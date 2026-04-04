from rest_framework import viewsets, response
from rest_framework.permissions import IsAuthenticated
import httpx
from django.conf import settings
import structlog
from wallet_backend.security import generate_hmac_signature

logger = structlog.get_logger(__name__)

class VendingLocationViewSet(viewsets.ViewSet):
    """
    Secured Proxy ViewSet to fetch machine locations from VMMC backend.
    Only available to authenticated mobile users.
    """
    permission_classes = [IsAuthenticated]

    def list(self, request):
        vmmc_url = "https://machine.ivend.cloud/api/v1/machine-locations/"
        
        # 1. Generate S2S HMAC signature for an empty payload (GET request)
        signature = generate_hmac_signature({})
        
        logger.info("fetching_locations_from_vmmc_secured", url=vmmc_url)
        
        try:
            with httpx.Client(timeout=10.0) as client:
                vmmc_response = client.get(
                    vmmc_url,
                    headers={
                        "X-S2S-Signature": signature,
                        "Content-Type": "application/json"
                    }
                )
                
            if vmmc_response.status_code == 200:
                data = vmmc_response.json()
                logger.info("locations_fetched_success", count=len(data))
                return response.Response(data)
            else:
                logger.error("vmmc_fetch_failed", status_code=vmmc_response.status_code)
                return response.Response(
                    {'error': 'Failed to fetch from VMMC', 'status_code': vmmc_response.status_code},
                    status=vmmc_response.status_code
                )
        except Exception as e:
            logger.exception("vmmc_proxy_exception", error=str(e))
            return response.Response({'error': 'Internal connection error'}, status=500)
