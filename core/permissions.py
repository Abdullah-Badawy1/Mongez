"""
Shared DRF permission classes for the Mongez API.

These are reusable, role-based permission classes that replace the
inline `if request.user.role != User.Role.X` checks scattered across views.

Usage:
    from core.permissions import IsClient, IsWorker, IsAdmin

    class MyView(APIView):
        permission_classes = [IsAuthenticated, IsClient]
"""

from rest_framework.permissions import BasePermission

# Avoid importing User at module load to keep this importable from anywhere
CLIENT = "client"
WORKER = "worker"
ADMIN = "admin"


class IsClient(BasePermission):
    message = "Only clients can perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and getattr(request.user, "role", None) == CLIENT
        )


class IsWorker(BasePermission):
    message = "Only workers can perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and getattr(request.user, "role", None) == WORKER
        )


class IsAdmin(BasePermission):
    message = "Only admins can perform this action."

    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (
                getattr(request.user, "role", None) == ADMIN
                or request.user.is_superuser
            )
        )


class IsClientOrWorker(BasePermission):
    """Allow either role — useful for shared endpoints that hide admin-only data."""

    message = "Account role not allowed."

    def has_permission(self, request, view):
        role = getattr(request.user, "role", None)
        return bool(
            request.user
            and request.user.is_authenticated
            and role in (CLIENT, WORKER)
        )


class IsOrderParticipant(BasePermission):
    """
    Object-level: client OR worker assigned to the order.
    Use with `permission_classes = [IsAuthenticated, IsOrderParticipant]`
    and call `self.check_object_permissions(request, order)` after fetching.
    """

    message = "You are not a participant in this order."

    def has_object_permission(self, request, view, obj):
        user = request.user
        return obj.client_id == user.id or obj.worker_id == user.id
