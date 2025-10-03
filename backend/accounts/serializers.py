from rest_framework import serializers
from .models import User, StudentProfile

# 1. Serializer for StudentProfile (Used for updates later)
class StudentProfileSerializer(serializers.ModelSerializer):
    """Handles serialization of the StudentProfile model."""
    class Meta:
        model = StudentProfile
        fields = ('college_university', 'department', 'course', 'current_year')
        read_only_fields = ('feed_types',) 

# 2. Serializer for RequestOTP (Step 1)
class RequestOTPSerializer(serializers.Serializer):
    """Handles the initial email submission for OTP request."""
    email = serializers.EmailField()

# 3. Serializer for Final Registration (Step 2)
class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Handles creation of User with minimal fields (email, username, password) 
    after OTP verification.
    """
    password_confirm = serializers.CharField(style={'input_type': 'password'}, write_only=True)
    
    # CRITICAL FIX: REMOVE otp_code from the serializer entirely.
    # The view (FinalRegisterView) handles checking the OTP. 
    # The serializer only needs the fields required for user creation.
    
    class Meta:
        model = User
        # Fields collected at minimal registration
        # REMOVED: 'otp_code'
        fields = ('email', 'username', 'password', 'password_confirm')
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True},
            'username': {'required': True}, 
        }

    def validate(self, data):
        """Custom validation to ensure passwords match."""
        if data['password'] != data['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})
        return data

    def create(self, validated_data):
        """Creates the User and ensures an empty StudentProfile is created."""
        
        # Now we only need to remove 'password_confirm'
        validated_data.pop('password_confirm') 
        
        user = User.objects.create_user(**validated_data)
        
        # Create the associated StudentProfile immediately
        StudentProfile.objects.create(user=user)
        
        return user