// The base URL for your Django backend.
// Change to your actual server IP or domain when deployed.
// Use 10.0.2.2 for Android emulator to access 'localhost' on your machine.
const String kBaseUrl = 'http://127.0.0.1:8000/api/';

// Auth Endpoints (assuming you use djoser or similar structure)
const String kLoginEndpoint = 'auth/token/login/';
const String kRegisterEndpoint = 'auth/users/';
const String kLogoutEndpoint = 'auth/token/logout/';

// Other Endpoints
const String kPostFeedEndpoint = 'posts/';
const String kProfileDetailEndpoint = 'profiles/'; // e.g., profiles/john_doe/
