// lib/features/home/widgets/activity_tracker_section.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/compact_water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_step_tracker.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';

class ActivityTrackerSection extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const ActivityTrackerSection({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full activity logging menu
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActivityLoggingMenu(
                          userProfile: userProfile,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          CompactWaterTracker(
            userProfile: userProfile,
            onUpdate: onUpdate,
          ),
          
          CompactStepTracker(
            userProfile: userProfile,
            onUpdate: onUpdate,
          ),
        ],
      ),
    );
  }
}