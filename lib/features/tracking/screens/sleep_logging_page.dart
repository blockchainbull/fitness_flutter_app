// lib/features/tracking/screens/sleep_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/sleep_quality_tracker.dart';

class SleepLoggingPage extends StatelessWidget {
  final UserProfile userProfile;

  const SleepLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bedtime),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sleep timer coming soon!')),
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
              'Sleep Quality',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Use existing SleepQualityTracker widget
            const SleepQualityTracker(
              sleepHours: 7.5,
              sleepQuality: 0.85,
              deepSleepPercentage: 0.22,
              remSleepPercentage: 0.18,
            ),
            
            const SizedBox(height: 30),
            _buildSleepInsights(),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepInsights() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInsightRow('Bedtime consistency', '85%', Colors.green),
            _buildInsightRow('Sleep efficiency', '92%', Colors.blue),
            _buildInsightRow('Weekly average', '7.3h', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}