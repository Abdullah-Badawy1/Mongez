from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # Auth
    path("auth/register/",      views.RegisterView.as_view(),        name="register"),
    path("auth/login/",         views.LoginView.as_view(),           name="login"),
    path("auth/logout/",        views.LogoutView.as_view(),          name="logout"),
    path("auth/password/",      views.PasswordChangeView.as_view(),  name="password-change"),
    path("auth/token/refresh/", TokenRefreshView.as_view(),          name="token-refresh"),
    # User profile
    path("users/me/",           views.MyProfileView.as_view(),       name="my-profile"),
    # Reference data
    path("governorates/",       views.GovernoratesView.as_view(),    name="governorates"),
]
