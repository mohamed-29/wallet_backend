import time
import uuid
from rest_framework import viewsets, status, response, decorators
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.utils import timezone
from datetime import timedelta
import httpx
from django.conf import settings as django_settings
from django.db import transaction
from .models import Order
from .serializers import OrderSerializer
from wallets.models import Wallet, WalletLedger
from wallet_backend.security import generate_hmac_signature, verify_hmac_signature, verify_timestamp
from notifications.tasks import send_notification_task
import structlog

logger = structlog.get_logger(__name__)

# S2S Configuration
VMMC_API_URL = f"{django_settings.VMMC_BASE_URL}/api/v1"


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
            machine_id = str(data['machine_id'])
            slot = str(data['slot'])
        except (KeyError, ValueError, TypeError) as e:
            logger.warning("invalid_payload", error=str(e), data=data)
            return response.Response({'error': f'Invalid payload: {e}'}, status=status.HTTP_400_BAD_REQUEST)

        # Use client-provided order ID if available, otherwise auto-generate
        client_order_id = data.get('device_order_id')

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

                order_kwargs = dict(
                    user=user,
                    machine_id=machine_id,
                    slot=slot,
                    price_cents=price_cents,
                    amount_paid_cents=price_cents,
                    status='PAID',
                    expires_at=timezone.now() + timedelta(minutes=5),
                )
                if client_order_id:
                    order_kwargs['device_order_id'] = client_order_id

                order = Order.objects.create(**order_kwargs)

                WalletLedger.objects.create(
                    wallet=wallet,
                    transaction_type='DEBIT',
                    amount_cents=price_cents,
                    metadata={'device_order_id': str(order.device_order_id), 'machine_id': machine_id}
                )

                # Notify VMMC (Secure S2S with HMAC + timestamp for replay protection)
                payload = {
                    "device_order_id": str(order.device_order_id),
                    "machine_id": machine_id,
                    "slot": slot,
                    "status": "PAID",
                    "timestamp": str(time.time()),
                }
                signature = generate_hmac_signature(payload)

                with httpx.Client(timeout=10.0) as client:
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
                    raise VMCCAuthorizationError(
                        f"VMMC {vmmc_response.status_code}: {vmmc_response.text[:200]}"
                    )

        except VMCCAuthorizationError as e:
            logger.warning("vmmc_authorization_error", error=str(e))
            return response.Response(
                {'error': f'Machine Authorization Failed', 'detail': str(e)},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        except Exception as e:
            logger.exception("vmmc_communication_error", error=str(e))
            return response.Response(
                {'error': 'Machine Authorization Failed', 'detail': str(e)},
                status=status.HTTP_502_BAD_GATEWAY,
            )

        # Success - Trigger background notification
        send_notification_task.delay(
            user.id,
            "Payment Successful!",
            f"You spent L.E.{(price_cents/100):.2f}. Your item is being dispensed."
        )

        logger.info("payment_success", user_id=user.id, order_id=order.device_order_id)
        return response.Response({'status': 'SUCCESS', 'order_id': str(order.device_order_id)})

    @decorators.action(detail=False, methods=['get'], url_path='my-orders')
    def my_orders(self, request):
        """Returns the authenticated user's orders, newest first."""
        orders = Order.objects.filter(user=request.user).order_by('-created_at')
        serializer = OrderSerializer(orders, many=True)
        return response.Response(serializer.data)

    @decorators.action(detail=False, methods=['post'], url_path='confirm-order',
                       permission_classes=[AllowAny], authentication_classes=[])
    def confirm_order(self, request):
        """
        S2S endpoint called by VMMC to update order status after vend.
        Secured via HMAC signature.
        """
        signature = request.headers.get('X-S2S-Signature')
        if not signature or not verify_hmac_signature(request.data, signature):
            return response.Response({'error': 'Unauthorized'}, status=status.HTTP_401_UNAUTHORIZED)

        if not verify_timestamp(request.data):
            return response.Response({'error': 'Request expired'}, status=status.HTTP_401_UNAUTHORIZED)

        device_order_id = request.data.get('device_order_id')
        new_status = request.data.get('status')  # COMPLETED or FAILED

        if not device_order_id or not new_status:
            return response.Response({'error': 'Missing fields'}, status=status.HTTP_400_BAD_REQUEST)

        status_map = {
            'SUCCESS': 'COMPLETED',
            'COMPLETED': 'COMPLETED',
            'FAILED': 'FAILED',
        }
        mapped_status = status_map.get(new_status.upper())
        if not mapped_status:
            return response.Response({'error': f'Invalid status: {new_status}'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            order = Order.objects.get(device_order_id=device_order_id)
            order.status = mapped_status
            order.save()
            logger.info("order_confirmed", order_id=device_order_id, status=mapped_status)

            # If failed, refund the wallet
            if mapped_status == 'FAILED':
                try:
                    wallet = Wallet.objects.get(user=order.user)
                    wallet.balance_cents += order.amount_paid_cents
                    wallet.save()
                    WalletLedger.objects.create(
                        wallet=wallet,
                        transaction_type='CREDIT',
                        amount_cents=order.amount_paid_cents,
                        metadata={'device_order_id': str(device_order_id), 'reason': 'vend_failed_refund'}
                    )
                    order.status = 'REFUNDED'
                    order.save()
                    logger.info("order_refunded", order_id=device_order_id)
                except Exception as e:
                    logger.exception("refund_error", order_id=device_order_id, error=str(e))

            return response.Response({'status': 'updated'})
        except Order.DoesNotExist:
            return response.Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)
