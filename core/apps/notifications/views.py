from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .models import DeviceToken, Notification
from .serializers import DeviceTokenSerializer, NotificationSerializer


class NotificationListView(APIView):
    """GET /api/notifications/ — list my notifications.

    Query params:
        ?unread=1   only unread notifications
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = Notification.objects.filter(user=request.user)
        if request.query_params.get("unread") in {"1", "true", "yes"}:
            qs = qs.filter(is_read=False)
        return Response(NotificationSerializer(qs, many=True).data)


class NotificationUnreadCountView(APIView):
    """GET /api/notifications/unread-count/ — for the bell badge."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({"unread": count})


class NotificationMarkReadView(APIView):
    """POST /api/notifications/{id}/read/ — mark one notification as read"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, user=request.user)
        except Notification.DoesNotExist:
            return Response(
                {"error": "Notification not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        notif.is_read = True
        notif.save()
        return Response(NotificationSerializer(notif).data)


class NotificationMarkAllReadView(APIView):
    """POST /api/notifications/read-all/ — mark all notifications as read"""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({"message": "All notifications marked as read."})


class DeviceTokenRegisterView(APIView):
    """POST /api/notifications/devices/ — register an FCM token for the current user.

    Idempotent: re-registering an existing token re-binds it to the current user
    (handles the case where the same phone is shared across multiple accounts).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        token = serializer.validated_data["token"]
        platform = serializer.validated_data.get("platform", DeviceToken.ANDROID)

        device, _ = DeviceToken.objects.update_or_create(
            token=token,
            defaults={
                "user": request.user,
                "platform": platform,
                "is_active": True,
            },
        )
        return Response(DeviceTokenSerializer(device).data, status=status.HTTP_201_CREATED)

    def delete(self, request):
        token = request.data.get("token") or request.query_params.get("token")
        if not token:
            return Response(
                {"error": "Provide 'token' to unregister."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        DeviceToken.objects.filter(user=request.user, token=token).update(is_active=False)
        return Response(status=status.HTTP_204_NO_CONTENT)
