from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Promotion
from .serializers import PromotionSerializer

class PromotionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PromotionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        now = timezone.now()
        return Promotion.objects.filter(is_active=True, valid_from__lte=now, valid_until__gte=now)
