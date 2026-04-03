import pytest
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from users.models import MobileUser
from wallets.models import Wallet
from wallet_backend.security import generate_hmac_signature, verify_hmac_signature
from unittest.mock import patch

@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def user(db):
    return MobileUser.objects.create_user(username='testuser', phone_number='123456789', password='password')

@pytest.mark.django_db
def test_hmac_security():
    payload = {"test": "data", "id": 1}
    secret = "secret"
    signature = generate_hmac_signature(payload, secret)
    assert verify_hmac_signature(payload, signature, secret) is True
    assert verify_hmac_signature(payload, "wrong_sig", secret) is False

@pytest.mark.django_db
@patch('httpx.Client.post')
def test_pay_qr_success(mock_post, api_client, user):
    # Setup
    wallet = Wallet.objects.create(user=user, balance_cents=1000)
    api_client.force_authenticate(user=user)
    
    # Mock VMMC response
    mock_post.return_value.status_code = 200
    
    url = reverse('payment-pay-qr')
    data = {
        "device_order_id": "550e8400-e29b-41d4-a716-446655440000",
        "machine_id": "MACH001",
        "slot": "101",
        "price_cents": 500
    }
    
    response = api_client.post(url, data, format='json')
    
    assert response.status_code == status.HTTP_200_OK
    wallet.refresh_from_db()
    assert wallet.balance_cents == 500
    assert mock_post.called

@pytest.mark.django_db
def test_pay_qr_insufficient_balance(api_client, user):
    wallet = Wallet.objects.create(user=user, balance_cents=100)
    api_client.force_authenticate(user=user)
    
    url = reverse('payment-pay-qr')
    data = {
        "device_order_id": "550e8400-e29b-41d4-a716-446655440000",
        "machine_id": "MACH001",
        "slot": "101",
        "price_cents": 500
    }
    
    response = api_client.post(url, data, format='json')
    
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    assert response.data['error'] == 'Insufficient balance'
