import random
import string
from django.utils import timezone
from django.shortcuts import get_object_or_404
from django.core.mail import send_mail
from django.conf import settings

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework import serializers 
from rest_framework import generics, permissions # NEW: Imports for generics and permissions

from .models import User, OTP, StudentProfile # UPDATED: Imported StudentProfile
from .serializers import (
    UserRegistrationSerializer, 
    RequestOTPSerializer,
    StudentProfileSerializer # UPDATED: Imported Profile Serializer
)
from .utils import send_otp_email # Custom email function

# 1. Custom Login View
class MyTokenObtainPairView(TokenObtainPairView):
    """Handles login and token generation using email as the identifier."""
    pass

# 2. Check Username Availability
class UsernameCheckView(APIView):
    """Provides instant feedback on username availability."""
    def get(self, request):
        username = request.query_params.get('username', None)
        if not username:
            return Response({"error": "Username parameter is required."}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check availability case-insensitively
        if User.objects.filter(username__iexact=username).exists():
            return Response({"available": False, "message": "Username is taken."}, status=status.HTTP_200_OK)
        else:
            return Response({"available": True, "message": "Username is available."}, status=status.HTTP_200_OK)

# 3. STEP 1: Request OTP and Send Custom Email
class RequestOTPView(APIView):
    """Handles the initial email submission and sends OTP via custom email utility."""
    
    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']

        # Check if user already exists
        if User.objects.filter(email=email).exists():
            return Response({"error": "User with this email already exists."}, status=status.HTTP_400_BAD_REQUEST)

        # Generate a 6-digit OTP (as a string to handle leading zeros)
        otp_code = ''.join(random.choices(string.digits, k=6))
        
        # Save/Update OTP in the database (The model's save method sets the correct expiry time)
        OTP.objects.update_or_create(
            email=email,
            defaults={
                'otp_code': otp_code, 
                'created_at': timezone.now()
            }
        )
        
        # Send Email using the custom utility function
        email_sent = send_otp_email(email, otp_code)
        
        if email_sent:
            return Response({"message": "OTP sent to your email."}, status=status.HTTP_200_OK)
        else:
            # If email fails, delete the OTP so the user must re-request
            OTP.objects.filter(email=email).delete() 
            return Response({"error": "Could not send OTP email. Please check server email settings."}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

# 4. STEP 2: Final Registration and OTP Verification
class FinalRegisterView(APIView):
    """Handles the final registration process after successful OTP verification."""
    
    def post(self, request):
        email = request.data.get('email')
        otp_code = request.data.get('otp_code')
        username = request.data.get('username') 
        
        # --- OTP Verification ---
        try:
            otp_instance = OTP.objects.get(email=email)
        except OTP.DoesNotExist:
            return Response({"error": "OTP not requested for this email."}, status=status.HTTP_400_BAD_REQUEST)
        
        if otp_instance.is_expired() or otp_instance.otp_code != otp_code:
            # Consolidate expired and incorrect OTP errors
            return Response({"error": "Verification code is incorrect or has expired."}, status=status.HTTP_400_BAD_REQUEST)

        # --- Username Availability Check ---
        if username and User.objects.filter(username__iexact=username).exists():
            return Response({"error": "This username is already taken. Please choose another."}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        # --- Final User Registration ---
        data = request.data.copy()
        data.pop('otp_code')
        
        serializer = UserRegistrationSerializer(data=data)
        if serializer.is_valid():
            user = serializer.save()
            
            # Clean up: Delete the used OTP instance
            otp_instance.delete() 
            
            return Response({"message": "User registered successfully."}, status=status.HTTP_201_CREATED)
            
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 5. Profile Update Endpoint
class StudentProfileUpdateView(generics.RetrieveUpdateAPIView):
    """
    Allows authenticated users to view (GET) and update (PUT/PATCH) their profile details.
    Requires authentication and ensures the user only accesses their own profile.
    """
    queryset = StudentProfile.objects.all()
    serializer_class = StudentProfileSerializer
    permission_classes = [permissions.IsAuthenticated] 

    def get_object(self):
        """
        Overrides the standard method to ensure the user can only access their own profile 
        via the OneToOne field (self.request.user.studentprofile).
        """
        return self.request.user.studentprofile