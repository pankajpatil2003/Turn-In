import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('@$username')),
      body: Center(
        child: Text('Profile page for user: $username'),
      ),
    );
  }
}
