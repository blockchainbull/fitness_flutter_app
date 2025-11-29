// lib/main.dart - COMPLETE FILE WITH UNIVERSAL TIMEZONE

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/features/splash/screens/splash_screen.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:user_onboarding/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ UNIVERSAL TIMEZONE INITIALIZATION
  // This works for ALL timezones automatically based on device settings
  tz.initializeTimeZones();
  
  // Get device's timezone name
  final String timeZoneName = DateTime.now().timeZoneName;
  
  // Set timezone based on device or fallback to UTC
  try {
    // Try to set from device timezone
    if (timeZoneName.isNotEmpty && timeZoneName != 'UTC') {
      // First try direct timezone name
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        print('🌍 Timezone set to: $timeZoneName (from device)');
      } catch (e) {
        // If direct name fails, try to find closest match
        final location = _findClosestTimezone(timeZoneName);
        tz.setLocalLocation(location);
        print('🌍 Timezone set to: ${location.name} (closest match to $timeZoneName)');
      }
    } else {
      // Fallback: Use system default
      tz.setLocalLocation(tz.local);
      print('🌍 Timezone set to: ${tz.local.name} (system default)');
    }
  } catch (e) {
    // Final fallback: UTC
    tz.setLocalLocation(tz.getLocation('UTC'));
    print('⚠️ Timezone detection failed, using UTC. Error: $e');
  }
  
  // Initialize notification service
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
      debug: true,
    );
    print('[Main] ✅ Supabase initialized successfully');
  } else {
    print('[Main] ⚠️ WARNING: Supabase credentials missing in .env file');
  }

  // Check and reschedule notifications if needed
  await _initializeNotifications();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider()..initUser(),
      child: const MyApp(),
    ),
  );
}

/// Find closest timezone match
tz.Location _findClosestTimezone(String timeZoneName) {
  // Common timezone mappings
  final Map<String, String> timezoneMap = {
    'PST': 'America/Los_Angeles',
    'PDT': 'America/Los_Angeles',
    'MST': 'America/Denver',
    'MDT': 'America/Denver',
    'CST': 'America/Chicago',
    'CDT': 'America/Chicago',
    'EST': 'America/New_York',
    'EDT': 'America/New_York',
    'GMT': 'Europe/London',
    'BST': 'Europe/London',
    'CET': 'Europe/Paris',
    'CEST': 'Europe/Paris',
    'IST': 'Asia/Kolkata',
    'PKT': 'Asia/Karachi',
    'JST': 'Asia/Tokyo',
    'AEST': 'Australia/Sydney',
    'AEDT': 'Australia/Sydney',
  };
  
  // Try mapped timezone
  final mappedZone = timezoneMap[timeZoneName];
  if (mappedZone != null) {
    try {
      return tz.getLocation(mappedZone);
    } catch (e) {
      // Continue to fallback
    }
  }
  
  // Fallback to local
  return tz.local;
}

/// Initialize and schedule notifications
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

/// Check if notifications need rescheduling
Future<void> _checkAndRescheduleIfNeeded(String userId, SharedPreferences prefs) async {
  final lastScheduled = prefs.getString('notifications_last_scheduled_$userId');
  
  if (lastScheduled == null) {
    print('📱 First time setup - scheduling notifications...');
    await _scheduleNotifications(userId, prefs);
    return;
  }
  
  final lastDate = DateTime.parse(lastScheduled);
  final now = DateTime.now();
  
  if (now.difference(lastDate).inHours > 24) {
    print('📱 Notifications expired (${now.difference(lastDate).inHours}h ago), re-scheduling...');
    await _scheduleNotifications(userId, prefs);
  } else {
    print('✅ Notifications still active (scheduled ${now.difference(lastDate).inHours}h ago)');
  }
}

/// Schedule notifications and save timestamp
Future<void> _scheduleNotifications(String userId, SharedPreferences prefs) async {
  try {
    final notificationService = NotificationService();
    final pending = await notificationService.getPendingNotifications();
    
    if (pending.isEmpty) {
      final profileJson = prefs.getString('user_profile');
      
      if (profileJson != null) {
        final userProfile = jsonDecode(profileJson);
        await notificationService.scheduleAllNotifications(userId, userProfile);
        
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