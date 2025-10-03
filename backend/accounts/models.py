import uuid
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.postgres.fields import ArrayField
from django.utils import timezone

# 1. Custom User Model
class User(AbstractUser):
    """
    Extends Django's AbstractUser. Supports UUID public ID and minimal registration.
    """
    
    # Secure, public ID for the user
    user_is = models.UUIDField(
        default=uuid.uuid4, 
        unique=True,         
        editable=False       
    )
    
    # Override email to ensure it is unique and used for login
    email = models.EmailField(unique=True) 

    # Fields made optional for minimal registration
    first_name = models.CharField(max_length=150, blank=True, null=True)
    last_name = models.CharField(max_length=150, blank=True, null=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def __str__(self):
        return self.email

# 2. Student Profile Model
class StudentProfile(models.Model):
    """
    Stores academic, feed-specific details, and the user's profile image.
    All fields except 'user' are optional initially.
    """
    
    user = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        primary_key=True
    ) 
    
    # NEW: Profile Image Field
    profile_image = models.ImageField(
        upload_to='profile_pics/', 
        null=True, 
        blank=True
    )
    
    # Academic Fields made optional (null/blank)
    college_university = models.CharField(max_length=255, blank=True, null=True)
    department = models.CharField(max_length=100, blank=True, null=True)
    course = models.CharField(max_length=100, blank=True, null=True)
    
    YEAR_CHOICES = [(i, str(i)) for i in range(1, 6)]
    current_year = models.PositiveSmallIntegerField(choices=YEAR_CHOICES, blank=True, null=True)
    
    # Array Field for content filtering
    feed_types = ArrayField(
        models.CharField(max_length=20),
        default=list, 
        blank=True
    )
    
    def __str__(self):
        return f"{self.user.username}'s Profile"

    def save(self, *args, **kwargs):
        # Set a default minimal feed if the list is empty
        if not self.feed_types:
             self.feed_types = ['GENERAL']
        
        super().save(*args, **kwargs)

# 3. OTP Verification Model
class OTP(models.Model):
    """Stores the one-time password for email verification."""
    email = models.EmailField(unique=True)
    
    # Corrected to CharField
    otp_code = models.CharField(max_length=6) 
    
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True) 

    def is_expired(self):
        # Check for None and perform time comparison
        if self.expires_at is None:
            return True 
        return timezone.now() > self.expires_at 
    
    def save(self, *args, **kwargs):
        # FIX: Always reset expires_at on save to ensure subsequent OTP requests
        # get a renewed 10-minute window when update_or_create is called.
        self.expires_at = timezone.now() + timezone.timedelta(minutes=10)
            
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.email} - {self.otp_code}"