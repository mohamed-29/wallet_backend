from rest_framework import serializers
from .models import Promotion

class PromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Promotion
        fields = ['code', 'promo_type', 'value', 'valid_from', 'valid_until']
