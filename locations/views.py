from rest_framework import viewsets
from .models import VendingLocation
from .serializers import VendingLocationSerializer
from rest_framework.permissions import AllowAny

class VendingLocationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = VendingLocation.objects.all()
    serializer_class = VendingLocationSerializer
    permission_classes = [AllowAny]
