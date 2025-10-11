import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes.dart'; // Import the new router file

void main() {
  // Riverpod requirement: All apps using Riverpod must be wrapped in a ProviderScope.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter instance from the provider
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Social App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Primary color scheme
        primarySwatch: Colors.indigo, 
        // Ensures density adapts based on platform
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Set a modern, clean font
        fontFamily: 'Inter', 
        useMaterial3: true,
        // Define a clean, compact AppBar style
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        )
      ),
      // Use MaterialApp.router and provide the router object
      // GoRouter handles all navigation and authentication-based redirects.
      routerConfig: router,
    );
  }
}
