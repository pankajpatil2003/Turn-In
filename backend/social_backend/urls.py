from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

# Import JWT Views for refresh/verify tokens
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView

# --- Custom Accounts Views ---
from accounts.views import (
    MyTokenObtainPairView,  
    UsernameCheckView,      
    RequestOTPView,         
    FinalRegisterView,      
    StudentProfileUpdateView, # IMPORTED: New Profile View
)

urlpatterns = [
    # Django Admin Site
    path('admin/', admin.site.urls),

    # =================================================================
    # 1. AUTHENTICATION & PROFILE ENDPOINTS
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
    
    # NEW: Profile Management Endpoint
    path('api/profile/', StudentProfileUpdateView.as_view(), name='user_profile_update'), 


    # =================================================================
    # 2. APPLICATION CONTENT ENDPOINTS
    # =================================================================
    
    # Placeholder for the content app
    path('api/content/', include('content.urls')), 
]

# Serve media files (like profile pictures) during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)