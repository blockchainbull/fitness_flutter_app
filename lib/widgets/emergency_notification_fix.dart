// lib/widgets/emergency_notification_fix.dart
// ⚠️ ADD THIS BUTTON TO YOUR APP RIGHT NOW TO FIX NOTIFICATIONS

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:user_onboarding/utils/notification_diagnostic.dart';
import 'package:user_onboarding/utils/notification_channel_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EmergencyNotificationFix extends StatefulWidget {
  const EmergencyNotificationFix({super.key});

  @override
  State<EmergencyNotificationFix> createState() => _EmergencyNotificationFixState();
}

class _EmergencyNotificationFixState extends State<EmergencyNotificationFix> {
  bool _isFixing = false;
  String? _status;

  Future<void> _emergencyFix() async {
    setState(() {
      _isFixing = true;
      _status = 'Checking...';
    });

    try {
      final notificationService = NotificationService();
      final prefs = await SharedPreferences.getInstance();

      // Step 1: Check if we have user data
      setState(() => _status = 'Step 1/5: Checking user data...');
      await Future.delayed(const Duration(milliseconds: 500));

      final userId = prefs.getString('user_id');
      final profileJson = prefs.getString('user_profile');

      if (userId == null || profileJson == null) {
        setState(() {
          _isFixing = false;
          _status = '❌ Error: User not logged in or no profile found';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Please log in first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Initialize notification service
      setState(() => _status = 'Step 2/5: Initializing notifications...');
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.initialize();

      // Step 3: Cancel all existing notifications
      setState(() => _status = 'Step 3/5: Clearing old notifications...');
      await Future.delayed(const Duration(milliseconds: 500));
      await notificationService.cancelAllNotifications();

      // Step 4: Schedule new notifications
      setState(() => _status = 'Step 4/5: Scheduling notifications...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userProfile = jsonDecode(profileJson);
      await notificationService.scheduleAllNotifications(userId, userProfile);

      // Step 5: Verify
      setState(() => _status = 'Step 5/5: Verifying...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final pending = await notificationService.getPendingNotifications();
      
      // Save timestamp
      await prefs.setString(
        'notifications_last_scheduled_$userId',
        DateTime.now().toIso8601String(),
      );

      setState(() {
        _isFixing = false;
        _status = '✅ Fixed! Scheduled ${pending.length} notifications';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Success! ${pending.length} notifications scheduled'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Show what was scheduled
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Notifications Scheduled'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled ${pending.length} notifications:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...pending.map((notif) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• ID ${notif.id}: ${notif.title}'),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Next Steps:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('1. Wait for next scheduled time'),
                        Text('2. Check notification panel'),
                        Text('3. Notification should appear'),
                      ],
                    ),
                  ),
                ],
              ),
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
    } catch (e) {
      print('❌ Emergency fix error: $e');
      setState(() {
        _isFixing = false;
        _status = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notification Emergency Fix',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'If notifications are not appearing, use this tool to reschedule them.',
              style: TextStyle(fontSize: 14),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _status!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFixing ? null : _emergencyFix,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isFixing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.build),
                    label: Text(_isFixing ? 'Fixing...' : '🔧 FIX NOW'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isFixing
                      ? null
                      : () => NotificationDiagnostic.showDiagnosticDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Diagnose'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ⭐ NEW: Test system tray visibility
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFixing
                        ? null
                        : () async {
                            await NotificationChannelChecker.sendMaxVisibilityTest();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🚨 Test sent! Check your notification panel NOW!'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.notification_important),
                    label: const Text('Test System Tray'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isFixing
                      ? null
                      : () => NotificationChannelChecker.showChannelDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.layers),
                  label: const Text('Channels'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ⭐ USAGE - Add this to ANY screen in your app:
/*
// Option 1: Add to your settings/profile screen
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: ListView(
      children: [
        // ... your existing widgets ...
        
        const EmergencyNotificationFix(), // ⭐ ADD THIS
        
        // ... rest of your widgets ...
      ],
    ),
  );
}

// Option 2: Add as a floating action button
@override
Widget build(BuildContext context) {
  return Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: const EmergencyNotificationFix(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.build),
      label: const Text('Fix Notifications'),
      backgroundColor: Colors.red,
    ),
  );
}

// Option 3: Add as a bottom sheet
ElevatedButton(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: const EmergencyNotificationFix(),
      ),
    );
  },
  child: const Text('Fix Notifications'),
)
*/