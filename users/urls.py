from django.urls import path
from .views import RegisterView, LoginView, ProfileView, UpdateUserView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/',    LoginView.as_view(),    name='login'),
    path('profile/',  ProfileView.as_view(),  name='profile'),
    path('update/',   UpdateUserView.as_view(), name='update'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]