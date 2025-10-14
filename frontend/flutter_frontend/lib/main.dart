// lib/main.dart (Updated to use AuthWrapper)

import 'package:flutter/material.dart';
import 'screens/auth_wrapper.dart'; // <-- Import the new wrapper

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Authentication Flow', // Updated title for clarity
      theme: ThemeData(
        // Configure a modern, clean theme
        primarySwatch: Colors.indigo,
        primaryColor: Colors.indigo,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
        ),
      ),
      // Set the AuthWrapper as the home screen
      // The AuthWrapper will display the LoginScreen by default.
      home: const AuthWrapper(),
    );
  }
}