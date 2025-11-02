import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart'; // Ensure this path is correct
import '../models/content_model.dart'; // Ensure this path is correct
import 'profile_screen.dart';
import 'comment_screen.dart';
import 'dart:async';

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
  // Assuming AuthService can be instantiated without an access token
  final AuthService _authService = AuthService();
  
  // 1. CRITICAL: Separate future for UserData to drive the outer FutureBuilder
  late Future<UserProfile> _userDataFuture; 
  // 2. Separate future for the Content Feed
  Future<List<ContentPost>>? _contentFeedFuture;

  // Local cache of posts for easy update access (e.g., hype status)
  List<ContentPost> _currentPosts = [];

  @override
  void initState() {
    super.initState();
    // Start fetching user data immediately. The result will then trigger the content fetch.
    _userDataFuture = _fetchUserDataAndFeedChain();
  }

  // A single method to fetch user data AND trigger the content feed fetch
  // This is used for initial load and pull-to-refresh.
  Future<UserProfile> _fetchUserDataAndFeedChain() async {
    // 1. Fetch User Data
    try {
      final userData = await _authService.getUserData();

      // CRITICAL: Check if component is still mounted before calling setState 
      if (!mounted) {
        // Return a dummy value if unmounted, as the caller (RefreshIndicator)
        // expects a Future<UserProfile> to complete.
        return userData; 
      }
      
      // 2. Trigger Content Feed Fetch based on new user data (feed types)
      final feedTypes = userData.feedTypes ?? [];

      if (feedTypes.isNotEmpty) {
        // Set the content feed future which will be awaited internally
        await _fetchContentFeed(feedTypes);
      } else {
        // User has no feed types - set an empty feed future
        setState(() {
          _currentPosts = []; // Ensure local cache is clear
          _contentFeedFuture = Future.value([]);
        });
      }

      // Return the user data for the outer FutureBuilder to display
      return userData; 
    } catch (error) {
      print("Error fetching user data/feed types: $error");

      // CRITICAL: Check mounted status
      if (!mounted) return Future.error('Unmounted during fetch error'); 

      // Handle potential session expiry error
      if (error.toString().contains('Session expired') ||
          error.toString().contains('401')) {
        // Schedule logout to run after the current build cycle
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLogout());
      } else {
        // Show a transient error message for the user.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load user profile: ${error.toString().split(':').last.trim()}'),
          ),
        );
      }
      
      // Also ensure the feed future is updated with an error state 
      // if the user data fetch failed, so the content section can reflect it.
      setState(() {
        _contentFeedFuture =
            Future.error('Failed to load user preferences for feed.');
      });
      
      // Re-throw the error so the outer FutureBuilder can catch and display it
      rethrow; 
    }
  }

  // Method to fetch the content feed, updates _contentFeedFuture and _currentPosts
  Future<void> _fetchContentFeed(List<String> feedTypes) async {
    final newFeedFuture = _authService.fetchContentByFeedTypes(feedTypes);

    // CRITICAL: Update the state with the new Future immediately
    setState(() {
      // Chain an operation that updates the local cache on success
      _contentFeedFuture = newFeedFuture.then((posts) {
        _currentPosts = posts;
        return posts; // Return the posts for the FutureBuilder
      }).catchError((error) {
        print('Error loading feed: Network or server error: $error');
        
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
    });

    // Await the content future so that onRefresh completes its animation.
    try {
      await _contentFeedFuture;
    } catch (e) {
      // Error is handled above and propagated, just need to await here.
    }
  }

  // Updates a single post's hype status in the local cache and UI
  void _updatePostHypeStatus(String postId, int newHypeCount, bool newIsHyped) {
    setState(() {
      // Use p.id for lookup
      final index = _currentPosts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        // Use the copyWith method from ContentPost to create an updated post object
        _currentPosts[index] = _currentPosts[index].copyWith(
          hypeCount: newHypeCount,
          isHyped: newIsHyped,
        );
      }
    });
  }

  // Handles the selection from the dropdown menu
  void _handleMenuSelection(UserMenuOption result) async {
    switch (result) {
      case UserMenuOption.profile:
        // Use the initialized _userDataFuture or better: pass the current user data
        // For simplicity, we'll keep the Future passing here and rely on the re-fetch
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              // Pass a fresh future to ensure latest data on ProfileScreen load
              userDataFuture: _authService.getUserData(), 
            ),
          ),
        );
        // Re-fetch all data when returning from ProfileScreen 
        // in case preferences were updated
        // CRITICAL: Call the chain method to re-initiate both fetches
        setState(() {
           _userDataFuture = _fetchUserDataAndFeedChain();
        });
        break;
      case UserMenuOption.logout:
        widget.onLogout();
        break;
    }
  }
  
  // NEW: Extracted method to build the main content widget (Image/Text)
  Widget _buildContentWidget(ContentPost post) {
    // CRITICAL CHECK: Ensure mediaFileUrl is not null AND starts with 'http'
    bool isValidImageUrl = post.mediaFileUrl != null &&
        (post.mediaFileUrl!.startsWith('http://') ||
            post.mediaFileUrl!.startsWith('https://'));

    if (post.contentType == 'IMAGE' && isValidImageUrl) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              post.mediaFileUrl!,
              fit: BoxFit.contain,
              height: 400,
              
              // --- Loading Builder for Progress Indicator ---
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    height: 400, // Match reserved height
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
                );
              },

              // --- Error Builder for Failure Feedback ---
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 400, // Match reserved height
                  width: double.infinity,
                  color: Colors.red.shade50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image,
                          size: 50, color: Colors.red.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'Image Failed to Load (Invalid URL/Network)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ), 
        ), 
      ); 
    } else if (post.contentType == 'TEXT' &&
        (post.textContent != null && post.textContent!.isNotEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
        child: Text(
          post.textContent!,
          style: const TextStyle(fontSize: 16),
        ),
      );
    } else {
      return const SizedBox.shrink(); // Hide if no main content
    }
  }

  // Widget to display individual content post (UPDATED to use new hype icon)
  Widget _buildContentCard(ContentPost post) {
    
    final contentWidget = _buildContentWidget(post); // Use the extracted method

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
                  // Check for and display the creator's profile image URL
                  backgroundImage:
                      (post.creator.profileImageUrl?.isNotEmpty ?? false)
                          ? NetworkImage(post.creator.profileImageUrl!)
                                as ImageProvider
                          : null,

                  // Fallback to initial if no image is available
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

            // Content (Text or Image)
            contentWidget,

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
              children: (post.feedTypes ?? [])
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
                // --- Hype Button (Updated Icon) ---
                IconButton(
                  icon: Icon(
                    // UPDATED: Use a distinct fire/hype icon
                    post.isHyped ? Icons.local_fire_department : Icons.local_fire_department_outlined, 
                    color: post.isHyped
                        ? Colors.amber.shade700
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    try {
                      final result = await _authService.toggleHype(
                          post.id.toString()); 

                      // CRITICAL: Check mounted status
                      if (!mounted) return;

                      // Update the UI state with the new count and status
                      _updatePostHypeStatus(
                        post.id,
                        result['hype_count'] as int,
                        result['hyped'] as bool,
                      );
                    } catch (e) {
                      // Display error if the API call fails
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
                const SizedBox(width: 4),
                Text('${post.hypeCount} Hype',
                    style: const TextStyle(fontWeight: FontWeight.w500)),

                // --- Comment Count ---
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined,
                      size: 24, color: Colors.teal),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Navigate to the CommentScreen, passing the entire ContentPost object.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentScreen(post: post),
                      ),
                    );
                  },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turn-In'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 1, // Added elevation for aesthetics
        actions: [
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
      body: FutureBuilder<UserProfile>(
        // Use the initialized _userDataFuture
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            // Error handling is mostly done in _fetchUserDataAndFeedChain 
            // to show SnackBar, but we handle the final display here.

            // Handle specific session expiration within the build method
            if (userSnapshot.error.toString().contains('Session expired') ||
                userSnapshot.error.toString().contains('401')) {
              // Ensure logout runs after the build is complete
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onLogout());
              return const Center(
                  child: Text('Session expired. Redirecting to login...'));
            }
            return Center(
                child: Text('Error fetching user data: ${userSnapshot.error}',
                    textAlign: TextAlign.center));
          } else if (userSnapshot.hasData) {
            final userData = userSnapshot.data!;

            // Add null check for feedTypes before calling .join()
            final feedTypesDisplay =
                (userData.feedTypes != null && userData.feedTypes!.isNotEmpty)
                    ? ' (Types: ${userData.feedTypes!.join(', ')})'
                    : '';

            return RefreshIndicator(
              // Allow users to pull down to refresh the feed
              // CRITICAL: Call the main chain method to re-fetch both user and content
              onRefresh: _fetchUserDataAndFeedChain, 
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE CARD START ---
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
                              // CRITICAL: Ensure profileImage is also checked for validity/null
                              backgroundImage: (userData.profileImage != null &&
                                      userData.profileImage!.isNotEmpty)
                                  ? NetworkImage(userData.profileImage!)
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
                            // Spacer to push the refresh button to the right
                            const Spacer(),
                            // Refresh Button (Optional, as RefreshIndicator covers this)
                            // Keeping it in for explicit visual refresh button
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.teal),
                              onPressed: () {
                                // Explicitly re-initiate the fetch chain on press
                                setState(() {
                                  _userDataFuture = _fetchUserDataAndFeedChain();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- PROFILE CARD END ---

                    // --- FEED HEADER ---
                    Text(
                        'Your Feed$feedTypesDisplay', // Use the null-safe display string
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal)),
                    const SizedBox(height: 10),

                    // --- CONTENT FEED SECTION ---
                    Expanded(
                      child: FutureBuilder<List<ContentPost>>(
                        future: _contentFeedFuture,
                        builder: (context, contentSnapshot) {
                          // Use _currentPosts for UI display when state is waiting, but only if it's not empty
                          if (contentSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              _currentPosts.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (contentSnapshot.hasError &&
                              _currentPosts.isEmpty) {
                            // If there's an error AND no cached posts, show the error.
                            return Center(
                                child: Text(
                                    'Error loading feed: ${contentSnapshot.error}',
                                    textAlign: TextAlign.center));
                          } else {
                            // Use the local _currentPosts list which is updated 
                            // in _fetchContentFeed and _updatePostHypeStatus
                            final posts = contentSnapshot.data ?? _currentPosts;

                            if (posts.isEmpty &&
                                contentSnapshot.connectionState !=
                                    ConnectionState.waiting) {
                              return const Center(
                                  child: Text(
                                      'No content found for your feed types. Try updating your profile preferences.'));
                            }

                            return ListView.builder(
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return _buildContentCard(posts[index]);
                              },
                            );
                          }
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
      // Optional: Add a Floating Action Button for creating a new post
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement navigation to a Post Creation Screen
          print("Navigate to new post screen");
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}