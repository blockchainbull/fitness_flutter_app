// lib/utils/notification_debug_helper.dart
// ⭐ USE THIS TO DEBUG NOTIFICATIONS

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationDebugHelper {
  static final NotificationService _notificationService = NotificationService();

  /// Show debug screen with notification testing tools
  static void showDebugScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationDebugScreen(),
      ),
    );
  }
}

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  final NotificationService _notificationService = NotificationService();
  List<String> _logs = [];
  bool _isLoading = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshPendingCount();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_logs.length > 50) _logs.removeLast();
    });
    print(message);
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() {
      _pendingCount = pending.length;
    });
  }

  Future<void> _scheduleTestNotification() async {
    setState(() => _isLoading = true);
    _addLog('Scheduling test notification in 10 seconds...');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';

    final now = DateTime.now();
    final testTime = now.add(const Duration(seconds: 10));

    try {
      await _notificationService.initialize();
      
      await _notificationService.showImmediateNotification(
        id: 9999,
        title: '🧪 Test - 10 Seconds',
        body: 'This notification was scheduled 10 seconds ago',
        userId: userId,
        type: 'test',
      );

      _addLog('✅ Test notification scheduled for ${testTime.hour}:${testTime.minute}:${testTime.second}');
      await _refreshPendingCount();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Test notification will appear in 10 seconds'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _showImmediateNotification() async {
    setState(() => _isLoading = true);
    _addLog('Showing immediate notification...');

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';

    try {
      await _notificationService.initialize();
      
      await _notificationService.showImmediateNotification(
        id: 9998,
        title: '⚡ Immediate Test',
        body: 'This should appear instantly in your notification panel!',
        userId: userId,
        type: 'test',
      );

      _addLog('✅ Immediate notification sent');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Check your notification panel now!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _rescheduleAll() async {
    setState(() => _isLoading = true);
    _addLog('Rescheduling all notifications...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final profileJson = prefs.getString('user_profile');

      if (userId == null || profileJson == null) {
        _addLog('❌ User profile not found');
        return;
      }

      final userProfile = jsonDecode(profileJson);
      
      await _notificationService.initialize();
      await _notificationService.scheduleAllNotifications(userId, userProfile);
      
      await _refreshPendingCount();
      _addLog('✅ All notifications rescheduled');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Scheduled $_pendingCount notifications'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _cancelAll() async {
    setState(() => _isLoading = true);
    _addLog('Cancelling all notifications...');

    try {
      await _notificationService.cancelAllNotifications();
      await _refreshPendingCount();
      _addLog('✅ All notifications cancelled');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All notifications cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _viewScheduled() async {
    setState(() => _isLoading = true);
    _addLog('Fetching scheduled notifications...');

    try {
      final pending = await _notificationService.getPendingNotifications();
      
      _addLog('📋 Found ${pending.length} scheduled notifications:');
      for (var notif in pending) {
        _addLog('   ID ${notif.id}: ${notif.title}');
      }
      
      await _refreshPendingCount();
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debugger'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPendingCount,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scheduled Notifications:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildActionButton(
                  '⚡ Show Immediate Notification',
                  'Test system tray instantly',
                  Colors.green,
                  _showImmediateNotification,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  '🧪 Schedule Test (10 seconds)',
                  'Test scheduled notification',
                  Colors.blue,
                  _scheduleTestNotification,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  '📋 View Scheduled',
                  'See all pending notifications',
                  Colors.purple,
                  _viewScheduled,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  '🔄 Reschedule All',
                  'Recreate all daily notifications',
                  Colors.orange,
                  _rescheduleAll,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  '🔕 Cancel All',
                  'Clear all scheduled notifications',
                  Colors.red,
                  _cancelAll,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Logs Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debug Logs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet. Try testing notifications!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isError = log.contains('❌');
                        final isSuccess = log.contains('✅');
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: isError
                                  ? Colors.red
                                  : isSuccess
                                      ? Colors.green
                                      : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}