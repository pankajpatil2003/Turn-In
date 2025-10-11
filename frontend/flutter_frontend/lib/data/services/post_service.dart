import 'package:dio/dio.dart';
import 'package:flutter_frontend/data/models/post.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// import '../../core/constants/api_constants.dart';
import 'package:flutter_frontend/core/constants/api_constants.dart';
import 'dio_client.dart';

part 'post_service.g.dart';

/// Riverpod provider for the PostService class.
@Riverpod(keepAlive: true)
PostService postService(Ref ref) {
  // PostService depends only on the Dio client for API calls.
  return PostService(ref.read(dioClientProvider));
}

/// Handles all API calls related to posts and the feed, including fetching and interactions.
class PostService {
  final Dio _dio;

  PostService(this._dio);

  /// Fetches a list of posts for the main feed from the backend.
  Future<List<Post>> fetchFeedPosts() async {
    try {
      final response = await _dio.get(kPostFeedEndpoint); 
      
      // Assuming the API returns a list of post JSON objects under a 'posts' key
      final List<dynamic> postsJson = response.data['posts'] as List<dynamic>;
      
      // Convert the JSON list to a list of Post objects
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } on DioException {
      // Re-throw the DioException to be caught by the FeedNotifier for error handling
      rethrow;
    }
  }

  /// Toggles the hype (like/upvote) status for a specific post.
  Future<void> toggleHype(String postId) async {
    try {
      // API endpoint for toggling hype. Assumes POST to this URL toggles the status.
      await _dio.post('$kPostFeedEndpoint/$postId/hype'); 
    } on DioException {
      rethrow;
    }
  }
}
