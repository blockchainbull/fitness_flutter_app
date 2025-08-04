// lib/features/tracking/screens/supplements_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class SupplementsLoggingPage extends StatelessWidget {
  final UserProfile userProfile;

  const SupplementsLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplements Tracking'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Supplements tracking page - Coming soon!'),
      ),
    );
  }
}