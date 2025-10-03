from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, StudentProfile, OTP # Import all custom models

# 1. Define the StudentProfile as an Inline
# Allows editing student details directly on the User page.
class StudentProfileInline(admin.StackedInline):
    model = StudentProfile
    can_delete = False  
    verbose_name_plural = 'Student Profile Details'
    fk_name = 'user' 

# 2. Customize the User Model Admin
@admin.register(User)
class CustomUserAdmin(UserAdmin):
    # Add 'user_is' to the list display for easy identification
    list_display = ('email', 'username', 'user_is', 'is_staff', 'is_superuser', 'is_active')
    
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'date_joined')
    search_fields = ('email', 'username', 'first_name', 'last_name', 'user_is')
    
    inlines = (StudentProfileInline,)

    # Customize fieldsets to include the 'user_is' field
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        # Make 'user_is' visible but read-only for security
        ('Public Identifier', {'fields': ('user_is',)}),
        # first_name/last_name are optional now
        ('Personal info', {'fields': ('username', 'first_name', 'last_name')}),
        ('Permissions', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    # Ensure 'user_is' is read-only
    readonly_fields = ('user_is', 'last_login', 'date_joined') 
    
    ordering = ('email',)


# 3. Register the OTP Model for Monitoring
@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    """Admin interface for managing and testing OTP records."""
    list_display = ('email', 'otp_code', 'created_at', 'expires_at', 'is_expired')
    search_fields = ('email',)
    list_filter = ('created_at',)
    # Prevent manual modification of time-sensitive fields
    readonly_fields = ('created_at', 'expires_at', 'is_expired')