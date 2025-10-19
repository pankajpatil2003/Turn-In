// lib/screens/home_screen.dart (Final Content Feed Integration with 'feedTypes')

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/content_model.dart'; 
import 'profile_screen.dart'; 
import '../config/api_config.dart'; 
import 'dart:async'; // <--- ADD THIS IMPORT

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Method to fetch user data and chain content feed fetch
  void _fetchUserData() {
    setState(() {
      _userDataFuture = _authService.getUserData();
    });
    
    // Chain content fetch after user data is available
    _userDataFuture!.then((userData) {
      // CORRECTED: Use userData.feedTypes instead of userData.tags
      if (userData.feedTypes.isNotEmpty) { 
        // CORRECTED: Call the new function name, passing feedTypes
        _fetchContentFeed(userData.feedTypes);
      } else {
        // User has no feed types - show empty feed
        setState(() {
          _contentFeedFuture = Future.value([]); 
        });
      }
    }).catchError((error) {
      // Handle error from user data fetch
      print("Error fetching user data for feed types: $error");
      setState(() {
        _contentFeedFuture = Future.error('Failed to load user preferences for feed.');
      });
    });
  }
  
  // Method to fetch the content feed
  // CORRECTED: Parameter name now suggests feed types
  void _fetchContentFeed(List<String> feedTypes) {
    setState(() {
      // CORRECTED: Use the renamed function in AuthService
      _contentFeedFuture = _authService.fetchContentByFeedTypes(feedTypes); 
    });
  }

  // Handles the selection from the dropdown menu (Unchanged logic)
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
        _fetchUserData();
        break;
      case UserMenuOption.logout:
        widget.onLogout();
        break;
    }
  }

  // Widget to display individual content post (Unchanged logic)
  Widget _buildContentCard(ContentPost post) {
    // Determine content widget based on type
    Widget contentWidget;
    
    // Note: Video content is currently omitted for simplicity, but the structure supports it.
    if (post.contentType == 'IMAGE' && post.mediaFileUrl != null) {
      contentWidget = Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            post.mediaFileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
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
            
            // Content (Text or Image)
            contentWidget,
            
            // Description / Caption (if main content is image/video)
            if (post.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                child: Text(post.description, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),

            // Tags
            Wrap(
              spacing: 6.0,
              children: post.tags.map((tag) => Chip(
                label: Text('#$tag', style: const TextStyle(fontSize: 12, color: Colors.indigo)),
                backgroundColor: Colors.indigo.shade50,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const Divider(height: 18),
            
            // Footer (Hype Count and Comment Count)
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 20, color: Colors.red),
                const SizedBox(width: 4),
                Text('${post.hypeCount} Hype', style: const TextStyle(fontWeight: FontWeight.w500)),
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
               WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLogout());
               return const Center(child: Text('Session expired. Redirecting to login...'));
             }
            return Center(child: Text('Error fetching user data: ${userSnapshot.error}', textAlign: TextAlign.center));
          } else if (userSnapshot.hasData) {
            final userData = userSnapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE CARD START (Unchanged) ---
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
                  
                  // --- FEED HEADER (Using feedTypes) ---
                  Text(
                    // CORRECTED: Display 'feedTypes' in the header
                    'Your Feed' + (userData.feedTypes.isNotEmpty ? ' (Types: ${userData.feedTypes.join(', ')})' : ''), 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)
                  ),
                  const SizedBox(height: 10),

                  // --- CONTENT FEED SECTION (Unchanged logic) ---
                  Expanded(
                    child: FutureBuilder<List<ContentPost>>(
                      future: _contentFeedFuture,
                      builder: (context, contentSnapshot) {
                        if (contentSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (contentSnapshot.hasError) {
                          return Center(child: Text('Error loading feed: ${contentSnapshot.error}', textAlign: TextAlign.center));
                        } else if (contentSnapshot.hasData) {
                          if (contentSnapshot.data!.isEmpty) {
                            // CORRECTED: Updated message to reflect 'feedTypes'
                            return const Center(child: Text('No content found for your feed types. Try updating your profile preferences.'));
                          }
                          return ListView.builder(
                            itemCount: contentSnapshot.data!.length,
                            itemBuilder: (context, index) {
                              return _buildContentCard(contentSnapshot.data![index]);
                            },
                          );
                        } else {
                          return const Center(child: Text('Loading content feed...')); 
                        }
                      },
                    ),
                  ),
                  
                ],
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