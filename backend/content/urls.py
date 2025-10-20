from django.urls import path
from .views import (
    PostListCreateView, 
    HypeToggleView,
    UserPostListView, 
    PublicUserPostListView,
    FeedListView,
    PostDetailView,         
    PostListByfeed_typesView,  
    CommentListCreateView, 
    CommentDestroyView,   
)

urlpatterns = [
    # 1. Main Feed (GET) and Post Creation (POST)
    # Endpoint: /api/content/
    path('', PostListCreateView.as_view(), name='post-list-create'),
    
    # 2. Authenticated User's Own Posts
    # Endpoint: /api/content/self/
    path('self/', UserPostListView.as_view(), name='user-post-list'),
    
    # 3. Public User's Posts
    # Endpoint: /api/content/user/<user_is>/
    path('user/<uuid:user_is>/', PublicUserPostListView.as_view(), name='public-user-post-list'),

    # 4. Content Detail by ID (Retrieve single post)
    # Endpoint: /api/content/<content_id>/
    path('<uuid:content_id>/', PostDetailView.as_view(), name='post-detail'), 
    
    # 5. Filter by feed_types 
    # Endpoint: /api/content/filter-by-feed_types/?feed_types=tag1,tag2
    path('filter-by-feed_types/', PostListByfeed_typesView.as_view(), name='post-list-by-feed_types'),
    
    # 6. Interaction (Hype Toggle)
    # Endpoint: /api/content/<content_id>/hype/
    path('<uuid:content_id>/hype/', HypeToggleView.as_view(), name='post-hype-toggle'),

    # 7. Comment Endpoints (NEW)
    # Endpoint: /api/content/<content_id>/comments/
    path(
        '<uuid:content_id>/comments/', 
        CommentListCreateView.as_view(), 
        name='comment-list-create'
    ),
    
    # 8. Comment Delete (NEW)
    # Endpoint: /api/content/<content_id>/comments/<pk>/
    path(
        '<uuid:content_id>/comments/<int:pk>/', 
        CommentDestroyView.as_view(), 
        name='comment-delete'
    ),
    
    # 9. Feed/feed_types List (Ranked/Sorted feed_types)
    # Endpoint: /api/content/feed_types/
    path('feed_types/', FeedListView.as_view(), name='feed-tag-list'), 
]