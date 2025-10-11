import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/post/post_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import 'package:flutter_frontend/providers/auth_provider.dart';

// 1. Define Route Names
class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/feed';
  static const String postDetail = '/post/:postId';
  static const String profile = '/profile/:username';
}

// 2. GoRouter Provider
// We use a Provider<GoRouter> to make the router instance accessible everywhere.
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the AuthNotifier state for redirects (login/logout)
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.feed,
    // Debug logging for route transitions
    debugLogDiagnostics: true,
    
    // 3. Redirection Logic (The core of the Auth Check)
    redirect: (BuildContext context, GoRouterState state) {
      // Check if the auth state is still loading
      if (authState.isLoading) return null;
      
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register;

      // If the user is NOT authenticated
      if (!isAuthenticated) {
        // If they are already on login/register, let them stay
        return isLoggingIn ? null : AppRoutes.login;
      }

      // If the user IS authenticated
      if (isLoggingIn) {
        // Redirect them to the main feed screen
        return AppRoutes.feed;
      }

      // No redirection needed
      return null;
    },

    // 4. Router Definitions
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        // Dynamic path for post detail, accessible via state.pathParameters['postId']
        path: AppRoutes.postDetail,
        builder: (context, state) {
          final postId = state.pathParameters['postId'];
          return PostDetailScreen(postId: postId!);
        },
      ),
      GoRoute(
        // Dynamic path for profile, accessible via state.pathParameters['username']
        path: AppRoutes.profile,
        builder: (context, state) {
          final username = state.pathParameters['username'];
          // Use the ProfileScreen to display user data
          return ProfileScreen(username: username!);
        },
      ),
    ],
  );
});
