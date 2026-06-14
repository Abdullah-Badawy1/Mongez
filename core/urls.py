from django.conf import settings
from django.http import JsonResponse
from django.urls import include, path, re_path
from django.views.static import serve as serve_static


def health(_request):
    return JsonResponse({"status": "ok"})


api_patterns = [
    path("health/", health, name="health"),
    path("", include("apps.users.urls")),
    path("", include("apps.workers.urls")),
    path("", include("apps.orders.urls")),
    path("", include("apps.notifications.urls")),
    path("", include("apps.payments.urls")),
    path("", include("apps.ratings.urls")),
    path("", include("apps.favorites.urls")),
    path("", include("apps.admin_api.urls")),
]

urlpatterns = [
    path("api/", include(api_patterns)),
]

# Serve user-uploaded files (avatars, order attachments) even when
# DEBUG=False. WhiteNoise only handles /static/, and
# django.conf.urls.static.static() short-circuits to [] when DEBUG is off,
# so we wire MEDIA_URL directly to django.views.static.serve. Fine for
# this app's scale; front with nginx if traffic ever justifies it.
_media_prefix = settings.MEDIA_URL.lstrip("/")
urlpatterns += [
    re_path(
        rf"^{_media_prefix}(?P<path>.*)$",
        serve_static,
        {"document_root": settings.MEDIA_ROOT},
    ),
]
