from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
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
        phone_number = request.data.get('phone_number')
        password = request.data.get('password')
        
        try:
            # We use phone_number as the username for uniqueness
            user = MobileUser.objects.get(username=phone_number)
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
                username=data['phone_number'], # Phone number as unique ID
                phone_number=data['phone_number'],
                first_name=data['name'], # Full name maps to first_name
                password=data['password']
            )
            refresh = RefreshToken.for_user(user)
            return response.Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': MobileUserSerializer(user).data
            }, status=status.HTTP_201_CREATED)
        except Exception:
            return response.Response({'error': 'Registration failed. Phone number may already be in use.'}, status=status.HTTP_400_BAD_REQUEST)


class UpdateProfileView(views.APIView):
    """Update the signed-in user's personal info (name, email)."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user

        if 'name' in request.data:
            name = (request.data.get('name') or '').strip()
            if not name:
                return response.Response(
                    {'error': 'Name cannot be empty.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            user.first_name = name

        if 'email' in request.data:
            email = (request.data.get('email') or '').strip()
            if email:
                try:
                    validate_email(email)
                except ValidationError:
                    return response.Response(
                        {'error': 'Enter a valid email address.'},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
            user.email = email

        user.save()
        return response.Response(MobileUserSerializer(user).data, status=status.HTTP_200_OK)


class ChangePasswordView(views.APIView):
    """Authenticated password change: verify current password, set a new one."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if not current_password or not new_password:
            return response.Response(
                {'error': 'Current and new password are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not user.check_password(current_password):
            return response.Response(
                {'error': 'Current password is incorrect.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            validate_password(new_password, user=user)
        except ValidationError as e:
            return response.Response({'error': e.messages}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()

        return response.Response(
            {'detail': 'Password changed successfully.'},
            status=status.HTTP_200_OK,
        )
