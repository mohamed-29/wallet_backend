import time
from rest_framework import viewsets, status, response, decorators
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from datetime import timedelta
import httpx
from django.db import transaction
from .models import Order
from .serializers import OrderSerializer
from wallets.models import Wallet, WalletLedger
from wallet_backend.security import generate_hmac_signature
from notifications.tasks import send_notification_task
import structlog

logger = structlog.get_logger(__name__)

# S2S Configuration
VMMC_API_URL = "https://machine.ivend.cloud/api/v1"


class VMCCAuthorizationError(Exception):
    pass


class PaymentViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @decorators.action(detail=False, methods=['post'], url_path='pay-qr')
    def pay_qr(self, request):
        """
        Processes QR payment and triggers machine vend via S2S.
        The entire operation (debit + VMMC call) is inside one atomic block
        so that a VMMC failure rolls back the wallet deduction.
        """
        data = request.data
        user = request.user
        wallet, _ = Wallet.objects.get_or_create(user=user)

        try:
            price_cents = int(data['price_cents'])
            device_order_id = data['device_order_id']
            machine_id = data['machine_id']
            slot = data['slot']
        except (KeyError, ValueError):
            return response.Response({'error': 'Invalid payload'}, status=status.HTTP_400_BAD_REQUEST)

        if wallet.balance_cents < price_cents:
            return response.Response({'error': 'Insufficient balance'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            with transaction.atomic():
                # Atomic deduction
                wallet = Wallet.objects.select_for_update().get(id=wallet.id)
                if wallet.balance_cents < price_cents:
                    raise VMCCAuthorizationError("Insufficient balance")

                wallet.balance_cents -= price_cents
                wallet.save()

                order = Order.objects.create(
                    user=user,
                    device_order_id=device_order_id,
                    machine_id=machine_id,
                    slot=slot,
                    price_cents=price_cents,
                    amount_paid_cents=price_cents,
                    status='PAID',
                    expires_at=timezone.now() + timedelta(minutes=5)
                )

                WalletLedger.objects.create(
                    wallet=wallet,
                    transaction_type='DEBIT',
                    amount_cents=price_cents,
                    metadata={'device_order_id': device_order_id, 'machine_id': machine_id}
                )

                # Notify VMMC (Secure S2S with HMAC + timestamp for replay protection)
                payload = {
                    "device_order_id": str(device_order_id),
                    "machine_id": machine_id,
                    "slot": slot,
                    "status": "PAID",
                    "timestamp": str(time.time()),
                }
                signature = generate_hmac_signature(payload)

                # TODO: Fix SSL cert on machine.ivend.cloud, then remove verify=False
                with httpx.Client(timeout=10.0, verify=False) as client:
                    vmmc_response = client.post(
                        f"{VMMC_API_URL}/machine/authorize-vend/",
                        json=payload,
                        headers={
                            "X-S2S-Signature": signature,
                            "Content-Type": "application/json"
                        }
                    )

                if vmmc_response.status_code != 200:
                    logger.error("vmmc_authorization_failed",
                                 status_code=vmmc_response.status_code,
                                 response=vmmc_response.text)
                    raise VMCCAuthorizationError("VMMC server rejected authorization")

        except VMCCAuthorizationError as e:
            logger.warning("vmmc_authorization_error", error=str(e))
            return response.Response({'error': 'Machine Authorization Failed'}, status=status.HTTP_502_BAD_GATEWAY)
        except Exception as e:
            logger.exception("vmmc_communication_error", error=str(e))
            return response.Response({'error': 'Machine Authorization Failed'}, status=status.HTTP_502_BAD_GATEWAY)

        # Success - Trigger background notification
        send_notification_task.delay(
            user.id,
            "Payment Successful!",
            f"You spent L.E.{(price_cents/100):.2f}. Your item is being dispensed."
        )

        logger.info("payment_success", user_id=user.id, order_id=order.device_order_id)
        return response.Response({'status': 'SUCCESS', 'order_id': order.device_order_id})
