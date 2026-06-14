from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny

from core.permissions import IsClient
from core.throttling import RatingThrottle
from .models import Rating
from .serializers import RatingSerializer, WorkerRatingSerializer


class RatingCreateView(APIView):
    permission_classes = [IsAuthenticated, IsClient]
    throttle_classes = [RatingThrottle]

    def post(self, request):
        serializer = RatingSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            rating = serializer.save()
            return Response(RatingSerializer(rating).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class WorkerRatingsListView(APIView):
    """GET /api/ratings/worker/<id>/ — public list of reviews left for a worker."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        ratings = (
            Rating.objects
            .filter(worker_id=pk)
            .select_related("client", "order")
            .order_by("-created_at")[:50]
        )
        return Response(WorkerRatingSerializer(ratings, many=True).data)
