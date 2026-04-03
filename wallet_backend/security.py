import hmac
import hashlib
import json
import time
from django.conf import settings

S2S_TIMESTAMP_TOLERANCE = 30  # seconds

def generate_hmac_signature(payload: dict, secret: str = None) -> str:
    """
    Generates an SHA256 HMAC signature for a JSON payload.
    Automatically injects a timestamp for replay protection.
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

def verify_timestamp(payload: dict, tolerance: int = S2S_TIMESTAMP_TOLERANCE) -> bool:
    """
    Verifies that the payload timestamp is within the allowed tolerance window.
    Returns False if timestamp is missing or expired.
    """
    ts = payload.get('timestamp')
    if ts is None:
        return False
    try:
        return abs(time.time() - float(ts)) <= tolerance
    except (ValueError, TypeError):
        return False
