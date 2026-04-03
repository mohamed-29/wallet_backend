from rest_framework import viewsets, decorators, response
from rest_framework.permissions import IsAuthenticated
from .models import Wallet, WalletLedger
from .serializers import WalletSerializer, WalletLedgerSerializer

class WalletViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @decorators.action(detail=False, methods=['get'])
    def balance(self, request):
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        serializer = WalletSerializer(wallet)
        return response.Response(serializer.data)

    @decorators.action(detail=False, methods=['get'])
    def history(self, request):
        wallet, _ = Wallet.objects.get_or_create(user=request.user)
        ledgers = WalletLedger.objects.filter(wallet=wallet).order_by('-timestamp')
        serializer = WalletLedgerSerializer(ledgers, many=True)
        return response.Response(serializer.data)
