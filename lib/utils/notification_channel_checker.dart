// lib/utils/notification_channel_checker.dart
// ⚠️ CHECK WHY NOTIFICATIONS FIRE BUT DON'T SHOW IN SYSTEM TRAY

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationChannelChecker {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Check all notification channels and permissions
  static Future<Map<String, dynamic>> checkChannels() async {
    print('');
    print('🔍 ========================================');
    print('🔍 CHECKING NOTIFICATION CHANNELS');
    print('🔍 ========================================');
    print('');

    final results = <String, dynamic>{};

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        // 1. Check if notifications are enabled
        try {
          final enabled = await androidImpl.areNotificationsEnabled();
          results['notifications_enabled'] = enabled;
          print('📱 Notifications Enabled: $enabled');
          
          if (enabled == false) {
            print('   ⚠️ PROBLEM: Notifications are DISABLED at app level!');
            print('   Fix: Settings → Apps → Health AI → Notifications → Enable');
          }
        } catch (e) {
          results['notifications_enabled'] = 'error: $e';
          print('❌ Could not check if notifications enabled: $e');
        }

        // 2. Get all notification channels
        try {
          final channels = await androidImpl.getNotificationChannels();
          results['channel_count'] = channels?.length ?? 0;
          results['channels'] = channels;

          print('');
          print('📋 NOTIFICATION CHANNELS: ${channels?.length ?? 0}');
          
          if (channels == null || channels.isEmpty) {
            print('   ⚠️ PROBLEM: NO CHANNELS CREATED!');
            print('   This is why notifications don\'t show in system tray.');
            print('   The notification fires, logs to DB, but has no channel to display in.');
          } else {
            for (var channel in channels) {
              print('');
              print('   Channel: ${channel.name}');
              print('   ID: ${channel.id}');
              print('   Description: ${channel.description}');
              print('   Importance: ${channel.importance.name}');
              print('   Show Badge: ${channel.showBadge}');
              print('   Sound: ${channel.playSound}');
              print('   Vibration: ${channel.enableVibration}');
              
              // Check if channel is problematic
              if (channel.importance == Importance.none || 
                  channel.importance == Importance.min) {
                print('   ⚠️ WARNING: Channel importance too low!');
                print('   Notifications won\'t show in system tray with this importance.');
              }
            }
          }
        } catch (e) {
          results['channels'] = 'error: $e';
          print('❌ Could not get channels: $e');
        }

        // 3. Check exact alarm permission
        try {
          final canSchedule = await androidImpl.canScheduleExactNotifications();
          results['can_schedule_exact'] = canSchedule;
          print('');
          print('⏰ Can Schedule Exact Alarms: $canSchedule');
          
          if (canSchedule == false) {
            print('   ⚠️ WARNING: Cannot schedule exact alarms');
            print('   Notifications may not fire at exact times');
          }
        } catch (e) {
          results['can_schedule_exact'] = 'error: $e';
          print('❌ Could not check exact alarm permission: $e');
        }

        // 4. Get active notifications
        try {
          final activeNotifications = await androidImpl.getActiveNotifications();
          results['active_count'] = activeNotifications.length;
          results['active_notifications'] = activeNotifications;

          print('');
          print('📬 ACTIVE NOTIFICATIONS IN SYSTEM TRAY: ${activeNotifications.length}');
          
          if (activeNotifications.isEmpty) {
            print('   ⚠️ No notifications currently showing in system tray');
            print('   Even though they fired and logged to DB');
          } else {
            for (var notif in activeNotifications) {
              print('   ID ${notif.id}: ${notif.title}');
            }
          }
        } catch (e) {
          results['active_notifications'] = 'error: $e';
          print('❌ Could not get active notifications: $e');
        }
      }
    }

    print('');
    print('🔍 ========================================');
    print('🔍 DIAGNOSIS');
    print('🔍 ========================================');
    print('');

    // Diagnose the problem
    if (results['notifications_enabled'] == false) {
      print('❌ MAIN PROBLEM: Notifications disabled at system level');
      print('💡 FIX: Go to Android Settings → Apps → Health AI → Enable notifications');
    } else if (results['channel_count'] == 0) {
      print('❌ MAIN PROBLEM: No notification channels created');
      print('💡 FIX: Channels must be created during app initialization');
      print('   The NotificationService.initialize() might not be creating channels properly');
    } else if (results['active_count'] == 0) {
      print('⚠️ PROBLEM: Notifications fire but don\'t stay in system tray');
      print('💡 POSSIBLE CAUSES:');
      print('   1. Channel importance too low (must be HIGH or MAX)');
      print('   2. Notification is auto-cancelled immediately');
      print('   3. DND (Do Not Disturb) is blocking notifications');
      print('   4. Notification doesn\'t have proper Android settings');
    } else {
      print('✅ Everything looks good!');
    }

    print('');

    return results;
  }

  /// Show dialog with channel status
  static Future<void> showChannelDialog(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Check channels
    final results = await checkChannels();

    // Close loading
    if (context.mounted) Navigator.pop(context);

    // Show results
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔍 Channel Status'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusRow(
                  'Notifications Enabled',
                  results['notifications_enabled'] == true,
                ),
                _buildStatusRow(
                  'Channels Created',
                  (results['channel_count'] ?? 0) > 0,
                ),
                _buildStatusRow(
                  'Active in System Tray',
                  (results['active_count'] ?? 0) > 0,
                ),
                const SizedBox(height: 16),
                Text(
                  'Channels: ${results['channel_count'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if ((results['channel_count'] ?? 0) == 0)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ NO CHANNELS! This is why notifications don\'t show in system tray.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Active Notifications: ${results['active_count'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            if (results['notifications_enabled'] == false)
              TextButton(
                onPressed: () async {
                  final androidImpl = _plugin.resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin>();
                  await androidImpl?.requestNotificationsPermission();
                },
                child: const Text('Request Permission'),
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

  static Widget _buildStatusRow(String label, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.cancel,
            color: isGood ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  /// Send a test notification with MAXIMUM visibility settings
  static Future<void> sendMaxVisibilityTest() async {
    print('');
    print('🧪 ========================================');
    print('🧪 SENDING MAX VISIBILITY TEST');
    print('🧪 ========================================');
    print('');

    try {
      // Initialize if needed
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // Request permissions
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImpl != null) {
        await androidImpl.requestNotificationsPermission();
      }

      // Create channel with MAXIMUM settings
      if (Platform.isAndroid && androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            'max_visibility_test',
            'Max Visibility Test',
            description: 'Test channel with maximum visibility',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
          ),
        );
        print('✅ Created max visibility test channel');
      }

      // Send notification with MAXIMUM settings
      await _plugin.show(
        99999,
        '🚨 MAX VISIBILITY TEST',
        'If you see this in system tray, channels work! If not, check app settings.',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'max_visibility_test',
            'Max Visibility Test',
            channelDescription: 'Test channel with maximum visibility',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            when: DateTime.now().millisecondsSinceEpoch,
            channelShowBadge: true,
            enableLights: true,
            ledColor: const Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            ticker: 'Test notification',
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            autoCancel: true,
            ongoing: false,
            onlyAlertOnce: false,
            styleInformation: const BigTextStyleInformation(
              'This is a test with maximum visibility. Check your notification panel NOW!',
              htmlFormatBigText: false,
              contentTitle: '🚨 MAX VISIBILITY TEST',
              htmlFormatContentTitle: false,
              summaryText: 'Test',
              htmlFormatSummaryText: false,
            ),
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      print('✅ Test notification sent with MAX settings');
      print('');
      print('💡 CHECK YOUR NOTIFICATION PANEL NOW!');
      print('   If you DON\'T see it, the problem is:');
      print('   1. App notifications are disabled in Android settings');
      print('   2. The notification channel is muted');
      print('   3. DND is blocking it');
      print('');

    } catch (e) {
      print('❌ Error sending test: $e');
    }
  }
}