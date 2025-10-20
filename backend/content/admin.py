from django.contrib import admin
from .models import Post, Hype, Comment, Feed 

# ----------------------------------------------------------------------
# 1. Inline Admin for Related Models (Hypes and Comments)
# ----------------------------------------------------------------------

class HypeInline(admin.TabularInline):
    """Displays Hypes related to a post within the PostAdmin view."""
    model = Hype
    extra = 0  
    readonly_fields = ('user', 'created_at')
    can_delete = False

class CommentInline(admin.StackedInline):
    """
    Displays comments related to a post within the PostAdmin view.
    Includes parent_comment for nesting context.
    """
    model = Comment
    extra = 0
    fields = ('user', 'text', 'parent_comment', 'created_at')
    readonly_fields = ('user', 'created_at')


# ----------------------------------------------------------------------
# 2. Main Post Admin (Fixed 'total_hypes' references)
# ----------------------------------------------------------------------

@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin configuration for the Post model."""
    
    list_display = (
        'content_id',
        'creator',
        'content_type',
        'posted_by',
        'get_hype_count', 
        'get_comment_count', 
        'is_published',
        'created_at',
        'updated'
    )
    
    search_fields = ('content_id', 'creator__username', 'description', 'feed_types')
    list_filter = ('content_type', 'posted_by', 'is_published', 'created_at')
    
    fieldsets = (
        ('Content Details', {
            'fields': (
                ('creator', 'posted_by'),
                ('content_type', 'media_file'),
                'description',
                'text_content',
                'feed_types',
            )
        }),
        ('Status and Dates', {
            'fields': (
                'is_published',
                'updated',
                'created_at',
                'updated_at',
            ),
            'classes': ('collapse',), 
        }),
    )

    inlines = [HypeInline, CommentInline] 

    # FIX: Add 'get_hype_count' to readonly_fields to allow it to be displayed
    # and remove any reference to the old, deleted field 'total_hypes'.
    readonly_fields = (
        'content_id', 
        'created_at', 
        'updated_at', 
        'updated',
        'get_hype_count' # CORRECTED: Use the method name here.
    ) 
    
    def get_hype_count(self, obj):
        """Custom method to display the count of related Hype objects."""
        return obj.Hypes.count()
    get_hype_count.short_description = 'Hypes' 
    
    def get_comment_count(self, obj):
        return obj.comments.count()
    get_comment_count.short_description = 'Comments'


# ----------------------------------------------------------------------
# 3. Comment Admin (NEW)
# ----------------------------------------------------------------------

@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """Admin configuration for the Comment model."""
    # list_display = ('id', 'user', 'post_link', 'text_preview', 'parent_comment', 'created_at')
    list_display = ('id', 'user', 'post_link', 'text_preview', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__username', 'post__content_id', 'text')
    raw_id_fields = ('user', 'post', 'parent_comment') 
    ordering = ('-created_at',)

    def post_link(self, obj):
        """Creates a link to the parent post in the admin list."""
        return obj.post.content_id.hex[:10] + '...'
    post_link.short_description = 'Post ID'
    
    def text_preview(self, obj):
        """Shows a truncated preview of the comment text."""
        return obj.text[:50] + '...' if len(obj.text) > 50 else obj.text
    text_preview.short_description = 'Text'


# ----------------------------------------------------------------------
# 4. Simple Admin for Hypes and Feed (Unchanged)
# ----------------------------------------------------------------------

@admin.register(Hype)
class HypeAdmin(admin.ModelAdmin):
    list_display = ('user', 'post', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('user__username', 'post__content_id')
    raw_id_fields = ('user', 'post') 

@admin.register(Feed)
class FeedAdmin(admin.ModelAdmin):
    """Admin configuration for the Feed (Tag Statistics) model."""
    list_display = ('tag', 'total_used', 'Rank', 'created_at', 'last_used_at')
    list_filter = ('created_at',)
    search_fields = ('tag',)
    readonly_fields = ('created_at', 'last_used_at', 'total_used', 'Rank')
    ordering = ('-Rank', '-total_used')