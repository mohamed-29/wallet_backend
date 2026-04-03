import hmac
import hashlib
import json
from django.conf import settings

def generate_hmac_signature(payload: dict, secret: str = None) -> str:
    """
    Generates an SHA256 HMAC signature for a JSON payload.
    """
    if secret is None:
        secret = settings.S2S_SECRET
    
    # Ensure keys are sorted for consistent hashing
    message = json.dumps(payload, sort_keys=True).encode()
    signature = hmac.new(secret.encode(), message, hashlib.sha256).hexdigest()
    return signature

def verify_hmac_signature(payload: dict, signature: str, secret: str = None) -> bool:
    """
    Verifies if the provided signature matches the payload.
    """
    expected_signature = generate_hmac_signature(payload, secret)
    return hmac.compare_digest(expected_signature, signature)
