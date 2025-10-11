import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_frontend/data/models/post.dart';
import 'package:flutter_frontend/data/services/post_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'feed_provider.freezed.dart';
part 'feed_provider.g.dart';

/// 1. Feed State Model (Freezed)
@freezed
// FIX: Must be abstract to use the _$FeedState mixin
abstract class FeedState with _$FeedState { 
  const factory FeedState({
    @Default(true) bool isLoading,
    @Default([]) List<Post> posts,
    String? error,
  }) = _FeedState;
}

/// 2. Feed State Notifier (Riverpod)
@Riverpod(keepAlive: true)
class FeedNotifier extends _$FeedNotifier {
  late final PostService _postService;

  @override
  FeedState build() {
    _postService = ref.read(postServiceProvider);
    
    // Start fetching posts immediately when the provider is initialized
    fetchPosts();
    
    return const FeedState();
  }

  /// Fetches the list of posts from the server.
  Future<void> fetchPosts() async {
    // Prevent fetching if already loading to avoid duplicate network calls
    if (state.isLoading) return; 

    // Reset error state and set loading to true
    state = state.copyWith(isLoading: true, error: null);

    try {
      final posts = await _postService.fetchFeedPosts();
      
      state = state.copyWith(
        posts: posts,
        isLoading: false,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Error fetching feed: $e');
      }
      state = state.copyWith(
        error: e is DioException ? 'Network error: Failed to load feed.' : 'An unknown error occurred.',
        isLoading: false,
      );
    }
  }

  /// Handles toggling the hype (like) status for a post.
  Future<void> toggleHype(String postId) async {
    try {
      // 1. Optimistically update the local state
      state = state.copyWith(
        posts: state.posts.map((post) {
          if (post.id == postId) {
            // Toggle the `isHype` status and adjust the hype count
            return post.copyWith(
              isHyped: !post.isHyped,
              hypeCount: post.isHyped ? post.hypeCount - 1 : post.hypeCount + 1,
            );
          }
          return post;
        }).toList(),
      );

      // 2. Call the service to update the backend
      await _postService.toggleHype(postId);
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to toggle hype: $e');
      }
      // If the backend call fails, revert the optimistic local change
      // A more robust app would also show an error message.
      await fetchPosts(); // Re-fetch to synchronize state with server
    }
  }
}
