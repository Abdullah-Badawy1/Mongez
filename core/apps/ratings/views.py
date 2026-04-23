from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from apps.users.models import User
from .models import Rating
from .serializers import RatingSerializer


class RatingCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != User.Role.CLIENT:
            return Response(
                {"error": "Only clients can submit ratings."},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = RatingSerializer(data=request.data, context={"request": request})
        if serializer.is_valid():
            rating = serializer.save()
            return Response(RatingSerializer(rating).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
