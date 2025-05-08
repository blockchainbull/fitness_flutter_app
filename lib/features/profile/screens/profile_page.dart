import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/profile/widgets/stat_card.dart';
import 'package:user_onboarding/features/profile/widgets/goal_progress.dart';

class ProfilePage extends StatelessWidget {
  final UserProfile userProfile;
  
  const ProfilePage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Profile Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.indigo,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                userProfile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.indigo, Colors.indigo.shade800],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          userProfile.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.indigo.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.settings,
                  color: Colors.white),
                onPressed: () {
                  // TODO: Navigate to settings
                },
              ),
            ],
          ),
          
          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Email', userProfile.email, Icons.email),
                        const Divider(),
                        _buildInfoRow('Age', '${userProfile.age} years', Icons.cake),
                        const Divider(),
                        _buildInfoRow(
                          'Height', 
                          '${userProfile.height.toStringAsFixed(1)} cm', 
                          Icons.height
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Weight', 
                          '${userProfile.weight.toStringAsFixed(1)} kg', 
                          Icons.monitor_weight
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Activity Level', 
                          userProfile.activityLevel, 
                          Icons.fitness_center
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Goals Section
                  const Text(
                    'My Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Primary Goal Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getGoalIcon(userProfile.primaryGoal),
                                color: Colors.indigo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Primary Goal',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    userProfile.primaryGoal,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monitor_weight,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Weight Goal',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${userProfile.weightGoal} (${userProfile.targetWeight.toStringAsFixed(1)} kg)',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Goal Progress
                  const GoalProgress(
                    goals: [
                      {
                        'name': 'Weekly Workouts',
                        'current': 3,
                        'target': 5,
                        'unit': 'workouts',
                      },
                      {
                        'name': 'Protein Intake',
                        'current': 115,
                        'target': 140,
                        'unit': 'g per day',
                      },
                      {
                        'name': 'Daily Steps',
                        'current': 7500,
                        'target': 10000,
                        'unit': 'steps',
                      },
                      {
                        'name': 'Sleep Duration',
                        'current': 7,
                        'target': 8,
                        'unit': 'hours',
                      },
                      {
                        'name': 'Water Intake',
                        'current': 6,
                        'target': 8,
                        'unit': 'glasses',
                      },
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Section
                  const Text(
                    'Stats & Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Cards Row 1
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Sleep',
                          value: '${userProfile.sleepHours} hrs',
                          icon: Icons.nightlight_round,
                          color: Colors.indigo,
                          subtitle: 'Average',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Water',
                          value: '${userProfile.waterIntake.toStringAsFixed(1)} L',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                          subtitle: 'Target',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats Cards Row 2
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Workout',
                          value: '${userProfile.workoutDuration} min',
                          icon: Icons.timer,
                          color: Colors.orange,
                          subtitle: 'Duration',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Frequency',
                          value: '${userProfile.workoutFrequency}/week',
                          icon: Icons.calendar_today,
                          color: Colors.green,
                          subtitle: 'Target',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Preferences Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Preferences',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPreferenceItem(
                          'Workout Location',
                          userProfile.workoutLocation,
                          Icons.location_on,
                        ),
                        const Divider(),
                        _buildPreferenceItem(
                          'Fitness Level',
                          userProfile.fitnessLevel,
                          Icons.fitness_center,
                        ),
                        const Divider(),
                        _buildPreferencesList(
                          'Dietary Preferences',
                          userProfile.dietaryPreferences,
                          Icons.restaurant,
                        ),
                        if (userProfile.dietaryPreferences.isNotEmpty) const Divider(),
                        _buildPreferencesList(
                          'Preferred Workouts',
                          userProfile.preferredWorkouts,
                          Icons.directions_run,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Account Actions
                  Center(
                    child: Column(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // TODO: Navigate to edit profile
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement logout
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferenceItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.indigo,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferencesList(String label, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.indigo,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                backgroundColor: Colors.indigo.withOpacity(0.1),
                padding: const EdgeInsets.all(4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  IconData _getGoalIcon(String goal) {
    final lowerGoal = goal.toLowerCase();
    
    if (lowerGoal.contains('weight') && lowerGoal.contains('lose')) {
      return Icons.trending_down;
    } else if (lowerGoal.contains('muscle') || lowerGoal.contains('strength')) {
      return Icons.fitness_center;
    } else if (lowerGoal.contains('fitness') || lowerGoal.contains('endurance')) {
      return Icons.directions_run;
    } else if (lowerGoal.contains('health') || lowerGoal.contains('maintain')) {
      return Icons.favorite;
    } else if (lowerGoal.contains('stress') || lowerGoal.contains('mental')) {
      return Icons.self_improvement;
    } else {
      return Icons.flag;
    }
  }
}