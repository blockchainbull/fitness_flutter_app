// lib/features/home/screens/dashboard_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/daily_metrics.dart';
import 'package:user_onboarding/features/home/widgets/activity_ring.dart';
import 'package:user_onboarding/features/home/widgets/progress_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_item.dart';
import 'package:user_onboarding/features/home/widgets/daily_calendar.dart';
import 'package:user_onboarding/features/chat/screens/chat_page.dart';

class DashboardHome extends StatefulWidget {
  final UserProfile userProfile;

  const DashboardHome({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  DateTime selectedDate = DateTime.now();
  late DailyMetrics todayMetrics;
  List<WorkoutSession> recentWorkouts = [];

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  void _loadTodayData() {
    // Mock data - replace with actual API calls
    todayMetrics = DailyMetrics(
      userId: widget.userProfile.id ?? '',
      date: selectedDate,
      steps: 7243,
      caloriesBurned: 423,
      activeMinutes: 32,
      caloriesConsumed: 1650,
      waterIntake: 1.8,
      sleepHours: 7.5,
      workoutCompleted: false,
    );

    recentWorkouts = [
      WorkoutSession(
        id: '1',
        userId: widget.userProfile.id ?? '',
        date: DateTime.now().subtract(const Duration(days: 1)),
        workoutType: 'Morning Run',
        durationMinutes: 32,
        caloriesBurned: 245,
        intensity: 'Medium',
      ),
      WorkoutSession(
        id: '2',
        userId: widget.userProfile.id ?? '',
        date: DateTime.now().subtract(const Duration(days: 2)),
        workoutType: 'Upper Body',
        durationMinutes: 45,
        caloriesBurned: 320,
        intensity: 'High',
      ),
      WorkoutSession(
        id: '3',
        userId: widget.userProfile.id ?? '',
        date: DateTime.now().subtract(const Duration(days: 3)),
        workoutType: 'Cycling',
        durationMinutes: 53,
        caloriesBurned: 410,
        intensity: 'Medium',
      ),
    ];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = widget.userProfile.name.split(' ').first;
    
    if (hour < 12) {
      return 'Good morning, $name';
    } else if (hour < 17) {
      return 'Good afternoon, $name';
    } else {
      return 'Good evening, $name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCalendar(),
                const SizedBox(height: 24),
                _buildTodayActivity(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildGoals(),
                const SizedBox(height: 24),
                _buildRecentWorkouts(),
                const SizedBox(height: 16),
                _buildMotivationCard(),
                const SizedBox(height: 24),
                _buildComingUp(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Text(
              "Let's crush your goals today!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {},
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DailyCalendar(
          selectedDate: selectedDate,
          onDateSelected: (date) {
            setState(() {
              selectedDate = date;
            });
            _loadTodayData();
          },
          userProfile: widget.userProfile,
        ),
      ),
    );
  }

  Widget _buildTodayActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Activity",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('MMM dd').format(selectedDate),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActivityRing(
                title: 'Steps',
                value: todayMetrics.steps.toString(),
                goal: '10,000',
                progress: todayMetrics.steps / 10000,
                color: Colors.green,
                icon: Icons.directions_walk,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActivityRing(
                title: 'Calories',
                value: todayMetrics.caloriesBurned.toInt().toString(),
                goal: '500',
                progress: todayMetrics.caloriesBurned / 500,
                color: Colors.orange,
                icon: Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ActivityRing(
                title: 'Active',
                value: '${todayMetrics.activeMinutes}m',
                goal: '60m',
                progress: todayMetrics.activeMinutes / 60,
                color: Colors.purple,
                icon: Icons.timer,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            title: 'Track Workout',
            icon: Icons.fitness_center,
            color: Colors.blue,
            onTap: () {
              // Navigate to workout tracking
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            title: 'Chat with AI',
            icon: Icons.psychology,
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(userProfile: widget.userProfile),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            title: 'Log Nutrition',
            icon: Icons.restaurant,
            color: Colors.green,
            onTap: () {
              // Navigate to nutrition logging
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGoals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Goals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProgressCard(
          title: 'Weekly Workouts',
          subtitle: '3 of 5 completed',
          progress: 0.6,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),
        ProgressCard(
          title: 'Weight Goal',
          subtitle: '7 kg to lose',
          progress: 0.7,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildRecentWorkouts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Workouts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('History'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentWorkouts.map((workout) => WorkoutItem(workout: workout)),
      ],
    );
  }

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            'The only bad workout is the one that didn\'t happen.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Motivation',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '3 day streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingUp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coming Up',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HIIT Training',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text(
                      '7:00 AM • 30 min • Coach Mike',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'Reschedule',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'Tomorrow',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Join Early', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}