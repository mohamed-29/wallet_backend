from rest_framework import serializers
from .models import MobileUser

class MobileUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = MobileUser
        fields = ['id', 'username', 'phone_number', 'language_preference', 'first_name', 'last_name', 'email']
