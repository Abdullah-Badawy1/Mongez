from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from apps.users.models import User
from .models import Favorite
from .serializers import FavoriteSerializer


class FavoriteListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != User.Role.CLIENT:
            return Response(
                {"error": "Only clients have a favorites list."},
                status=status.HTTP_403_FORBIDDEN,
            )
        favorites = Favorite.objects.select_related("worker").filter(
            client=request.user
        )
        return Response(FavoriteSerializer(favorites, many=True).data)

    def post(self, request):
        if request.user.role != User.Role.CLIENT:
            return Response(
                {"error": "Only clients can add favorites."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = FavoriteSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        worker = serializer.validated_data["worker"]

        if Favorite.objects.filter(client=request.user, worker=worker).exists():
            return Response(
                {"error": "This worker is already in your favorites."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        favorite = Favorite.objects.create(client=request.user, worker=worker)
        return Response(FavoriteSerializer(favorite).data, status=status.HTTP_201_CREATED)


class FavoriteDeleteView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            favorite = Favorite.objects.get(pk=pk, client=request.user)
        except Favorite.DoesNotExist:
            return Response(
                {"error": "Favorite not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        favorite.delete()
        return Response(
            {"message": "Removed from favorites."},
            status=status.HTTP_204_NO_CONTENT,
        )
