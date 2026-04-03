from rest_framework import viewsets, response
from rest_framework.permissions import AllowAny
import httpx
from django.conf import settings

class VendingLocationViewSet(viewsets.ViewSet):
    """
    Proxy ViewSet to fetch machine locations from VMMC backend.
    """
    permission_classes = [AllowAny]

    def list(self, request):
        vmmc_url = "https://machine.ivend.cloud/api/v1/machine-locations/"
        
        try:
            with httpx.Client(timeout=10.0) as client:
                vmmc_response = client.get(vmmc_url)
                
            if vmmc_response.status_code == 200:
                return response.Response(vmmc_response.json())
            else:
                return response.Response(
                    {'error': 'Failed to fetch from VMMC', 'status_code': vmmc_response.status_code},
                    status=vmmc_response.status_code
                )
        except Exception as e:
            return response.Response({'error': str(e)}, status=500)
