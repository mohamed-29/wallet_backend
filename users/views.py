from rest_framework import viewsets, status, response, views
from .models import MobileUser
from .serializers import MobileUserSerializer
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = MobileUser.objects.all()
    serializer_class = MobileUserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return MobileUser.objects.filter(id=self.request.user.id)

class LoginView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        username = request.data.get('username')
        password = request.data.get('password')
        
        # Simple auth for prototype
        try:
            user = MobileUser.objects.get(username=username)
            if user.check_password(password):
                refresh = RefreshToken.for_user(user)
                return response.Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                    'user': MobileUserSerializer(user).data
                })
        except MobileUser.DoesNotExist:
            pass
            
        return response.Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class RegisterView(views.APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        data = request.data
        try:
            user = MobileUser.objects.create_user(
                username=data['username'],
                phone_number=data['phone_number'],
                password=data['password']
            )
            refresh = RefreshToken.for_user(user)
            return response.Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': MobileUserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return response.Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
