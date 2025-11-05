import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as user_models;
import '../models/content_model.dart' as content_models;
import 'profile_screen.dart';
import 'comment_screen.dart';
import 'post_creation_screen.dart';
import 'dart:async';
import 'dart:developer';

// 🚨 NEW IMPORT: Video Player for the post feed
import 'package:video_player/video_player.dart';

// Enum for menu options
enum UserMenuOption { profile, logout }

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String accessToken;

  const HomeScreen({
    super.key,
    required this.onLogout,
    required this.accessToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // CRITICAL: Separate future for UserData to drive the outer FutureBuilder
  late Future<user_models.UserProfile> _userDataFuture;
  // Separate future for the Content Feed
  Future<List<content_models.ContentPost>>? _contentFeedFuture;

  // Local cache of posts for easy update access (e.g., hype status)
  List<content_models.ContentPost> _currentPosts = [];

  @override
  void initState() {
    super.initState();
    // Start fetching user data immediately. The result will then trigger the content fetch.
    _userDataFuture = _fetchUserDataAndFeedChain();
  }

  // --- Data Fetching and Management Methods (No Functional Changes Needed) ---

  // A single method to fetch user data AND trigger the content feed fetch
  // Also serves as the onRefresh callback for the RefreshIndicator
  Future<user_models.UserProfile> _fetchUserDataAndFeedChain() async {
    // 1. Fetch User Data
    try {
      final userData = await _authService.getUserData();

      if (!mounted) {
        return userData;
      }

      // Map List<TagInfo> (userData.feedTypes) to List<String> (feedTypeStrings)
      final feedTypeStrings = userData.feedTypes
          ?.map((tagInfo) => tagInfo.tag)
          .toList() ?? <String>[];

      // 2. Trigger Content Feed Fetch based on new user data (feed types: List<String>)
      if (feedTypeStrings.isNotEmpty) {
        // Trigger content fetch (updates _contentFeedFuture)
        _fetchContentFeed(feedTypeStrings);
      } else {
        log('User has no feed types, setting empty feed.');
        setState(() {
          _currentPosts = []; // Ensure local cache is clear
          _contentFeedFuture = Future.value([]);
        });
      }

      // Return the user data for the outer FutureBuilder to display
      return userData;
    } catch (error) {
      log("Error fetching user data/feed types: $error", error: error);

      if (!mounted) rethrow;

      // Check for session/auth error
      if (error.toString().contains('Session expired') ||
          error.toString().contains('401')) {
        // Use a PostFrameCallback to safely call logout after build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLogout());
      } else {
        // Show general error for user data fetch
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to load user profile: ${error.toString().split(':').last.trim()}'),
            ),
          );
        }
      }

      // Propagate the error to the outer FutureBuilder
      rethrow;
    }
  }

  // Method to fetch the content feed, updates _contentFeedFuture and _currentPosts
  Future<void> _fetchContentFeed(List<String> feedTypes) async {
    final newFeedFuture =
        _authService.fetchContentByFeedTypes(feedTypes).then((posts) {
      if (mounted) {
        setState(() {
          // Update the local cache on successful fetch
          _currentPosts = posts;
        });
      }
      return posts; // Return posts for the FutureBuilder
    }).catchError((error) {
      log('Error loading feed: Network or server error: $error', error: error);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load feed: Network or server error.'),
          ),
        );
      }
      // Re-throw the error so the FutureBuilder can handle it
      throw error;
    });

    setState(() {
      _contentFeedFuture = newFeedFuture;
    });

    try {
      await _contentFeedFuture;
    } catch (e) {
      log('Content feed future completed with error (expected for RefreshIndicator): $e');
    }
  }

  // Updates a single post's hype status in the local cache and UI
  void _updatePostHypeStatus(
      String postId, int newHypeCount, bool newIsHyped) {
    setState(() {
      _currentPosts = _currentPosts.map((post) {
        if (post.id == postId) {
          return post.copyWith(
            hypeCount: newHypeCount,
            isHyped: newIsHyped,
          );
        }
        return post;
      }).toList();
    });
  }

  // Handles the selection from the dropdown menu (No changes needed)
  void _handleMenuSelection(UserMenuOption result) async {
    switch (result) {
      case UserMenuOption.profile:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userDataFuture: _authService.getUserData(),
            ),
          ),
        );
        setState(() {
          _userDataFuture = _fetchUserDataAndFeedChain();
        });
        break;
      case UserMenuOption.logout:
        widget.onLogout();
        break;
    }
  }

  // Widget to display individual content post (Uses the new _PostContentWidget)
  Widget _buildContentCard(content_models.ContentPost post) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Creator and Date)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueGrey.shade100,
                  backgroundImage:
                      (post.creator.profileImageUrl?.isNotEmpty ?? false)
                          ? NetworkImage(post.creator.profileImageUrl!)
                              as ImageProvider
                          : null,
                  child: (post.creator.profileImageUrl == null ||
                          post.creator.profileImageUrl!.isEmpty)
                      ? Text(
                          post.creator.username[0].toUpperCase(),
                          style: TextStyle(
                              color: Colors.blueGrey.shade800,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.creator.username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  // Display date in a friendly format
                  '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            // 🚨 CRITICAL CHANGE: Use the new StatefulWidget here to manage video state
            _PostContentWidget(post: post),
            
            // Description / Caption
            if (post.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(post.description,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),

            // Tags
            Wrap(
              spacing: 6.0,
              children: (post.feedTypes ?? <String>[]) // Use empty list for safety
                  .map((tag) => Chip(
                        label: Text('#$tag',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.indigo)),
                        backgroundColor: Colors.indigo.shade50,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
            const Divider(height: 18),

            // Hype and Comments Row
            Row(
              children: [
                // --- Hype Button ---
                SizedBox(
                  width: 38,
                  height: 38,
                  child: IconButton(
                    icon: Icon(
                      post.isHyped
                          ? Icons.local_fire_department
                          : Icons.local_fire_department_outlined,
                      color: post.isHyped
                          ? Colors.amber.shade700
                          : Colors.grey.shade600,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      try {
                        final result =
                            await _authService.toggleHype(postId: post.id);

                        if (!mounted) return;

                        // Update the UI state with the new count and status
                        _updatePostHypeStatus(
                          post.id,
                          result['hype_count'] as int,
                          result['hyped'] as bool,
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Failed to hype post: ${e.toString().split(':').last.trim()}')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text('${post.hypeCount} Hype',
                    style: const TextStyle(fontWeight: FontWeight.w500)),

                // --- Comment Count ---
                const SizedBox(width: 16),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: IconButton(
                    icon: const Icon(Icons.comment_outlined,
                        size: 24, color: Colors.teal),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Navigate to the CommentScreen, passing the entire ContentPost object.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CommentScreen(
                              post: post,
                              // FIX: 'onCommentCountUpdated' -> 'onCountUpdated'
                              onCountUpdated: (newCount) {
                                // Local update for the comment count
                                setState(() {
                                  _currentPosts = _currentPosts.map((p) {
                                    if (p.id == post.id) {
                                      return p.copyWith(commentCount: newCount);
                                    }
                                    return p;
                                  }).toList();
                                });
                              }),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Text('${post.commentCount} Comments',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method (Unchanged structure) ---

  @override
  Widget build(BuildContext context) {
    final isMediaAttached = _contentFeedFuture != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turn-In'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: 'Refresh Feed',
            onPressed: () {
              setState(() {
                _userDataFuture = _fetchUserDataAndFeedChain();
              });
            },
          ),
          // Dropdown Menu
          PopupMenuButton<UserMenuOption>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<UserMenuOption>>[
              const PopupMenuItem<UserMenuOption>(
                value: UserMenuOption.profile,
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<UserMenuOption>(
                value: UserMenuOption.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.account_circle, size: 30),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<user_models.UserProfile>(
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            final errorString = userSnapshot.error.toString();

            if (errorString.contains('Session expired') ||
                errorString.contains('401')) {
              return const Center(
                  child: Text('Session expired. Redirecting to login...'));
            }
            return Center(
                child: Text(
                    'Error fetching user data: ${errorString.split(':').last.trim()}',
                    textAlign: TextAlign.center));
          } else if (userSnapshot.hasData) {
            final userData = userSnapshot.data!;

            final feedTypesList = userData.feedTypes
                    ?.map((tagInfo) => tagInfo.tag)
                    .toList() ??
                <String>[];

            final feedTypesDisplay = (feedTypesList.isNotEmpty)
                ? ' (Types: ${feedTypesList.join(', ')})'
                : ' (No preferences set)';

            return RefreshIndicator(
              onRefresh: () => _fetchUserDataAndFeedChain(),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE CARD START (Unchanged) ---
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.teal.shade100,
                              backgroundImage: (userData.profileImage != null &&
                                      userData.profileImage!.isNotEmpty)
                                  ? NetworkImage(userData.profileImage!)
                                      as ImageProvider
                                  : null,
                              child: (userData.profileImage == null ||
                                      userData.profileImage!.isEmpty)
                                  ? const Icon(Icons.person,
                                      size: 28, color: Colors.teal)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back!',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                                Text(userData.username,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    // --- PROFILE CARD END ---

                    // --- FEED HEADER ---
                    Text('Your Feed$feedTypesDisplay',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                    const SizedBox(height: 10),

                    // --- CONTENT FEED SECTION ---
                    Expanded(
                      child: FutureBuilder<List<content_models.ContentPost>>(
                        future: _contentFeedFuture,
                        builder: (context, contentSnapshot) {
                          final isLoading = contentSnapshot.connectionState ==
                              ConnectionState.waiting;

                          if (isLoading && _currentPosts.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (contentSnapshot.hasError && _currentPosts.isEmpty) {
                            return Center(
                                child: Text(
                                    'Error loading feed: ${contentSnapshot.error}',
                                    textAlign: TextAlign.center));
                          }

                          final posts = _currentPosts;

                          if (posts.isEmpty && !isLoading) {
                            return Center(
                                child: Text(
                                    'No content found for your feed types. Try updating your profile preferences. ${feedTypesList.isEmpty ? 'Tap the profile icon > Profile to set preferences.' : ''}',
                                    textAlign: TextAlign.center));
                          }

                          return ListView.builder(
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return _buildContentCard(posts[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No user data available.'));
          }
        },
      ),

      // Floating Action Button to navigate to Post Creation
      floatingActionButton: FutureBuilder<user_models.UserProfile>(
          future: _userDataFuture,
          builder: (context, userSnapshot) {
            final availableTags = userSnapshot.hasData
                ? userSnapshot.data!.feedTypes
                        ?.map((tagInfo) => tagInfo.tag) // Extract the string tag
                        .toList() ??
                    <String>['GENERAL']
                : <String>['GENERAL']; // Fallback tag list

            return FloatingActionButton(
              onPressed: userSnapshot.hasData
                  ? () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PostCreationScreen(
                            authService: _authService,
                            availableFeedTypes: availableTags,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _userDataFuture = _fetchUserDataAndFeedChain();
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Post published successfully!')),
                          );
                        }
                      }
                    }
                  : null, // onPressed is null while loading or on error
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            );
          }),
    );
  }
}

// -------------------------------------------------------------
// 🚨 NEW WIDGET: _PostContentWidget
// This new StatefulWidget manages the video player lifecycle for each post.
// -------------------------------------------------------------
class _PostContentWidget extends StatefulWidget {
  final content_models.ContentPost post;

  const _PostContentWidget({required this.post});

  @override
  State<_PostContentWidget> createState() => _PostContentWidgetState();
}

class _PostContentWidgetState extends State<_PostContentWidget> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  // Handle case where post data changes (e.g., in a complex list update)
  @override
  void didUpdateWidget(covariant _PostContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.mediaFileUrl != oldWidget.post.mediaFileUrl ||
        widget.post.contentType != oldWidget.post.contentType) {
      _disposeVideoController();
      _initializeMedia();
    }
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
    _initializeVideoPlayerFuture = null;
  }

  @override
  void dispose() {
    _isDisposed = true; // Safety flag
    _disposeVideoController();
    super.dispose();
  }

  void _initializeMedia() {
    final post = widget.post;
    final isValidUrl = post.mediaFileUrl != null &&
        (post.mediaFileUrl!.startsWith('http://') ||
            post.mediaFileUrl!.startsWith('https://'));

    if (post.contentType == 'VIDEO' && isValidUrl) {
      // Use VideoPlayerController.networkUrl for web/remote files
      _videoController = VideoPlayerController.networkUrl(Uri.parse(post.mediaFileUrl!));
      _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
        if (!_isDisposed && mounted) {
          // No auto-play on initial load; user must tap.
          setState(() {});
        }
      });
      _videoController!.setLooping(true);
    }
  }

  Widget _buildVideoControls() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const SizedBox.shrink();
    }
    
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(50),
        ),
        child: IconButton(
          icon: Icon(
            _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          },
        ),
      ),
    );
  }

  // --- Main Build Method for Content ---
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    bool isValidImageUrl = post.mediaFileUrl != null &&
        (post.mediaFileUrl!.startsWith('http://') ||
            post.mediaFileUrl!.startsWith('https://'));

    // 1. VIDEO CONTENT
    if (post.contentType == 'VIDEO' && isValidImageUrl) {
      if (_initializeVideoPlayerFuture == null) {
        // Fallback for cases where initialization failed early or wasn't triggered
        return _buildMediaError('VIDEO');
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_videoController!.value.hasError) {
                return _buildMediaError('VIDEO');
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      VideoPlayer(_videoController!),
                      // Custom controls overlay
                      _buildVideoControls(), 
                    ],
                  ),
                ),
              );
            } else {
              // Loading state
              return Container(
                height: 200,
                color: Colors.grey.shade200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text('Loading Video: ${post.mediaFileUrl!.split('/').last}'),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      );
    } 
    
    // 2. IMAGE CONTENT
    else if (post.contentType == 'IMAGE' && isValidImageUrl) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Image.network(
                post.mediaFileUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 400, 
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildMediaError('IMAGE');
                },
              ),
            ),
          ),
        ),
      );
    } 
    
    // 3. TEXT CONTENT
    else if (post.textContent != null && post.textContent!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
        child: Text(
          post.textContent!,
          style: const TextStyle(fontSize: 16),
        ),
      );
    } 
    
    // 4. FALLBACK / NO CONTENT
    else {
      return const SizedBox.shrink();
    }
  }

  // Error/Placeholder Widget for images and videos that fail to load
  Widget _buildMediaError(String type) {
    return Container(
      height: 200, 
      width: double.infinity,
      color: Colors.red.shade50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'VIDEO' ? Icons.videocam_off : Icons.broken_image,
              size: 55, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text(
            '$type Media Failed to Load',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}