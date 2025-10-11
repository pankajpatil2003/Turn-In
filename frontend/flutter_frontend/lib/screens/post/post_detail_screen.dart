import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Post #$postId')),
      body: Center(
        child: Text('Viewing details for Post ID: $postId'),
      ),
    );
  }
}
