from django.db import models
from django.conf import settings
from decimal import Decimal

User = settings.AUTH_USER_MODEL

class Wallet(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wallet')
    balance_cents = models.PositiveIntegerField(default=0)
    
    @property
    def balance_display(self):
        return Decimal(self.balance_cents) / Decimal(100)

    def __str__(self):
        return f"Wallet for {self.user.username} - Balance: {self.balance_display}"

class WalletLedger(models.Model):
    TRANSACTION_TYPES = (
        ('CREDIT', 'Credit (Top-up/Refund)'),
        ('DEBIT', 'Debit (Purchase)'),
    )
    wallet = models.ForeignKey(Wallet, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=10, choices=TRANSACTION_TYPES)
    amount_cents = models.PositiveIntegerField()
    timestamp = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict, blank=True, help_text="Store device_order_id, fawry_ref, etc.")

    def __str__(self):
        return f"{self.transaction_type} of {self.amount_cents} cents to {self.wallet.user.username}"
