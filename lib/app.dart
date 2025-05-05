import 'package:flutter/material.dart';
import 'package:user_onboarding/features/onboarding/screens/onboarding_flow.dart';
import 'package:user_onboarding/features/home/screens/home_page.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class HealthAIApp extends StatelessWidget {
  final bool onboardingCompleted;
  final UserProfile? userProfile;
  
  const HealthAIApp({
    Key? key,
    this.onboardingCompleted = false,
    this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: onboardingCompleted && userProfile != null
          ? HomePage(userProfile: userProfile!)
          : const OnboardingFlow(),
    );
  }

  // Extract theme configuration to a separate method for better organization
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // You can add more theme customizations here as needed
      // For example:
      // textTheme, cardTheme, appBarTheme, etc.
    );
  }
}