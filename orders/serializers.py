from rest_framework import serializers
from .models import Order

class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = [
            'device_order_id', 'machine_id', 'slot', 'price_cents', 
            'discount_cents', 'amount_paid_cents', 'status', 'created_at'
        ]
