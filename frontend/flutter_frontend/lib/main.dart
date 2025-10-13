import 'package:flutter/material.dart';
import 'screens/registration/registration_flow.dart'; // Import the main flow widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Registration Flow',
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
      // Set the RegistrationFlow as the home screen
      home: const RegistrationFlow(),
    );
  }
}