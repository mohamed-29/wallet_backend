from rest_framework import serializers
from .models import VendingLocation

class VendingLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = VendingLocation
        fields = '__all__'
