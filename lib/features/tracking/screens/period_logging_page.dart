// lib/features/tracking/screens/period_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class PeriodLoggingPage extends StatelessWidget {
  final UserProfile userProfile;

  const PeriodLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Period Tracking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Period tracking page - Coming soon!'),
      ),
    );
  }
}