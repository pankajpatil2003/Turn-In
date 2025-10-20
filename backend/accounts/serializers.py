from rest_framework import serializers
from .models import User, StudentProfile

# ----------------------------------------------------------------------
# 1. Serializer for StudentProfile (Used for updates)
# ----------------------------------------------------------------------
# accounts/serializers.py

class StudentProfileSerializer(serializers.ModelSerializer):
    """
    Handles serialization of the StudentProfile model, including fields 
    from the linked User model for read/write.
    """
    
    # Read-only fields from the linked User model
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    user_is = serializers.UUIDField(source='user.user_is', read_only=True)
    
    # Writable fields sourced from the User model (CRITICAL for update)
    first_name = serializers.CharField(source='user.first_name', required=False, allow_null=True)
    last_name = serializers.CharField(source='user.last_name', required=False, allow_null=True)
    
    class Meta:
        model = StudentProfile
        fields = (
            'username', 'email', 'user_is', 
            'first_name', 'last_name',       
            'profile_image', 
            'college_university', 
            'department', 
            'course', 
            'current_year',
            'feed_types'
        )
        read_only_fields = ('username', 'email', 'user_is') 
        # NOTE: feed_types should not be read_only if you want to update it via the PATCH request.
        # I removed 'feed_types' from read_only_fields here, assuming it's editable.

    def update(self, instance, validated_data):
        """
        FIXED: Explicitly updates StudentProfile fields (including feed_types) 
        before handling User fields.
        """
        # 1. CRITICAL: Extract the nested 'user' dictionary
        user_data = validated_data.pop('user', {}) 
        user = instance.user

        # 2. Update StudentProfile fields EXPLICITLY (FIX for ArrayField updates)
        # Loop through all remaining validated_data (e.g., feed_types, college_university, etc.)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Manually save the profile instance to ensure changes are committed
        instance.save() 
        profile_instance = instance

        # 3. Update the related User fields (first_name, last_name)
        if user_data:
            for attr, value in user_data.items():
                if value is not None: 
                    setattr(user, attr, value)
            user.save()

        return profile_instance
    
# ----------------------------------------------------------------------
# 2. Serializer for RequestOTP (Step 1)
# ----------------------------------------------------------------------

class RequestOTPSerializer(serializers.Serializer):
    """Handles the initial email submission for OTP request."""
    email = serializers.EmailField()

# ----------------------------------------------------------------------
# 3. Serializer for Final Registration (Step 2)
# ----------------------------------------------------------------------

class UserRegistrationSerializer(serializers.ModelSerializer):
    """
    Handles creation of User with minimal fields (email, username, password) 
    after OTP verification.
    """
    password_confirm = serializers.CharField(style={'input_type': 'password'}, write_only=True)
    
    class Meta:
        model = User
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
        
        validated_data.pop('password_confirm') 
        
        user = User.objects.create_user(**validated_data)
        
        # Create the associated StudentProfile immediately
        StudentProfile.objects.create(user=user)
        
        return user