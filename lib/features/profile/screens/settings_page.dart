// lib/features/profile/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/profile/screens/notification_settings_page.dart';
import 'package:user_onboarding/features/notifications/screens/notifications_screen.dart';

class SettingsPage extends StatefulWidget {
  final UserProfile userProfile;

  const SettingsPage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _dataSync = true;
  String _selectedTheme = 'System';
  String _selectedUnits = 'Metric';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSection(
            'Notifications',
            [
              _buildSwitchTile(
                'Push Notifications',
                'Receive workout reminders and updates',
                _pushNotifications,
                (value) => setState(() => _pushNotifications = value),
              ),
              _buildSwitchTile(
                'Email Notifications',
                'Get weekly progress reports via email',
                _emailNotifications,
                (value) => setState(() => _emailNotifications = value),
              ),
              _buildTile(
                'Notification Preferences',
                'Customize your reminder times',
                Icons.notifications_active,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationSettingsPage(
                        userId: widget.userProfile.id,
                      ),
                    ),
                  );
                },
              ),
              _buildTile(
                'View Notifications',
                'See all your notifications',
                Icons.notifications,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        userId: widget.userProfile.id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            'Data & Privacy',
            [
              _buildSwitchTile(
                'Data Synchronization',
                'Sync your data across devices',
                _dataSync,
                (value) => setState(() => _dataSync = value),
              ),
              _buildTile(
                'Export Data',
                'Download your health data',
                Icons.download,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data export coming soon!')),
                  );
                },
              ),
            ],
          ),
          _buildSection(
            'Preferences',
            [
              _buildDropdownTile(
                'Theme',
                _selectedTheme,
                ['Light', 'Dark', 'System'],
                (value) => setState(() => _selectedTheme = value!),
              ),
              _buildDropdownTile(
                'Units',
                _selectedUnits,
                ['Metric', 'Imperial'],
                (value) => setState(() => _selectedUnits = value!),
              ),
            ],
          ),
          _buildSection(
            'Support',
            [
              _buildTile(
                'Help Center',
                'Get help and support',
                Icons.help,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center coming soon!')),
                  );
                },
              ),
              _buildTile(
                'Send Feedback',
                'Share your thoughts with us',
                Icons.feedback,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback form coming soon!')),
                  );
                },
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}