// lib/utils/test_notification_scheduler.dart
// ⚡ IMMEDIATE TEST - Schedule notifications for next few minutes

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TestNotificationScheduler {
  static final NotificationService _notificationService = NotificationService();

  /// Schedule test notifications for the NEXT FEW MINUTES
  /// This lets you verify notifications work without waiting until tomorrow
  static Future<void> scheduleImmediateTests(BuildContext context) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';

    print('');
    print('🧪 ========================================');
    print('🧪 SCHEDULING IMMEDIATE TEST NOTIFICATIONS');
    print('🧪 ========================================');
    print('🧪 Current time: ${now.hour}:${now.minute}:${now.second}');
    print('');

    await _notificationService.initialize();

    // Cancel any existing test notifications
    for (int i = 9990; i < 10000; i++) {
      await _notificationService.cancelNotification(i);
    }

    // Schedule 5 test notifications over the next 5 minutes
    final List<Map<String, dynamic>> testSchedule = [
      {
        'delay': 30, // 30 seconds
        'title': '🧪 Test 1: Breakfast',
        'body': 'Testing breakfast notification (30 sec)',
        'id': 9990,
      },
      {
        'delay': 60, // 1 minute
        'title': '🧪 Test 2: Lunch',
        'body': 'Testing lunch notification (1 min)',
        'id': 9991,
      },
      {
        'delay': 90, // 1.5 minutes
        'title': '🧪 Test 3: Water',
        'body': 'Testing water reminder (1.5 min)',
        'id': 9992,
      },
      {
        'delay': 120, // 2 minutes
        'title': '🧪 Test 4: Exercise',
        'body': 'Testing exercise reminder (2 min)',
        'id': 9993,
      },
      {
        'delay': 180, // 3 minutes
        'title': '🧪 Test 5: Dinner',
        'body': 'Testing dinner notification (3 min)',
        'id': 9994,
      },
    ];

    for (var test in testSchedule) {
      final scheduledTime = now.add(Duration(seconds: test['delay']));
      
      await _scheduleExactNotification(
        id: test['id'],
        title: test['title'],
        body: test['body'],
        scheduledDateTime: scheduledTime,
        userId: userId,
      );

      print('⏰ Scheduled: ${test['title']}');
      print('   Will fire at: ${scheduledTime.hour}:${scheduledTime.minute}:${scheduledTime.second}');
      print('');
    }

    print('✅ Test notifications scheduled!');
    print('📱 Check your notification panel over the next 3 minutes');
    print('');

    // Show dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🧪 Test Scheduled'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test notifications scheduled for:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...testSchedule.map((test) {
                final time = now.add(Duration(seconds: test['delay']));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          test['title'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Keep the app in background and watch your notification panel!',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Schedule a notification for an exact DateTime
  static Future<void> _scheduleExactNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    required String userId,
  }) async {
    try {
      final scheduledTZDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

      await _notificationService.showImmediateNotification(
        id: id,
        title: title,
        body: body,
        userId: userId,
        type: 'test',
      );

      print('✅ Scheduled notification ID $id for ${scheduledDateTime.toString()}');
    } catch (e) {
      print('❌ Error scheduling notification $id: $e');
    }
  }

  /// Show immediate notification to test system tray
  static Future<void> showInstantTest(BuildContext context) async {
    await _notificationService.initialize();
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';

    await _notificationService.showImmediateNotification(
      id: 9999,
      title: '⚡ INSTANT TEST',
      body: 'If you see this, notifications are working! Check your notification panel NOW.',
      userId: userId,
      type: 'test',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Instant notification sent! Check notification panel now.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Verify notifications are scheduled
  static Future<void> verifyScheduled(BuildContext context) async {
    final pending = await _notificationService.getPendingNotifications();
    
    print('');
    print('📋 ========================================');
    print('📋 CURRENTLY SCHEDULED NOTIFICATIONS: ${pending.length}');
    print('📋 ========================================');
    
    if (pending.isEmpty) {
      print('⚠️ NO NOTIFICATIONS SCHEDULED');
      print('   This might mean:');
      print('   1. Permissions not granted');
      print('   2. Notifications were cancelled');
      print('   3. Schedule failed');
    } else {
      for (var notif in pending) {
        print('   ID ${notif.id}: ${notif.title}');
      }
    }
    print('');

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scheduled: ${pending.length}'),
          content: pending.isEmpty
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 48),
                    SizedBox(height: 16),
                    Text('No notifications scheduled.'),
                    SizedBox(height: 8),
                    Text(
                      'Try scheduling test notifications first.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: pending.map((notif) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ID ${notif.id}: ${notif.title}'),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

// ⭐ USAGE EXAMPLE:
/*
// Add these buttons to your settings/debug screen:

1. INSTANT TEST (Immediate notification):
   ElevatedButton(
     onPressed: () => TestNotificationScheduler.showInstantTest(context),
     child: const Text('⚡ Instant Test'),
   )

2. SCHEDULE TESTS (Next 3 minutes):
   ElevatedButton(
     onPressed: () => TestNotificationScheduler.scheduleImmediateTests(context),
     child: const Text('🧪 Schedule Test Notifications'),
   )

3. VERIFY SCHEDULED:
   ElevatedButton(
     onPressed: () => TestNotificationScheduler.verifyScheduled(context),
     child: const Text('📋 Check Scheduled'),
   )
*/