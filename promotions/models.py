from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL

class Promotion(models.Model):
    PROMO_TYPES = (
        ('PERCENTAGE', 'Percentage Discount'),
        ('FIXED', 'Fixed Amount Discount'),
        ('FREE_ITEM', 'Free Item (Direct Vend)'),
    )
    code = models.CharField(max_length=50, unique=True)
    promo_type = models.CharField(max_length=20, choices=PROMO_TYPES)
    value = models.PositiveIntegerField(help_text="Percentage (0-100) or Fixed cents")
    is_active = models.BooleanField(default=True)
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    max_uses_per_user = models.PositiveIntegerField(default=1)

    def __str__(self):
        return f"Promo {self.code} ({self.promo_type})"

class UserPromotion(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='claimed_promotions')
    promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE)
    claimed_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)
