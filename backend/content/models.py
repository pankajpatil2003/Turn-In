from django.db import models

# content/models.py
from django.db import models
from django.contrib.postgres.fields import ArrayField
from accounts.models import User # Import the custom User model

class Post(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    
    # Content Fields
    content = models.TextField(blank=True)
    
    # Media Fields (using the local file storage approach for now)
    media_url = models.CharField(max_length=255, blank=True, null=True) # Stores the path/URL
    media_type = models.CharField(max_length=20, blank=True, null=True) # e.g., 'image', 'video'
    
    # Post Attributes
    is_admin_post = models.BooleanField(default=False)
    post_type = models.CharField(max_length=50, default='Status')
    
    # Feed Filtering (The Array Field)
    tags = ArrayField(
        models.CharField(max_length=20),
        default=list,
        blank=True
    )
    
    # Status and Time
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=True)

    class Meta:
        ordering = ['-created_at'] # Default feed ordering: newest first

    def __str__(self):
        return f"Post by {self.author.username} at {self.created_at.strftime('%Y-%m-%d %H:%M')}"