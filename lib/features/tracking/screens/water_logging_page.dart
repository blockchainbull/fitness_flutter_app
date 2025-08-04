// lib/features/tracking/screens/water_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/water_tracker.dart';

class WaterLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const WaterLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<WaterLoggingPage> createState() => _WaterLoggingPageState();
}

class _WaterLoggingPageState extends State<WaterLoggingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Water history coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Water Intake',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Use the existing WaterTracker widget
            WaterTracker(userProfile: widget.userProfile),
            
            const SizedBox(height: 30),
            
            // Additional features you can add
            _buildWaterTips(),
            const SizedBox(height: 20),
            _buildWeeklyProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Hydration Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Drink water first thing in the morning'),
            const Text('• Set reminders throughout the day'),
            const Text('• Eat water-rich foods like fruits'),
            const Text('• Monitor urine color for hydration levels'),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Average: 2.1L per day'),
            const Text('Best day: 2.8L (Monday)'),
            const Text('Goal achieved: 5/7 days'),
          ],
        ),
      ),
    );
  }
}