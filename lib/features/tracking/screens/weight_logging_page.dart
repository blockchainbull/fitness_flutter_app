// lib/features/tracking/screens/weight_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class WeightLoggingPage extends StatelessWidget {
  final UserProfile userProfile;

  const WeightLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Weight tracking page - Coming soon!'),
      ),
    );
  }
}