from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.db.models import Q 
from django.utils import timezone 
from accounts.models import User 
from .models import Post, Hype, Feed, Comment
from .serializers import ( 
                            PostListSerializer, 
                            PostCreateSerializer, 
                            FeedSerializer,
                            CommentSerializer
                        )

# ----------------------------------------------------------------------
# HELPER FUNCTION FOR FEED RANKING (Defined here for utility, executed by signal)
# ----------------------------------------------------------------------

def calculate_and_update_rank(feed_instance):
    """
    Calculates a simple rank score based on total_used and recency.
    NOTE: This function is executed by the post_save signal in content/signals.py.
    """
    usage_score = feed_instance.total_used
    days_since_last_used = (timezone.now() - feed_instance.last_used_at).days
    
    # Simple Recency Multiplier: Gives a positive score if used in the last 7 days.
    recency_score = max(0, 7 - days_since_last_used) * 0.5 
    
    new_rank = usage_score + recency_score
    
    Feed.objects.filter(pk=feed_instance.pk).update(Rank=new_rank)


# ----------------------------------------------------------------------
# 1. Post Feed (List) and Post Creation (Create) Endpoint
# ----------------------------------------------------------------------

class PostListCreateView(generics.ListCreateAPIView):
    """
    Handles GET (list feed) and POST (create new post) requests.
    The POST call relies on the serializer to parse tags from text_content/description,
    and the signal to update the Feed table.
    """
    queryset = Post.objects.filter(is_published=True).select_related('creator')
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return PostCreateSerializer
        return PostListSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response(serializer.data)

    def perform_create(self, serializer):
        """
        Injects the current user as the creator and sets the posted_by status.
        The save() call triggers the post_save signal, which handles the Feed update.
        """
        user = self.request.user
        
        if user.is_superuser:
            posted_by = 'ADMIN'
        elif user.is_staff:
            posted_by = 'STAFF'
        else:
            posted_by = 'USER'
        
        serializer.save(creator=user, posted_by=posted_by)


# ----------------------------------------------------------------------
# 2. Authenticated User's Own Post List Endpoint (GET /api/content/self/)
# ----------------------------------------------------------------------

class UserPostListView(generics.ListAPIView):
    """
    Returns a list of posts created only by the currently authenticated user.
    """
    serializer_class = PostListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Post.objects.filter(creator=user).select_related('creator').order_by('-created_at')

    def get_serializer_context(self):
        return {'request': self.request}


# ----------------------------------------------------------------------
# 3. Public User's Post List Endpoint (GET /api/content/user/{user_is}/)
# ----------------------------------------------------------------------

class PublicUserPostListView(generics.ListAPIView):
    """
    Returns a list of published posts created by a specific user (identified by user_is UUID).
    """
    serializer_class = PostListSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_url_kwarg = 'user_is' 

    def get_queryset(self):
        user_uuid = self.kwargs.get(self.lookup_url_kwarg)
        
        try:
            creator_user = User.objects.get(user_is=user_uuid)
        except User.DoesNotExist:
            return Post.objects.none() 

        return Post.objects.filter(
            creator=creator_user, 
            is_published=True
        ).select_related('creator').order_by('-created_at')
        
    def get_serializer_context(self):
        return {'request': self.request}


# ----------------------------------------------------------------------
# 4. Post Detail Endpoint (GET /api/content/<content_id>/)
# ----------------------------------------------------------------------

class PostDetailView(generics.RetrieveAPIView):
    """
    Retrieves a single published post by its content_id (UUID).
    """
    queryset = Post.objects.filter(is_published=True).select_related('creator')
    serializer_class = PostListSerializer
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'content_id' 
    
    def get_serializer_context(self):
        return {'request': self.request}


# ----------------------------------------------------------------------
# 5. Post List By Tags Endpoint (GET /api/content/filter-by-tags/?tags=tag1,tag2,...)
# ----------------------------------------------------------------------

class PostListByTagsView(generics.ListAPIView):
    """
    Returns a list of published posts matching a comma-separated list of tags.
    """
    serializer_class = PostListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Post.objects.filter(is_published=True).select_related('creator')
        tags_param = self.request.query_params.get('tags')
        
        if tags_param:
            tag_list = [tag.strip().upper() for tag in tags_param.split(',') if tag.strip()]
            
            # Use __overlap for finding posts that share ANY tag in the provided list.
            queryset = queryset.filter(tags__overlap=tag_list)
            
        return queryset.order_by('-created_at')
        
    def get_serializer_context(self):
        return {'request': self.request}


# ----------------------------------------------------------------------
# 6. Hype (Like) Toggle Endpoint (POST /api/content/<content_id>/hype/)
# ----------------------------------------------------------------------

class HypeToggleView(generics.UpdateAPIView):
    """
    Allows a user to toggle (add/remove) a Hype for a specific post.
    """
    queryset = Post.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'content_id' 

    def post(self, request, *args, **kwargs):
        post = self.get_object()
        user = request.user
        
        hype_qs = Hype.objects.filter(user=user, post=post)
        
        if hype_qs.exists():
            hype_qs.delete()
            return Response({'hyped': False, 'hype_count': post.Hypes.count()}, status=status.HTTP_200_OK)
        else:
            Hype.objects.create(user=user, post=post)
            return Response({'hyped': True, 'hype_count': post.Hypes.count()}, status=status.HTTP_201_CREATED)


# ----------------------------------------------------------------------
# 7. Tag/Feed List Endpoint (GET /api/content/tags/)
# ----------------------------------------------------------------------

class FeedListView(generics.ListAPIView):
    """
    Returns a sorted list of unique tags (Feed model entries).
    Sorting is determined by the 'sort' query parameter.
    """
    queryset = Feed.objects.all()
    serializer_class = FeedSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = self.queryset
        sort_by = self.request.query_params.get('sort', 'ranked').lower()
        
        sort_mapping = {
            'ranked': '-Rank',           
            'alpha': 'tag',              
            'latest': '-last_used_at',   
            'oldest': 'created_at',      
            'popular': '-total_used',    
        }
        
        order_field = sort_mapping.get(sort_by, '-Rank')
        
        return queryset.order_by(order_field)
    
# 8. Comment Endpoints (GET list, POST create)
class CommentListCreateView(generics.ListCreateAPIView):
    """
    Handles listing comments for a specific post and creating a new comment 
    (either top-level or a reply).
    """
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs.get('content_id')
        
        # Get only top-level comments for the list view
        return Comment.objects.filter(
            post__content_id=post_id,
            parent_comment__isnull=True
        ).select_related('user').prefetch_related('replies').order_by('-created_at')

    def perform_create(self, serializer):
        post_id = self.kwargs.get('content_id')
        try:
            post = Post.objects.get(content_id=post_id)
        except Post.DoesNotExist:
            raise status.HTTP_404_NOT_FOUND("Post not found.")
        
        # The serializer handles validation of 'parent_comment' (if it's a reply)
        serializer.save(user=self.request.user, post=post)
        
        
# 9. Comment Detail/Delete Endpoint
class CommentDestroyView(generics.DestroyAPIView):
    """
    Allows the comment creator or an admin/staff to delete a comment.
    """
    queryset = Comment.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    lookup_field = 'pk' # Use the primary key (id) for lookup

    def get_object(self):
        obj = super().get_object()
        # Ensure the comment belongs to the correct post ID
        if str(obj.post.content_id) != self.kwargs.get('content_id'):
            raise status.HTTP_404_NOT_FOUND("Comment not found on this post.")
        return obj

    def perform_destroy(self, instance):
        # Basic ownership check
        if instance.user != self.request.user and not self.request.user.is_staff and not self.request.user.is_superuser:
            raise permissions.PermissionDenied("You do not have permission to delete this comment.")
        
        instance.delete()