from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# --- Simple JWT Views ---
from rest_framework_simplejwt.views import (
    TokenRefreshView,
    TokenVerifyView,
)

# --- Custom Accounts Views ---
from accounts.views import (
    MyTokenObtainPairView,  # Custom login view
    UsernameCheckView,      # New instant username check
    RequestOTPView,         # Step 1 of Registration
    FinalRegisterView,      # Step 2 of Registration
)


urlpatterns = [
    # Django Admin Site
    path('admin/', admin.site.urls),

    # =================================================================
    # 1. AUTHENTICATION & TOKEN ENDPOINTS
    # =================================================================

    # Utility Check
    path('api/check-username/', UsernameCheckView.as_view(), name='check_username'),

    # Registration Steps
    path('api/register/request-otp/', RequestOTPView.as_view(), name='request_otp'),
    path('api/register/final/', FinalRegisterView.as_view(), name='final_register'),

    # Login/Token Endpoints
    path('api/login/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    
    # Placeholder for profile management
    # path('api/profile/', ProfileUpdateView.as_view(), name='user_profile'),


    # =================================================================
    # 2. APPLICATION CONTENT ENDPOINTS
    # =================================================================
    
    # Directs all URLs starting with 'api/content/' to the content app's urls.py
    path('api/content/', include('content.urls')),
]


# =================================================================
# 3. MEDIA FILES (DEVELOPMENT ONLY)
# =================================================================

# This is essential for serving uploaded images/videos during local development.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)