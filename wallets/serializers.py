from rest_framework import serializers
from .models import Wallet, WalletLedger

class WalletSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wallet
        fields = ['balance_cents', 'balance_display']

class WalletLedgerSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletLedger
        fields = ['transaction_type', 'amount_cents', 'timestamp', 'metadata']
