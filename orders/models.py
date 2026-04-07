from django.db import models
from django.conf import settings
import uuid

User = settings.AUTH_USER_MODEL

class Order(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending (QR Scanned)'),
        ('PAID', 'Paid (Waiting for Machine)'),
        ('COMPLETED', 'Completed (Vended successfully)'),
        ('FAILED', 'Failed (Machine Error)'),
        ('REFUNDED', 'Refunded'),
    )
    device_order_id = models.UUIDField(default=uuid.uuid4, unique=True)
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='orders')
    machine_id = models.CharField(max_length=100)
    slot = models.CharField(max_length=50)
    
    # Pricing details
    price_cents = models.PositiveIntegerField(help_text="Original price of the item")
    discount_cents = models.PositiveIntegerField(default=0, help_text="Discount from promotions")
    amount_paid_cents = models.PositiveIntegerField(help_text="Final amount deducted from wallet")
    
    # Needs a lazy reference to promotions app
    applied_promotion = models.ForeignKey('promotions.UserPromotion', on_delete=models.SET_NULL, null=True, blank=True)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(help_text="When the QR session expires")

    @property
    def amount_display(self):
        from decimal import Decimal
        return Decimal(self.amount_paid_cents) / Decimal(100)

    def __str__(self):
        return f"Order {self.device_order_id} - {self.status}"
