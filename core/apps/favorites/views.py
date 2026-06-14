from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from core.permissions import IsClient
from .models import Favorite
from .serializers import FavoriteSerializer


class FavoriteListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsClient]

    def get(self, request):
        favorites = (
            Favorite.objects
            .select_related("worker", "worker__worker_profile")
            .filter(client=request.user)
        )
        return Response(FavoriteSerializer(favorites, many=True).data)

    def post(self, request):
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
    permission_classes = [IsAuthenticated, IsClient]

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


class FavoriteByWorkerDeleteView(APIView):
    """DELETE /api/favorites/worker/<worker_id>/ — convenient toggle by worker id."""

    permission_classes = [IsAuthenticated, IsClient]

    def delete(self, request, worker_id):
        deleted, _ = Favorite.objects.filter(
            client=request.user, worker_id=worker_id,
        ).delete()
        if not deleted:
            return Response(
                {"error": "Not in favorites."}, status=status.HTTP_404_NOT_FOUND,
            )
        return Response({"message": "Removed."}, status=status.HTTP_204_NO_CONTENT)
