// lib/features/home/screens/dashboard_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/daily_metrics.dart';
import 'package:user_onboarding/features/home/widgets/activity_ring.dart';
import 'package:user_onboarding/features/home/widgets/progress_card.dart';
import 'package:user_onboarding/features/home/widgets/workout_item.dart';
import 'package:user_onboarding/features/home/widgets/daily_calendar.dart';
import 'package:user_onboarding/features/home/widgets/activity_drawer.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/features/reports/screens/today_report_screen.dart';


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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
  
  String greeting;
  
  if (hour >= 7 && hour < 12) {
    // 7AM to 12PM
    greeting = 'Good morning';
  } else if (hour >= 12 && hour < 15) {
    // 12PM to 3PM
    greeting = 'Good afternoon';
  } else if (hour >= 18 && hour < 20) {
    // 6PM to 8PM
    greeting = 'Good evening';
  } else if (hour >= 23 || hour < 5) {
    // 11PM to 5AM
    greeting = 'Good night';
  } else {
    // Handle the gaps: 3PM-6PM (15-17), 8PM-11PM (20-22), 5AM-7AM (5-6)
    if (hour >= 15 && hour < 18) {
      // 3PM to 6PM - Late afternoon
      greeting = 'Good afternoon';
    } else if (hour >= 20 && hour < 23) {
      // 8PM to 11PM - Late evening
      greeting = 'Good evening';
    } else {
      // 5AM to 7AM - Early morning
      greeting = 'Good morning';
    }
  }
  
  return '$greeting, $name';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: ActivityDrawer(userProfile: widget.userProfile),
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
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildSmartRecommendations(),
                const SizedBox(height: 24),
                _buildTodayActivity(),
                const SizedBox(height: 24),
                _buildGoals(),
                const SizedBox(height: 24),
                _buildRecentWorkouts(),
                const SizedBox(height: 16),
                _buildMotivationCard(),
                const SizedBox(height: 24),
                _buildComingUp(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // MOVED: Menu button to the left
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, size: 28, color: Colors.blue),
            onPressed: () {
              print('Menu button pressed');
              _scaffoldKey.currentState?.openDrawer();
            },
            tooltip: 'Open activity menu',
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Greeting text in the middle
        Expanded(
          child: Column(
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
        ),
        
        // Notifications on the right
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
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

  // ... rest of your methods stay exactly the same
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLoggingMenu(userProfile: widget.userProfile),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Log Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TodayReportScreen(
                        userProfile: widget.userProfile,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('View Reports'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildSmartRecommendations() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getSmartRecommendations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final recommendations = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Today\'s Focus',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Dynamic recommendations based on user's framework
                ...recommendations['recommendations'].map<Widget>((rec) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(rec['icon'], color: rec['color'], size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(rec['text'])),
                      ],
                    ),
                  ),
                ).toList(),
                
                const SizedBox(height: 12),
                
                // Quick action based on goal
                ElevatedButton.icon(
                  onPressed: () => _handleQuickAction(recommendations['quick_action']),
                  icon: Icon(recommendations['quick_action']['icon']),
                  label: Text(recommendations['quick_action']['text']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getGoalColor(),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getSmartRecommendations() async {
    final weightGoal = widget.userProfile.weightGoal;
    final currentHour = DateTime.now().hour;
    final userWeight = widget.userProfile.weight;
    final targetWeight = widget.userProfile.targetWeight;
    
    // Get BMR and TDEE from formData
    final bmr = widget.userProfile.formData['bmr']?.toDouble() ?? 0.0;
    final tdee = widget.userProfile.formData['tdee']?.toDouble() ?? 0.0;
    
    // Calculate approximate TDEE if not available
    double estimatedTDEE = tdee > 0 ? tdee : 1800; // Use stored TDEE or fallback
    
    if (bmr > 0 && tdee <= 0) {
      // Use BMR to calculate TDEE if BMR exists but TDEE doesn't
      double activityMultiplier = 1.4; // Sedentary default
      
      switch (widget.userProfile.activityLevel) {
        case 'Lightly active':
          activityMultiplier = 1.6;
          break;
        case 'Moderately active':
          activityMultiplier = 1.8;
          break;
        case 'Very active':
          activityMultiplier = 2.0;
          break;
        case 'Extra active':
          activityMultiplier = 2.2;
          break;
      }
      
      estimatedTDEE = bmr * activityMultiplier;
    }
    
    // Framework-driven recommendations that don't expose the framework
    switch (weightGoal) {
      case 'lose_weight':
        return {
          'recommendations': [
            {
              'icon': Icons.local_fire_department,
              'color': Colors.red,
              'text': 'Focus on protein at each meal (${(userWeight * 1.6).round()}g target today)'
            },
            {
              'icon': Icons.directions_walk,
              'color': Colors.blue,
              'text': 'Aim for ${(10000 + (userWeight - targetWeight) * 1000).round()} steps today'
            },
            {
              'icon': Icons.water_drop,
              'color': Colors.cyan,
              'text': 'Drink 10 glasses of water (helps with satiety)'
            },
          ],
          'quick_action': {
            'text': currentHour < 12 ? 'Log Breakfast' : (currentHour < 17 ? 'Log Lunch' : 'Log Dinner'),
            'icon': Icons.restaurant,
            'action': 'log_meal'
          }
        };
        
      case 'gain_weight':
        return {
          'recommendations': [
            {
              'icon': Icons.fitness_center,
              'color': Colors.green,
              'text': 'Strength training focus: compound movements today'
            },
            {
              'icon': Icons.restaurant,
              'color': Colors.orange,
              'text': 'Eat every 3 hours (${((estimatedTDEE + 300) / 5).round()} cal per meal)'
            },
            {
              'icon': Icons.local_drink,
              'color': Colors.brown,
              'text': 'Consider a protein shake post-workout'
            },
          ],
          'quick_action': {
            'text': 'Log Workout',
            'icon': Icons.fitness_center,
            'action': 'log_exercise'
          }
        };
        
      case 'maintain_weight':
      default:
        return {
          'recommendations': [
            {
              'icon': Icons.balance,
              'color': Colors.blue,
              'text': 'Maintain your ${estimatedTDEE.round()} calorie balance'
            },
            {
              'icon': Icons.self_improvement,
              'color': Colors.purple,
              'text': 'Mix of cardio and strength training this week'
            },
            {
              'icon': Icons.psychology,
              'color': Colors.teal,
              'text': 'Listen to your hunger and fullness cues'
            },
          ],
          'quick_action': {
            'text': 'Check Progress',
            'icon': Icons.analytics,
            'action': 'view_progress'
          }
        };
    }
  }

  Color _getGoalColor() {
    switch (widget.userProfile.weightGoal) {
      case 'lose_weight':
        return Colors.red[500]!;
      case 'gain_weight':
        return Colors.green[500]!;
      default:
        return Colors.blue[500]!;
    }
  }

  void _handleQuickAction(Map<String, dynamic> action) {
    switch (action['action']) {
      case 'log_meal':
        // Navigate to meal logging
        break;
      case 'log_exercise':
        // Navigate to exercise logging
        break;
      case 'view_progress':
        // Navigate to progress/reports
        break;
    }
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Goals page coming soon!')),
                );
              },
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Workout history coming soon!')),
                );
              },
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
                    const SizedBox(height: 8),
                    Text(
                      'Scheduled for tomorrow',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Tomorrow',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}