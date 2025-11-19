// lib/features/profile/screens/notification_settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/notification_preferences.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'dart:convert';

class NotificationSettingsPage extends StatefulWidget {
  final String userId;

  const NotificationSettingsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationPreferences _prefs;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString('notification_prefs_${widget.userId}');
      
      if (prefsJson != null) {
        _prefs = NotificationPreferences.fromJson(jsonDecode(prefsJson));
      } else {
        _prefs = NotificationPreferences();
      }
    } catch (e) {
      print('Error loading notification preferences: $e');
      _prefs = NotificationPreferences();
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_prefs_${widget.userId}',
        jsonEncode(_prefs.toJson()),
      );
      
      // Reschedule notifications with new preferences
      if (_prefs.enabled) {
        await _rescheduleNotifications();
      } else {
        await NotificationService().cancelAllNotifications();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification settings saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving notification preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isSaving = false);
  }

  Future<void> _rescheduleNotifications() async {
    final notificationService = NotificationService();
    await notificationService.cancelAllNotifications();
    
    // Schedule only enabled notification types
    if (_prefs.mealReminders) {
      // Schedule meal notifications based on custom times
    }
    if (_prefs.exerciseReminders) {
      await notificationService.scheduleExerciseNotification(widget.userId);
    }
    if (_prefs.waterReminders) {
      await notificationService.scheduleWaterNotifications(widget.userId);
    }
    if (_prefs.sleepReminders) {
      await notificationService.scheduleSleepNotification(widget.userId, {});
    }
    if (_prefs.supplementReminders) {
      await notificationService.scheduleSupplementNotification(widget.userId);
    }
    if (_prefs.weightReminders) {
      await notificationService.scheduleWeightNotification(widget.userId);
    }
  }

  Future<void> _sendTestNotification() async {
    final notificationService = NotificationService();
    
    // Get userId from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    
    if (userId != null) {
      await notificationService.showImmediateNotification(
        id: 999,
        title: '🎉 Test Notification',
        body: 'Your notifications are working perfectly!',
        userId: userId,  
        type: 'test',  
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent and logged to database!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _savePreferences,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master Toggle
          _buildSection(
            'Enable Notifications',
            [
              SwitchListTile(
                title: const Text('All Notifications'),
                subtitle: Text(
                  _prefs.enabled 
                      ? 'Notifications are enabled' 
                      : 'Notifications are disabled',
                ),
                value: _prefs.enabled,
                onChanged: (value) {
                  setState(() => _prefs.enabled = value);
                },
                activeColor: Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notification Types
          _buildSection(
            'Notification Types',
            [
              _buildSwitchTile(
                '🍽️ Meal Reminders',
                'Get reminded to log your meals',
                _prefs.mealReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.mealReminders = value),
              ),
              _buildSwitchTile(
                '💪 Exercise Reminders',
                'Stay motivated to workout',
                _prefs.exerciseReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.exerciseReminders = value),
              ),
              _buildSwitchTile(
                '💧 Water Reminders',
                'Stay hydrated throughout the day',
                _prefs.waterReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.waterReminders = value),
              ),
              _buildSwitchTile(
                '😴 Sleep Reminders',
                'Track your sleep quality',
                _prefs.sleepReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.sleepReminders = value),
              ),
              _buildSwitchTile(
                '💊 Supplement Reminders',
                'Remember to take supplements',
                _prefs.supplementReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.supplementReminders = value),
              ),
              _buildSwitchTile(
                '⚖️ Weight Check Reminders',
                'Weekly weigh-in reminder',
                _prefs.weightReminders,
                _prefs.enabled,
                (value) => setState(() => _prefs.weightReminders = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Meal Times
          if (_prefs.enabled && _prefs.mealReminders)
            _buildSection(
              'Meal Reminder Times',
              [
                _buildTimePicker(
                  'Breakfast Time',
                  TimeOfDay(hour: _prefs.breakfastHour, minute: _prefs.breakfastMinute),
                  (time) {
                    setState(() {
                      _prefs.breakfastHour = time.hour;
                      _prefs.breakfastMinute = time.minute;
                    });
                  },
                ),
                _buildTimePicker(
                  'Lunch Time',
                  TimeOfDay(hour: _prefs.lunchHour, minute: _prefs.lunchMinute),
                  (time) {
                    setState(() {
                      _prefs.lunchHour = time.hour;
                      _prefs.lunchMinute = time.minute;
                    });
                  },
                ),
                _buildTimePicker(
                  'Dinner Time',
                  TimeOfDay(hour: _prefs.dinnerHour, minute: _prefs.dinnerMinute),
                  (time) {
                    setState(() {
                      _prefs.dinnerHour = time.hour;
                      _prefs.dinnerMinute = time.minute;
                    });
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Custom Exercise Time
          if (_prefs.enabled && _prefs.exerciseReminders)
            _buildSection(
              'Exercise Reminder Time',
              [
                _buildTimePicker(
                  'Exercise Time',
                  TimeOfDay(hour: _prefs.exerciseHour, minute: _prefs.exerciseMinute),
                  (time) {
                    setState(() {
                      _prefs.exerciseHour = time.hour;
                      _prefs.exerciseMinute = time.minute;
                    });
                  },
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Water Reminder Frequency
          if (_prefs.enabled && _prefs.waterReminders)
            _buildSection(
              'Water Reminder Frequency',
              [
                ListTile(
                  title: const Text('Remind me every'),
                  subtitle: Text('${_prefs.waterReminderFrequency} hours'),
                  trailing: DropdownButton<int>(
                    value: _prefs.waterReminderFrequency,
                    items: [1, 2, 3, 4, 6].map((hours) {
                      return DropdownMenuItem(
                        value: hours,
                        child: Text('$hours hour${hours > 1 ? 's' : ''}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _prefs.waterReminderFrequency = value);
                      }
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Test Notification Button
          ElevatedButton.icon(
            onPressed: _sendTestNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Send Test Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'About Notifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Notifications help you stay on track with your health goals. '
                  'You can customize when you receive reminders for each activity.',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    bool enabled,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Colors.blue,
    );
  }

  Widget _buildTimePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return ListTile(
      title: Text(label),
      trailing: InkWell(
        onTap: () async {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (pickedTime != null) {
            onTimeSelected(pickedTime);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Text(
            time.format(context),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}