from celery import shared_task
from .models import Notification
from users.models import MobileUser
import structlog

logger = structlog.get_logger(__name__)

@shared_task
def send_notification_task(user_id, title, body, data_payload=None):
    """
    Background task to record a notification and (future) trigger push provider.
    """
    try:
        user = MobileUser.objects.get(id=user_id)
        notification = Notification.objects.create(
            user=user,
            title=title,
            body=body,
            data_payload=data_payload or {}
        )
        logger.info("notification_sent", user_id=user_id, notification_id=notification.id)
        
        # Here you would integrate with your custom notification server/provider
        # e.g., requests.post("https://your-notify-server.com/send", json=...)
        
        return True
    except MobileUser.DoesNotExist:
        logger.error("notification_failed_user_not_found", user_id=user_id)
        return False
    except Exception as e:
        logger.error("notification_failed_error", user_id=user_id, error=str(e))
        return False
