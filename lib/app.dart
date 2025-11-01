// lib/app.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/config/home_routes.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/auth/screens/login_screens.dart';
import 'package:user_onboarding/features/home/screens/home_page.dart';

class HealthAIApp extends StatelessWidget {
  final bool hasValidLogin;
  final UserProfile? userProfile;

  const HealthAIApp({
    Key? key,
    required this.hasValidLogin,
    this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      // Add the onGenerateRoute function
      onGenerateRoute: (settings) {
        // Check if this is a home route
        if (settings.name?.startsWith('/home/') ?? false) {
          if (!hasValidLogin || userProfile == null) {
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
          return HomeRoutes.generateRoute(
            RouteSettings(
              name: settings.name!.replaceFirst('/home', ''),
              arguments: settings.arguments,
            ),
          );
        }
        
        // Default route handling
        return MaterialPageRoute(
          builder: (_) => _getInitialScreen(),
        );
      },
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // If user has valid login and profile, go to home
    if (hasValidLogin && userProfile != null) {
      return HomePage(userProfile: userProfile!);
    }
    
    // Otherwise, show login screen (which can navigate to onboarding)
    return const LoginScreen();
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light, // Set to light mode
      scaffoldBackgroundColor: Colors.white, // Light background
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue, // Green app bar
        foregroundColor: Colors.white, // White text and icons on app bar
        elevation: 0,
      ),
      textTheme: const TextTheme(
        // Default text styles in light mode
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.grey.shade50, // Light background for input fields
        labelStyle: TextStyle(color: Colors.grey.shade700), // Darker text for labels
        hintStyle: TextStyle(color: Colors.grey.shade500), // Medium gray for hints
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Green buttons
          foregroundColor: Colors.white, // White text on buttons
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white, // White cards
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Correct IconThemeData, not IconTheme
      iconTheme: IconThemeData(
        color: Colors.blue, // Green icons
      ),
      colorScheme: ColorScheme.light().copyWith(
        primary: Colors.blue,
        secondary: Colors.blue.shade700,
      ),
    );
  }
}