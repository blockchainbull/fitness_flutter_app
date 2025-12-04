// lib/utils/notification_diagnostic.dart
// ⚠️ CRITICAL DIAGNOSTIC TOOL - Run this to find the problem

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;

class NotificationDiagnostic {
  static final NotificationService _notificationService = NotificationService();

  /// Run complete diagnostic and show results
  static Future<Map<String, dynamic>> runDiagnostic() async {
    print('');
    print('🔍 ========================================');
    print('🔍 NOTIFICATION DIAGNOSTIC STARTING');
    print('🔍 ========================================');
    print('');

    final results = <String, dynamic>{};

    // 1. Check current time
    final now = DateTime.now();
    results['current_time'] = '${now.hour}:${now.minute}:${now.second}';
    print('⏰ Current Time: ${results['current_time']}');
    print('');

    // 2. Check timezone
    final tzNow = tz.TZDateTime.now(tz.local);
    results['timezone'] = tz.local.name;
    results['tz_offset'] = tzNow.timeZoneOffset.inHours;
    print('🌍 Timezone: ${results['timezone']}');
    print('🌍 TZ Offset: ${results['tz_offset']} hours');
    print('');

    // 3. Check SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    results['user_id'] = prefs.getString('user_id');
    results['notifications_configured'] = prefs.getBool('notifications_configured') ?? false;
    results['last_notification_setup'] = prefs.getString('last_notification_setup');
    results['needs_reschedule'] = prefs.getBool('flutter.needs_notification_reschedule') ?? false;
    
    print('👤 User ID: ${results['user_id']}');
    print('⚙️ Notifications Configured: ${results['notifications_configured']}');
    print('📅 Last Setup: ${results['last_notification_setup']}');
    print('🔄 Needs Reschedule: ${results['needs_reschedule']}');
    print('');

    // 4. Check pending notifications
    final pending = await _notificationService.getPendingNotifications();
    results['pending_count'] = pending.length;
    results['pending_notifications'] = pending.map((n) => {
      'id': n.id,
      'title': n.title,
      'body': n.body,
    }).toList();

    print('📋 PENDING NOTIFICATIONS: ${results['pending_count']}');
    if (pending.isEmpty) {
      print('   ⚠️ NO NOTIFICATIONS SCHEDULED!');
      print('   This is the problem - nothing is scheduled.');
    } else {
      for (var notif in pending) {
        print('   ID ${notif.id}: ${notif.title}');
      }
    }
    print('');

    // 5. Check permissions
    final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
    final androidImpl = notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      try {
        final granted = await androidImpl.areNotificationsEnabled();
        results['notification_permission'] = granted;
        print('🔔 Notification Permission: ${granted ?? 'unknown'}');
      } catch (e) {
        results['notification_permission'] = 'error: $e';
        print('⚠️ Cannot check notification permission: $e');
      }
    }
    print('');

    // 6. Check user profile
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      try {
        final profile = jsonDecode(profileJson);
        results['daily_meals_count'] = profile['daily_meals_count'] ?? profile['dailyMealsCount'];
        results['has_profile'] = true;
        print('📊 User Profile Found: ✅');
        print('📊 Daily Meals: ${results['daily_meals_count']}');
      } catch (e) {
        results['has_profile'] = false;
        results['profile_error'] = e.toString();
        print('❌ Profile Parse Error: $e');
      }
    } else {
      results['has_profile'] = false;
      print('❌ No User Profile Found');
    }
    print('');

    // 7. CRITICAL: Check when notifications were last scheduled
    final lastScheduledKey = 'notifications_last_scheduled_${results['user_id']}';
    final lastScheduled = prefs.getString(lastScheduledKey);
    results['last_scheduled'] = lastScheduled;
    
    if (lastScheduled != null) {
      final lastScheduledDate = DateTime.parse(lastScheduled);
      final hoursSince = DateTime.now().difference(lastScheduledDate).inHours;
      results['hours_since_scheduled'] = hoursSince;
      print('⏱️ Last Scheduled: $lastScheduled ($hoursSince hours ago)');
      
      if (hoursSince > 24) {
        print('   ⚠️ WARNING: More than 24 hours since last schedule!');
        print('   Notifications may have expired or been cleared.');
      }
    } else {
      print('⚠️ No schedule timestamp found');
    }
    print('');

    // 8. DIAGNOSIS
    print('🔍 ========================================');
    print('🔍 DIAGNOSIS');
    print('🔍 ========================================');
    
    final issues = <String>[];
    final recommendations = <String>[];

    if (results['user_id'] == null) {
      issues.add('No user ID found');
      recommendations.add('User must be logged in');
    }

    if (results['pending_count'] == 0) {
      issues.add('NO NOTIFICATIONS SCHEDULED - This is the main problem!');
      recommendations.add('CRITICAL: Run scheduleAllNotifications() immediately');
    }

    if (results['has_profile'] == false) {
      issues.add('No user profile found');
      recommendations.add('Profile needed for meal scheduling');
    }

    if (results['notifications_configured'] == false) {
      issues.add('Notifications not configured');
      recommendations.add('Run notification setup');
    }

    if (results['needs_reschedule'] == true) {
      issues.add('Reschedule flag set (device was rebooted?)');
      recommendations.add('Reschedule all notifications');
    }

    final hoursSince = results['hours_since_scheduled'];
    if (hoursSince != null && hoursSince > 24) {
      issues.add('Last schedule was $hoursSince hours ago');
      recommendations.add('Notifications may have expired - reschedule needed');
    }

    if (issues.isEmpty) {
      print('✅ No obvious issues found');
      print('   Notifications should be working...');
      print('');
      print('🤔 Possible reasons notifications aren\'t showing:');
      print('   1. Notifications scheduled but times haven\'t arrived yet');
      print('   2. App settings blocking notifications');
      print('   3. Battery optimization killing scheduled alarms');
      print('   4. DND (Do Not Disturb) is enabled');
    } else {
      print('❌ ISSUES FOUND:');
      for (var i = 0; i < issues.length; i++) {
        print('   ${i + 1}. ${issues[i]}');
      }
      print('');
      print('💡 RECOMMENDATIONS:');
      for (var i = 0; i < recommendations.length; i++) {
        print('   ${i + 1}. ${recommendations[i]}');
      }
    }

    print('');
    print('🔍 ========================================');
    print('🔍 DIAGNOSTIC COMPLETE');
    print('🔍 ========================================');
    print('');

    results['issues'] = issues;
    results['recommendations'] = recommendations;

    return results;
  }

  /// Show diagnostic results in a dialog
  static Future<void> showDiagnosticDialog(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Run diagnostic
    final results = await runDiagnostic();

    // Close loading
    if (context.mounted) Navigator.pop(context);

    // Show results
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔍 Diagnostic Results'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Status', [
                  'Time: ${results['current_time']}',
                  'Timezone: ${results['timezone']}',
                  'User: ${results['user_id'] ?? 'Not logged in'}',
                ]),
                const SizedBox(height: 16),
                _buildSection('Scheduled', [
                  'Count: ${results['pending_count']}',
                  results['pending_count'] == 0
                      ? '⚠️ NO NOTIFICATIONS SCHEDULED!'
                      : '✅ Notifications are scheduled',
                ]),
                const SizedBox(height: 16),
                if ((results['issues'] as List).isNotEmpty) ...[
                  _buildSection('Issues', results['issues'] as List<String>),
                  const SizedBox(height: 16),
                ],
                if ((results['recommendations'] as List).isNotEmpty) ...[
                  _buildSection('Fix', results['recommendations'] as List<String>),
                ],
              ],
            ),
          ),
          actions: [
            if (results['pending_count'] == 0)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _fixNotifications(context, results);
                },
                child: const Text('🔧 FIX NOW'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  static Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '• $item',
            style: const TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  static Future<void> _fixNotifications(BuildContext context, Map<String, dynamic> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = results['user_id'];
      final profileJson = prefs.getString('user_profile');

      if (userId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No user ID - cannot schedule notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (profileJson == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No user profile - cannot schedule notifications'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Schedule notifications
      final userProfile = jsonDecode(profileJson);
      await _notificationService.initialize();
      await _notificationService.scheduleAllNotifications(userId, userProfile);

      // Save timestamp
      await prefs.setString(
        'notifications_last_scheduled_$userId',
        DateTime.now().toIso8601String(),
      );

      // Clear reschedule flag
      await prefs.setBool('flutter.needs_notification_reschedule', false);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notifications scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Run diagnostic again to confirm
        await Future.delayed(const Duration(seconds: 1));
        await showDiagnosticDialog(context);
      }
    } catch (e) {
      print('❌ Error fixing notifications: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ⭐ USAGE:
/*
// Add this button to your app (settings screen, profile, anywhere):

ElevatedButton(
  onPressed: () => NotificationDiagnostic.showDiagnosticDialog(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
  ),
  child: const Text('🔍 DIAGNOSE NOTIFICATIONS'),
)

// Or run in console:
final results = await NotificationDiagnostic.runDiagnostic();
*/