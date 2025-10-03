from django.contrib import admin

from django.contrib import admin
from .models import Post

# Define how the Post model will look in the Admin
@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    # Fields displayed in the list view
    list_display = ('author', 'post_type', 'is_admin_post', 'is_published', 'created_at')
    
    # Fields to filter the list view
    list_filter = ('post_type', 'is_admin_post', 'is_published', 'created_at')
    
    # Fields to use for searching
    search_fields = ('content', 'author__username')
    
    # Make tags easier to see/edit in the form
    # Note: ArrayField is handled well by Django's admin interface
    fields = ('author', 'content', 'media_url', 'media_type', 'is_admin_post', 'post_type', 'tags', 'is_published')