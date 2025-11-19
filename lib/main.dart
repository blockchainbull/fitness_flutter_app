// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/features/splash/screens/splash_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:user_onboarding/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  
  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Enable for debugging
    );
    print('[Main] Supabase initialized successfully');
  } else {
    print('[Main] WARNING: Supabase credentials missing in .env file');
  }

  await _initializeNotifications();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider()..initUser(),
      child: const MyApp(),
    ),
  );
}

// Initialize and schedule notifications
Future<void> _initializeNotifications() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId != null) {
      print('📱 User found: $userId, checking notifications...');
      await _checkAndRescheduleIfNeeded(userId, prefs);
    } else {
      print('📱 No user logged in, skipping notification scheduling');
    }
  } catch (e) {
    print('⚠️ Error initializing notifications: $e');
  }
}

// Check if notifications need rescheduling
Future<void> _checkAndRescheduleIfNeeded(String userId, SharedPreferences prefs) async {
  final lastScheduled = prefs.getString('notifications_last_scheduled_$userId');
  
  if (lastScheduled == null) {
    // Never scheduled, do it now
    print('📱 First time setup - scheduling notifications...');
    await _scheduleNotifications(userId, prefs);
    return;
  }
  
  final lastDate = DateTime.parse(lastScheduled);
  final now = DateTime.now();
  
  // If last scheduled more than 24 hours ago, reschedule
  if (now.difference(lastDate).inHours > 24) {
    print('📱 Notifications expired (${now.difference(lastDate).inHours}h ago), re-scheduling...');
    await _scheduleNotifications(userId, prefs);
  } else {
    print('✅ Notifications still active (scheduled ${now.difference(lastDate).inHours}h ago)');
  }
}

// Schedule notifications and save timestamp
Future<void> _scheduleNotifications(String userId, SharedPreferences prefs) async {
  try {
    final notificationService = NotificationService();
    
    // Check if already scheduled
    final pending = await notificationService.getPendingNotifications();
    
    if (pending.isEmpty) {
      // Get user profile from cache
      final profileJson = prefs.getString('user_profile');
      
      if (profileJson != null) {
        final userProfile = jsonDecode(profileJson);
        
        await notificationService.scheduleAllNotifications(
          userId,
          userProfile,
        );
        
        // Save timestamp
        await prefs.setString(
          'notifications_last_scheduled_$userId',
          DateTime.now().toIso8601String(),
        );
        
        print('✅ Notifications scheduled successfully');
      } else {
        print('⚠️ User profile not found in cache');
      }
    } else {
      print('✅ ${pending.length} notifications already scheduled');
      
      // Still update the timestamp since notifications are active
      await prefs.setString(
        'notifications_last_scheduled_$userId',
        DateTime.now().toIso8601String(),
      );
    }
  } catch (e) {
    print('❌ Error scheduling notifications: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      navigatorKey: NotificationService.navigatorKey,
      
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}