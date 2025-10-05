from rest_framework import serializers
from .models import User, StudentProfile

# 1. Serializer for StudentProfile (Used for updates later)
# accounts/serializers.py (Changes in StudentProfileSerializer)

class StudentProfileSerializer(serializers.ModelSerializer):
    """
    Handles serialization of the StudentProfile model, now including 
    read-only fields from the linked User model.
    """
    
    # 1. Read-only fields from the linked User model
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    user_is = serializers.UUIDField(source='user.user_is', read_only=True)
    
    # Optional: If you want to show names on the profile screen too
    first_name = serializers.CharField(source='user.first_name', required=False, allow_null=True)
    last_name = serializers.CharField(source='user.last_name', required=False, allow_null=True)
    
    class Meta:
        model = StudentProfile
        fields = (
            'username', 'email', 'user_is', # Core User Fields
            'first_name', 'last_name',      # Core User Names
            'profile_image', 
            'college_university', 
            'department', 
            'course', 
            'current_year',
            'feed_types'
        )
        read_only_fields = ('feed_types', 'username', 'email', 'user_is')

    # Optional: Override update() if you want the profile endpoint to update first/last name
    def update(self, instance, validated_data):
        # Handle updating fields in the related User model
        user_data = {
            'first_name': validated_data.pop('first_name', None),
            'last_name': validated_data.pop('last_name', None)
        }
        
        # Update User fields
        user = instance.user
        for key, value in user_data.items():
            if value is not None:
                setattr(user, key, value)
        user.save()
        
        # Update StudentProfile fields
        return super().update(instance, validated_data)

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