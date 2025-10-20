import uuid
from django.db import models
from django.contrib.postgres.fields import ArrayField
from accounts.models import User # Import the custom User model

# -------------------------------------------------------------------------
# 1. Post Model
# -------------------------------------------------------------------------

class Post(models.Model):
    """
    Represents a single piece of content, accommodating text, media, and creator types.
    """
    
    # 1. IDENTIFIERS AND RELATIONSHIPS
    
    # NEW: Secure, public ID for the content
    content_id = models.UUIDField(
        default=uuid.uuid4, 
        unique=True,         
        editable=False       
    )
    # Renamed from 'author' to 'creator' (User foreign key)
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_posts')
    
    # 2. CONTENT TYPE AND DATA
    
    CONTENT_CHOICES = [
        ('TEXT', 'Text Only'), 
        ('IMAGE', 'Image Post'),
        ('VIDEO', 'Video Post'),
    ]
    # content_type (text, image, video)
    content_type = models.CharField(max_length=10, choices=CONTENT_CHOICES)
    
    # text_content (if content_type is text, otherwise None)
    text_content = models.TextField(blank=True, null=True, verbose_name="Text Content")
    
    # media_url (Replaced by FileField for better Django handling)
    media_file = models.FileField(
        upload_to='post_media/%Y/%m/%d/', 
        blank=True, 
        null=True,
        verbose_name="Media File (Image/Video)"
    ) 
    
    # 3. METADATA AND CREATOR
    
    POSTED_BY_CHOICES = [
        ('USER', 'Regular User'),
        ('STAFF', 'Staff Member'),
        ('ADMIN', 'Administrator'),
    ]
    # posted_by (user, staff, admin) - Tracks who created the post
    posted_by = models.CharField(max_length=10, choices=POSTED_BY_CHOICES, default='USER')
    
    # description (Used for short summary or main post title)
    description = models.CharField(max_length=255, blank=True)
    
    # feed_types 
    feed_types = ArrayField(
        models.CharField(max_length=50),
        default=list,
        blank=True
    )

    
    # 4. STATUS AND TIME
    
    created_at = models.DateTimeField(auto_now_add=True)
    is_published = models.BooleanField(default=True)
    
    # updated (true, false) - Tracks if the post has ever been modified
    updated = models.BooleanField(default=False)
    # updated_at
    updated_at = models.DateTimeField(auto_now=True) 

    # 5. INTERACTIONS
    
    # Hypes (number which denote the Hypes) - Not stored directly in the model.
    # We will get the count dynamically using the 'Hypes' ForeignKey relationship
    # (i.e., post.Hypes.count()). This prevents race conditions and ensures accuracy.

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Content Post"

    def __str__(self):
        return f"Post {self.content_id} by {self.creator.username}"
        
    def save(self, *args, **kwargs):
        # Logic to set 'updated' status
        if self.pk:
            # If the post already exists, mark it as updated
            self.updated = True
        super().save(*args, **kwargs)

# -------------------------------------------------------------------------
# 2. Hype/Interaction Model (Used for counting 'Hypes')
# -------------------------------------------------------------------------

class Hype(models.Model):
    """Tracks a user's Hype/upvote (Hype) on a specific post."""
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='Hypes')
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name='Hypes')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'post')
        verbose_name = "Post Hype" # Renamed for clarity

    def __str__(self):
        return f"{self.user.username} Hyped Post {self.post.content_id}"

# -------------------------------------------------------------------------
# 3. Comment Model
# -------------------------------------------------------------------------

class Comment(models.Model):
    """Represents a comment on a post, supporting nested replies."""
    
    # The user who created the comment
    user = models.ForeignKey(
        'accounts.User', 
        on_delete=models.CASCADE, 
        related_name='comments'
    )
    
    # The post the comment belongs to
    post = models.ForeignKey(
        Post, 
        on_delete=models.CASCADE, 
        related_name='comments' 
    )
    
    # Text content of the comment
    text = models.TextField()
    
    # Field to support nested comments/replies
    parent_comment = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='replies'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        verbose_name = "Comment"
        verbose_name_plural = "Comments"

    def __str__(self):
        return f"Comment by {self.user.username} on Post {self.post.content_id}"

    # Helper method (optional, for convenience)
    @property
    def is_reply(self):
        return self.parent_comment is not None

# -------------------------------------------------------------------------
# 4. Feed/Tag Tracking Model (NEW)
# -------------------------------------------------------------------------

class Feed(models.Model):
    """
    Tracks statistics for feed_types used in posts, used for feed ranking and personalization.
    """
    
    # tag (The unique tag name, e.g., 'SCIENCE', 'TECH', 'EVENTS')
    tag = models.CharField(max_length=50, unique=True, verbose_name="Tag Name")
    
    # total_used (How many times this tag has appeared on a published post)
    total_used = models.IntegerField(default=0)
    
    # Rank (A weighted score for trending/relevance, calculated periodically)
    Rank = models.FloatField(default=0.0)
    
    # created_at (When the tag was first added/tracked)
    created_at = models.DateTimeField(auto_now_add=True)
    
    # last_used_at (When the tag was last used on a new published post)
    last_used_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-Rank', '-total_used'] # Rank by importance/popularity
        verbose_name = "Feed Tag Statistic"
        verbose_name_plural = "Feed Tag Statistics"

    def __str__(self):
        return self.tag