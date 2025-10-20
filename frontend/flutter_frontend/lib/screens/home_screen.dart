// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/content_model.dart'; 
import 'profile_screen.dart'; 
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
  final AuthService _authService = AuthService();
  Future<UserProfile>? _userDataFuture; 
  Future<List<ContentPost>>? _contentFeedFuture; 
  
  // Local cache of posts for easy update access
  List<ContentPost> _currentPosts = []; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Method to fetch user data and chain content feed fetch
  void _fetchUserData() {
    // Reset user data future
    setState(() {
      _userDataFuture = _authService.getUserData();
    });
    
    // Chain content fetch after user data is available
    _userDataFuture!.then((userData) {
      // 🔥 FIX 1: Handle nullable feedTypes field
      final feedTypes = userData.feedTypes;

      if (feedTypes != null && feedTypes.isNotEmpty) { 
        _fetchContentFeed(feedTypes);
      } else {
        // User has no feed types - show empty feed
        setState(() {
          _currentPosts = []; // Ensure local cache is clear
          _contentFeedFuture = Future.value([]); 
        });
      }
    }).catchError((error) {
      print("Error fetching user data for feed types: $error");
      setState(() {
        _contentFeedFuture = Future.error('Failed to load user preferences for feed.');
      });
    });
  }
  
  // Method to fetch the content feed
  void _fetchContentFeed(List<String> feedTypes) {
    setState(() {
      _contentFeedFuture = _authService.fetchContentByFeedTypes(feedTypes)
        .then((posts) {
          // Update the local cache on successful fetch
          _currentPosts = posts; 
          return posts;
        }).catchError((error) {
          // 🛑 This catches the "Type 'Null' is not a subtype of type 'String'" error 
          // that is likely occurring inside ContentPost.fromJson when a required string field is null.
          print('Error loading feed: Exception: Network or server error: $error');
          // You must fix the ContentPost model definition for a permanent solution.
          return Future.error('Error loading feed: Exception: Network or server error: $error');
        });
    });
  }
  
  // Updates a single post's hype status in the local cache and UI
  void _updatePostHypeStatus(String contentId, int newHypeCount, bool newIsHyped) {
    setState(() {
      final index = _currentPosts.indexWhere((p) => p.contentId == contentId);
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
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              userDataFuture: _userDataFuture!,
            ),
          ),
        );
        // Re-fetch all data when returning from ProfileScreen
        _fetchUserData();
        break;
      case UserMenuOption.logout:
        widget.onLogout();
        break;
    }
  }

  // Widget to display individual content post (UPDATED for robust image loading)
  Widget _buildContentCard(ContentPost post) {
    // Determine content widget based on type
    Widget contentWidget;
    
    // CRITICAL CHECK: Ensure mediaFileUrl is not null AND starts with 'http'
    bool isValidImageUrl = post.mediaFileUrl != null && 
                          (post.mediaFileUrl!.startsWith('http://') || post.mediaFileUrl!.startsWith('https://')); 
    print('🔵 Attempting to load image from URL: ${post.mediaFileUrl}');

    if (post.contentType == 'IMAGE' && isValidImageUrl) {
      contentWidget = Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            post.mediaFileUrl!,
            fit: BoxFit.cover,
            // 💡 FIX: Reserve space for the image to prevent UI jump/collapse on load failure
            height: 250, 
            
            // --- Loading Builder for Progress Indicator ---
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  height: 250, // Match reserved height
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null 
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! 
                          : null,
                    ),
                  ),
                ),
              );
            },
            
            // --- Error Builder for Failure Feedback ---
            errorBuilder: (context, error, stackTrace) {
              // Log the specific URL that failed (helpful for debugging API data)
              print('🔴 Image Load Failed for: ${post.mediaFileUrl}');
              
              return Container(
                height: 250, // Match reserved height
                width: double.infinity,
                color: Colors.red.shade50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 50, color: Colors.red.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Image Failed to Load (Invalid URL/Network)', 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 14)
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else if (post.contentType == 'TEXT' && (post.textContent != null && post.textContent!.isNotEmpty)) {
      contentWidget = Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
        child: Text(
          post.textContent!,
          style: const TextStyle(fontSize: 16),
        ),
      );
    } else {
      contentWidget = const SizedBox.shrink(); // Hide if no main content
    }

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
                  // Placeholder logic for profile image
                  child: Text(
                    post.creator.username[0].toUpperCase(),
                    style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold),
                  ), 
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
            
            // Content (Text or Image) - Now robust
            contentWidget,
            
            // Description / Caption
            if (post.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(post.description, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),

            // Tags
            // 🔥 FIX 2: Use null-aware access (?.) and null coalescing (?? [])
            // for post.feedTypes in case it is nullable in ContentPost model.
            Wrap(
              spacing: 6.0,
              children: (post.feedTypes ?? []).map((tag) => Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                backgroundColor: Colors.indigo.shade50,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const Divider(height: 18),
            
            // Hype and Comments Row
            Row(
              children: [
                // --- Hype Button ---
                IconButton(
                  icon: Icon(
                    post.isHyped ? Icons.bolt : Icons.bolt_outlined, // Use bolt icon for 'hype'
                    color: post.isHyped ? Colors.amber.shade700 : Colors.grey.shade600,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    try {
                      // Call the service to toggle the hype status
                      final result = await _authService.toggleHype(post.contentId);

                      // Update the UI state with the new count and status
                      _updatePostHypeStatus(
                        post.contentId,
                        result['hype_count'] as int,
                        result['hyped'] as bool,
                      );
                    } catch (e) {
                      // Display error if the API call fails
                      if(mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to hype post: ${e.toString().split(':').last.trim()}')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 4),
                Text('${post.hypeCount} Hype', style: const TextStyle(fontWeight: FontWeight.w500)),
                
                // --- Comment Count ---
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined, size: 20, color: Colors.teal), 
                const SizedBox(width: 4),
                Text('${post.commentCount} Comments', style: const TextStyle(fontWeight: FontWeight.w500)),
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
        actions: [
          PopupMenuButton<UserMenuOption>(
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<UserMenuOption>>[
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
        future: _userDataFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
              if (userSnapshot.error.toString().contains('Session expired') || userSnapshot.error.toString().contains('401')) {
               // Ensure logout runs after the build is complete
               WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLogout());
               return const Center(child: Text('Session expired. Redirecting to login...'));
              }
            return Center(child: Text('Error fetching user data: ${userSnapshot.error}', textAlign: TextAlign.center));
          } else if (userSnapshot.hasData) {
            final userData = userSnapshot.data!;
            
            // 🔥 FIX 3: Add null check for feedTypes before calling .join()
            final feedTypesDisplay = (userData.feedTypes != null && userData.feedTypes!.isNotEmpty)
                ? ' (Types: ${userData.feedTypes!.join(', ')})'
                : '';
            
            return RefreshIndicator(
              // Allow users to pull down to refresh the feed
              onRefresh: () async {
                _fetchUserData();
                await _contentFeedFuture; // Wait for the new feed to load
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- PROFILE CARD START ---
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.teal.shade100,
                              // CRITICAL: Ensure profileImage is also checked for validity/null
                              backgroundImage: (userData.profileImage != null && userData.profileImage!.isNotEmpty)
                                  ? NetworkImage(userData.profileImage!) 
                                  : null, 
                              child: (userData.profileImage == null || userData.profileImage!.isEmpty)
                                  ? const Icon(Icons.person, size: 40, color: Colors.teal)
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Text(
                                  userData.username, 
                                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // --- PROFILE CARD END ---
                    
                    // --- FEED HEADER ---
                    Text(
                      'Your Feed$feedTypesDisplay', // Use the null-safe display string
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)
                    ),
                    const SizedBox(height: 10),

                    // --- CONTENT FEED SECTION ---
                    Expanded(
                      child: FutureBuilder<List<ContentPost>>(
                        future: _contentFeedFuture,
                        builder: (context, contentSnapshot) {
                          if (contentSnapshot.connectionState == ConnectionState.waiting && _currentPosts.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (contentSnapshot.hasError && _currentPosts.isEmpty) {
                            return Center(child: Text('Error loading feed: ${contentSnapshot.error}', textAlign: TextAlign.center));
                          } else {
                            // Use the local _currentPosts list 
                            final posts = _currentPosts; 
                            
                            if (posts.isEmpty && contentSnapshot.connectionState != ConnectionState.waiting) {
                              return const Center(child: Text('No content found for your feed types. Try updating your profile preferences.'));
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
    );
  }
}