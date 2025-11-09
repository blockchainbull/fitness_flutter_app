// lib/features/notifications/screens/notification_test_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:user_onboarding/data/services/permission_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final PermissionService _permissionService = PermissionService();
  
  bool _notificationPermission = false;
  List<String> _pendingNotifications = [];
  bool _isLoading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadPendingNotifications();
  }

  Future<void> _checkPermissions() async {
    final granted = await _permissionService.isNotificationGranted();
    setState(() {
      _notificationPermission = granted;
    });
  }

  Future<void> _loadPendingNotifications() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _notificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = pending.map((n) => 
          'ID: ${n.id}, Title: ${n.title}, Time: ${n.body}'
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading pending notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermissions();
    setState(() {
      _notificationPermission = granted;
      _status = granted 
          ? '✅ Permission granted!' 
          : '❌ Permission denied';
    });
  }

  Future<void> _showTestNotification() async {
    await _notificationService.showTestNotification();
    setState(() {
      _status = '✅ Test notification sent!';
    });
  }

  Future<void> _scheduleAllNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Scheduling notifications...';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId == null) {
        setState(() {
          _status = '❌ User ID not found';
          _isLoading = false;
        });
        return;
      }

      // Get user profile from preferences
      final mealsCount = prefs.getInt('daily_meals_count') ?? 3;
      final wakeTime = prefs.getString('usual_wake_time') ?? '07:00';
      
      final userProfile = {
        'daily_meals_count': mealsCount,
        'usual_wake_time': wakeTime,
      };

      await _notificationService.scheduleAllNotifications(userId, userProfile);
      await _loadPendingNotifications();
      
      setState(() {
        _status = '✅ All notifications scheduled!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    await _loadPendingNotifications();
    setState(() {
      _status = '🔕 All notifications cancelled';
    });
  }

  Future<void> _testStepMilestone(int percentage) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'test_user';
    
    if (percentage == 50) {
      await _notificationService.showMilestoneNotification(
        id: NotificationService.stepMilestone50Id,
        title: '🎯 Halfway There! (TEST)',
        body: 'You\'ve reached 50% of your step goal! Keep going!',
        userId: userId,
        milestoneType: 'steps_50',
      );
    } else {
      await _notificationService.showMilestoneNotification(
        id: NotificationService.stepMilestone100Id,
        title: '🎉 Goal Achieved! (TEST)',
        body: 'Congratulations! You\'ve reached your daily step goal!',
        userId: userId,
        milestoneType: 'steps_100',
      );
    }
    
    setState(() {
      _status = '✅ Test ${percentage}% milestone notification sent!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Permission Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Permission Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _notificationPermission 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: _notificationPermission 
                                    ? Colors.green 
                                    : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _notificationPermission 
                                    ? 'Notifications Enabled' 
                                    : 'Notifications Disabled',
                              ),
                            ],
                          ),
                          if (!_notificationPermission) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _requestPermission,
                              child: const Text('Request Permission'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showTestNotification,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Send Test Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _scheduleAllNotifications,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Schedule All Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _cancelAllNotifications,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel All Notifications'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Test Step Milestones
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Step Milestones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _testStepMilestone(50),
                                  child: const Text('50% Milestone'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _testStepMilestone(100),
                                  child: const Text('100% Milestone'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Pending Notifications
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pending Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadPendingNotifications,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_pendingNotifications.isEmpty)
                            const Text(
                              'No pending notifications',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...List.generate(
                              _pendingNotifications.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _pendingNotifications[index],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status
                  if (_status.isNotEmpty)
                    Card(
                      color: _status.contains('❌') 
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _status,
                          style: TextStyle(
                            color: _status.contains('❌') 
                                ? Colors.red 
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}