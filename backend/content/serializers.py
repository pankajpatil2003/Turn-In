from rest_framework import serializers
from .models import Post, Hype, Comment, Feed 
from accounts.models import User
from accounts.serializers import StudentProfileSerializer 
import re 

# ----------------------------------------------------------------------
# 1. Nested Serializers for Creator/Author Data
# ----------------------------------------------------------------------

class PostCreatorSerializer(serializers.ModelSerializer):
    """Minimal serializer to represent the post creator and their profile image."""
    profile = StudentProfileSerializer(source='studentprofile', read_only=True)
    class Meta:
        model = User
        fields = ('user_is', 'username', 'profile')

class CommentCreatorSerializer(serializers.ModelSerializer):
    """Minimal user data for a comment creator."""
    profile = StudentProfileSerializer(source='studentprofile', read_only=True)
    class Meta:
        model = User
        fields = ('user_is', 'username', 'profile')

# ----------------------------------------------------------------------
# 2. Comment Serializers (Recursive)
# ----------------------------------------------------------------------

class RecursiveCommentSerializer(serializers.Serializer):
    """Helper serializer for recursive nesting of comment replies."""
    def to_representation(self, value):
        serializer = CommentSerializer(value, context=self.context)
        return serializer.data


class CommentSerializer(serializers.ModelSerializer):
    """
    Main serializer for comments.
    """
    user = CommentCreatorSerializer(read_only=True)
    replies = RecursiveCommentSerializer(many=True, read_only=True) 
    reply_count = serializers.SerializerMethodField()

    class Meta:
        model = Comment
        fields = [
            'id', 
            'user', 
            'text',             # Required for input
            'parent_comment',   # Optional for input (if it's a reply)
            'created_at',
            'replies',       
            'reply_count',   
        ]
        # 'post' is excluded from input but included in read_only_fields 
        # so it can still be serialized if needed by other views.
        read_only_fields = ['id', 'user', 'created_at', 'replies', 'reply_count'] 
        
    def get_reply_count(self, obj):
        return obj.replies.count()


# ----------------------------------------------------------------------
# 3. Main Post Display (Read-Only) Serializer (Updated)
# ----------------------------------------------------------------------

class PostListSerializer(serializers.ModelSerializer):
    """
    Serializer for displaying the full post content in the main feed.
    """
    
    creator = PostCreatorSerializer(read_only=True)
    hype_count = serializers.SerializerMethodField() 
    comment_count = serializers.SerializerMethodField()
    is_hyped = serializers.SerializerMethodField()
    top_comments = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'content_id', 
            'creator',
            'content_type', 
            'text_content', 
            'media_file',
            'description',
            'tags',
            'hype_count',           
            'comment_count',        
            'is_hyped',
            'top_comments',       
            'posted_by',
            'created_at',
            'updated',
            'updated_at',
            'is_published',
        ]
        read_only_fields = fields 

    def get_hype_count(self, obj):
        return obj.Hypes.count()
        
    def get_comment_count(self, obj):
        return obj.comments.count()

    def get_is_hyped(self, obj):
        user = self.context.get('request').user
        if user.is_authenticated:
            return Hype.objects.filter(post=obj, user=user).exists()
        return False
        
    def get_top_comments(self, obj):
        """Fetches the top 3 top-level comments (parent_comment=None)."""
        top_level_comments = obj.comments.filter(
            parent_comment__isnull=True
        ).order_by('-created_at')[:3]
        
        return CommentSerializer(top_level_comments, many=True, context=self.context).data


# ----------------------------------------------------------------------
# 4. Post Creation (Write-Only) Serializer
# ----------------------------------------------------------------------

class PostCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating a new post.
    """
    
    class Meta:
        model = Post
        fields = [
            'content_type',
            'text_content',
            'media_file',
            'description',
            'tags', 
        ]

    def validate_tags(self, tags):
        """Cleans and normalizes manually provided tags (or those extracted from text)."""
        cleaned_tags = [tag.strip().upper() for tag in tags if tag.strip()]
        return cleaned_tags

    def validate(self, data):
        """Custom validation to check content types and to extract/normalize tags."""
        content_type = data.get('content_type')
        text_content = data.get('text_content', '')
        media_file = data.get('media_file')
        
        # --- 1. Content Type Validation ---
        if content_type == 'TEXT' and not text_content:
            raise serializers.ValidationError("Text content is required for TEXT posts.")
            
        if content_type in ['IMAGE', 'VIDEO'] and not media_file:
            raise serializers.ValidationError(f"Media file is required for {content_type} posts.")

        if media_file and content_type == 'TEXT':
             raise serializers.ValidationError("Cannot include media file if content type is TEXT.")

        # --- 2. Tag Extraction and Cleaning ---
        provided_tags = set(data.get('tags', []))
        combined_text = f" {text_content} {data.get('description', '')} "
        extracted_tags = re.findall(r'#(\w+)', combined_text)
        
        all_tags = set(tag.strip().upper() for tag in extracted_tags)
        all_tags.update(provided_tags)
            
        final_tag_list = list(all_tags)

        if len(final_tag_list) > 10: 
             raise serializers.ValidationError("A post cannot have more than 10 tags.")
             
        data['tags'] = final_tag_list 
        
        return data
    
    def create(self, validated_data):
        return Post.objects.create(**validated_data)


# ----------------------------------------------------------------------
# 5. Feed/Tag List Serializer
# ----------------------------------------------------------------------

class FeedSerializer(serializers.ModelSerializer):
    """Serializer for displaying Feed statistics."""
    class Meta:
        model = Feed
        fields = ('tag', 'total_used', 'Rank', 'created_at', 'last_used_at')