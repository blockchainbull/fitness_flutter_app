// lib/app.dart - Replace your current HealthAIApp class with this
import 'package:flutter/material.dart';
import 'package:user_onboarding/config/home_routes.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/auth/screens/login_screens.dart';
import 'package:user_onboarding/features/home/screens/home_page.dart';
import 'package:user_onboarding/features/onboarding/screens/onboarding_flow.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';

// Global key to access the app state from anywhere
final GlobalKey<_HealthAIAppState> appStateKey = GlobalKey<_HealthAIAppState>();

class HealthAIApp extends StatefulWidget {
  final bool hasValidLogin;
  final UserProfile? userProfile;

  const HealthAIApp({
    Key? key,
    required this.hasValidLogin,
    this.userProfile,
  }) : super(key: key);

  @override
  State<HealthAIApp> createState() => _HealthAIAppState();

  // Static method to refresh auth state
  static void refreshAuthState() {
    appStateKey.currentState?._checkAuthState();
  }
}

class _HealthAIAppState extends State<HealthAIApp> with WidgetsBindingObserver {
  bool? _hasValidLogin;
  UserProfile? _userProfile;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the values from main.dart
    _hasValidLogin = widget.hasValidLogin;
    _userProfile = widget.userProfile;
    
    // Add observer to detect when app comes back from background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When app resumes, check auth state
    if (state == AppLifecycleState.resumed) {
      _checkAuthState();
    }
  }

  // This method will be called after logout to refresh the auth state
  Future<void> _checkAuthState() async {
    if (_isChecking) return; // Prevent multiple simultaneous checks
    
    setState(() {
      _isChecking = true;
    });

    try {
      print('🔄 Checking authentication state...');
      
      final isLoggedIn = await UserManager.isLoggedIn();
      UserProfile? profile;
      
      if (isLoggedIn) {
        profile = await UserManager.getCurrentUser();
        print('✅ User is logged in: ${profile?.name ?? 'Unknown'}');
      } else {
        print('❌ User is not logged in');
      }
      
      if (mounted) {
        setState(() {
          _hasValidLogin = isLoggedIn;
          _userProfile = profile;
          _isChecking = false;
        });
        
        print('🔄 Auth state updated: isLoggedIn=$isLoggedIn');
      }
    } catch (e) {
      print('❌ Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _hasValidLogin = false;
          _userProfile = null;
          _isChecking = false;
        });
      }
    }
  }

  // Static method that can be called from anywhere to refresh auth state
  static void refreshAuthState(BuildContext context) {
    final state = context.findAncestorStateOfType<_HealthAIAppState>();
    state?._checkAuthState();
  }

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
          if (_hasValidLogin != true || _userProfile == null) {
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
    // Show loading indicator while checking auth state
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If user has valid login and profile, go to home
    if (_hasValidLogin == true && _userProfile != null) {
      return HomePage(userProfile: _userProfile!);
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
        backgroundColor: Colors.blue, // Blue app bar
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
          backgroundColor: Colors.blue, // Blue buttons
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
        color: Colors.blue, // Blue icons
      ),
      colorScheme: ColorScheme.light().copyWith(
        primary: Colors.blue,
        secondary: Colors.blue.shade700,
      ),
    );
  }
}