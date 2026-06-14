"""
Notification service helpers.

The `notify` function is the single entry point used across the codebase to
send notifications. It always persists a row to the Notification table so the
in-app bell works, and additionally fans out to FCM device tokens when the
notification type is PUSH and an FCM_SERVER_KEY is configured.

We never raise from notify — push delivery is best-effort, never block the
caller's business logic on a delivery failure.
"""

import logging

from django.conf import settings

from .models import DeviceToken, Notification

logger = logging.getLogger(__name__)


def notify(user, title, message, notif_type=Notification.IN_APP, data=None):
    record = Notification.objects.create(
        user=user,
        title=title,
        message=message,
        type=notif_type,
        data=data or {},
    )

    if notif_type == Notification.PUSH:
        try:
            _push_to_devices(user, title, message, data or {})
        except Exception as exc:  # pragma: no cover — best-effort delivery
            logger.warning("FCM push to user %s failed: %s", user.id, exc)

    return record


def _push_to_devices(user, title, message, data):
    """Send the payload to every active device token registered for the user.

    If FCM_SERVER_KEY is unset (typical in dev), we just log and skip — the
    in-app row is still saved by `notify`.
    """
    server_key = getattr(settings, "FCM_SERVER_KEY", "") or ""
    tokens = list(
        DeviceToken.objects.filter(user=user, is_active=True).values_list("token", flat=True)
    )
    if not tokens:
        return
    if not server_key:
        logger.info(
            "Push payload prepared (FCM_SERVER_KEY not set, skipping HTTP) "
            "user=%s tokens=%d title=%r",
            user.id, len(tokens), title,
        )
        return

    import requests  # local import to keep startup light

    for token in tokens:
        try:
            requests.post(
                "https://fcm.googleapis.com/fcm/send",
                headers={
                    "Authorization": f"key={server_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "to": token,
                    "notification": {"title": title, "body": message},
                    "data": data,
                },
                timeout=5,
            )
        except Exception as exc:  # pragma: no cover
            logger.warning("FCM delivery error token=%s err=%s", token[:8], exc)
