// lib/features/home/screens/dashboard_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/activity_drawer.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/features/reports/screens/today_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'dart:async';
import 'package:user_onboarding/utils/profile_update_notifier.dart';
import 'package:user_onboarding/data/services/metrics_service.dart';
import 'package:user_onboarding/data/services/insights_service.dart';
import 'package:user_onboarding/data/services/schedule_service.dart';
import 'package:user_onboarding/features/home/widgets/dashboard_weight_goal_card.dart';
import 'package:user_onboarding/features/home/widgets/daily_meal_card.dart';

class DashboardHome extends StatefulWidget {
  final UserProfile userProfile;
  final Function(int)? onTabChange;

  const DashboardHome({
    Key? key,
    required this.userProfile,
    this.onTabChange,
  }) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Core state
  DateTime selectedDate = DateTime.now();
  late UserProfile _currentUserProfile;
  late StreamSubscription<UserProfile> _profileSubscription;
  final MetricsService _metricsService = MetricsService();
  final InsightsService _insightsService = InsightsService();
  final ScheduleService _scheduleService = ScheduleService();
  bool _isLoadingMetrics = false;
  
  // Feature flags - turn these on as we implement each section
  final bool _quickActionsEnabled = true;
  final bool _todayProgressEnabled = true;
  final bool _smartInsightsEnabled = true;
  final bool _upcomingEventsEnabled = true;
  final bool _goalProgressEnabled = true;
  
  // Data placeholders
  Map<String, dynamic> todayProgress = {
    'steps': 0,
    'stepsGoal': 10000,
    'water': 0,
    'waterGoal': 8,
    'activeMinutes': 0,
    'activeGoal': 30,
    'calories': 0,
    'caloriesGoal': 2000,
  };
  
  List<String> smartInsights = [];
  List<Map<String, dynamic>> upcomingEvents = [];

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.userProfile;
    WidgetsBinding.instance.addObserver(this);
    _setupListeners();
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _profileSubscription.cancel();
    super.dispose();
  }

  void _setupListeners() {
    _profileSubscription = ProfileUpdateNotifier().profileUpdates.listen((profile) {
      if (mounted) {
        setState(() {
          _currentUserProfile = profile;
        });
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      if (_todayProgressEnabled) _loadTodayProgress(),
      if (_smartInsightsEnabled) _generateSmartInsights(),
    ]);
    
    if (_upcomingEventsEnabled) {
      _loadUpcomingEvents();
    }
  }

  Future<void> _loadTodayProgress() async {
    if (!_todayProgressEnabled) return;
    
    setState(() => _isLoadingMetrics = true);
    
    try {
      final metrics = await _metricsService.getTodayMetrics(_currentUserProfile.id!);
      
      setState(() {
        todayProgress = {
          'steps': metrics['steps'],
          'stepsGoal': _currentUserProfile.dailyStepGoal ?? 10000,
          'water': metrics['water'],
          'waterGoal': _currentUserProfile.waterIntakeGlasses ?? 8,
          'activeMinutes': metrics['activeMinutes'],
          'activeGoal': _currentUserProfile.workoutDuration ?? 30,
          'calories': metrics['caloriesBurned'],
          'caloriesGoal': _currentUserProfile.tdee?.toInt() ?? 2000,
          'caloriesConsumed': metrics['caloriesConsumed'],
          'netCalories': metrics['netCalories'],
        };
        _isLoadingMetrics = true;
      });
    } catch (e) {
      print('Error loading today progress: $e');
      setState(() => _isLoadingMetrics = false);
    }
  }

  Future<void> _generateSmartInsights() async {
    if (!_smartInsightsEnabled) return;
    
    try {
      final insights = await _insightsService.generateDailyInsights(
        _currentUserProfile,
        todayProgress,
      );
      
      setState(() {
        smartInsights = insights;
      });
    } catch (e) {
      print('Error generating insights: $e');
      setState(() {
        smartInsights = ["💪 Keep going! You're doing great today!"];
      });
    }
  }

  void _loadUpcomingEvents() {
    if (!_upcomingEventsEnabled) return;
    
    try {
      final events = _scheduleService.generateDailySchedule(_currentUserProfile);
      
      setState(() {
        upcomingEvents = events;
      });
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.refreshProfile();
    
    if (userProvider.userProfile != null && mounted) {
      setState(() {
        _currentUserProfile = userProvider.userProfile!;
      });
      await _loadInitialData();
    }
  }

  Future<void> _quickUpdateWater(int glasses) async {
    try {
      await _metricsService.updateWater(_currentUserProfile.id!, glasses);
      await _loadTodayProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Water intake updated: $glasses glasses')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update water intake')),
      );
    }
  }

  Future<void> _quickUpdateSteps(int steps) async {
    try {
      await _metricsService.updateSteps(_currentUserProfile.id!, steps);
      await _loadTodayProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Steps updated: $steps')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update steps')),
      );
    }
  }

  void _showWaterUpdateDialog() {
    int currentGlasses = todayProgress['water'] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Water Intake'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$currentGlasses glasses',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentGlasses > 0
                        ? () => setDialogState(() => currentGlasses--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline, size: 36),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    onPressed: () => setDialogState(() => currentGlasses++),
                    icon: const Icon(Icons.add_circle_outline, size: 36),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _quickUpdateWater(currentGlasses);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStepsUpdateDialog() {
    final controller = TextEditingController(
      text: todayProgress['steps'].toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Steps'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Step Count',
            suffixText: 'steps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final steps = int.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _quickUpdateSteps(steps);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = _currentUserProfile.name.split(' ')[0];
    
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
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: ActivityDrawer(userProfile: _currentUserProfile),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildHeader(),
                ),
              ),

              // Goal Progress
              if(_goalProgressEnabled)
                if (_currentUserProfile.weightGoal != null && 
                  _currentUserProfile.weightGoal.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildGoalProgress(),
                    ),
                  ),
              
              // Quick Actions
              if (_quickActionsEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildQuickActions(),
                  ),
                ),

              if (_todayProgressEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DailyGoalsCard(
                      userProfile: widget.userProfile,
                      onTap: () {
                        // Navigate to meal logging page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnhancedMealLoggingPage(
                              userProfile: widget.userProfile,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),


              // Smart Insights
              if (_smartInsightsEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSmartInsights(),
                  ),
                ),
              
              // Upcoming Events
              if (_upcomingEventsEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildUpcomingEvents(),
                  ),
                ),
              
              
              
              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============== SECTION BUILDERS ==============
  
  Widget _buildHeader() {
    return Row(
      children: [
        // Menu button
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, size: 28, color: Colors.blue),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Greeting
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
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Notifications
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                // TODO: Implement notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
            // Notification dot
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

  Widget _buildGoalProgress() {
    if (!_goalProgressEnabled || 
        _currentUserProfile.weightGoal == null || 
        _currentUserProfile.weightGoal!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return DashboardWeightGoalCard(userProfile: _currentUserProfile);
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.edit_note,
                label: 'Log Activity',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActivityLoggingMenu(
                        userProfile: _currentUserProfile,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fitness_center,
                label: 'Start Workout',
                color: Colors.orange,
                onTap: () {
                  // TODO: Implement workout start
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Workout feature coming soon!')),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.analytics,
                label: "Today's Report",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TodayReportScreen(
                        userProfile: _currentUserProfile,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.chat,
                label: 'AI Coach',
                color: Colors.purple,
                onTap: () {
                  widget.onTabChange?.call(1);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartInsights() {
    if (smartInsights.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...smartInsights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, size: 20),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    insight,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    if (upcomingEvents.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coming Up Today',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...upcomingEvents.map((event) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  event['icon'] as IconData,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(event['time']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Handle event action
                },
                child: const Text('View'),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
  
  Widget _buildStreaks(Map<String, dynamic> streaks) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: streaks.entries.map((entry) {
          IconData icon;
          Color color;
          
          switch (entry.key) {
            case 'steps':
              icon = Icons.directions_walk;
              color = Colors.blue;
              break;
            case 'water':
              icon = Icons.water_drop;
              color = Colors.cyan;
              break;
            case 'workout':
              icon = Icons.fitness_center;
              color = Colors.orange;
              break;
            default:
              icon = Icons.check;
              color = Colors.green;
          }
          
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, size: 32, color: color.withOpacity(0.3)),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                entry.key,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievements(List<dynamic> achievements) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Achievements',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: achievements.take(3).map((achievement) {
              return Chip(
                avatar: Text(achievement['icon'], style: const TextStyle(fontSize: 16)),
                label: Text(achievement['title']),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============== CUSTOM WIDGETS ==============

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactDailyGoalsCard extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onTap;
  
  const CompactDailyGoalsCard({
    Key? key,
    required this.userProfile,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final tdee = (userProfile.formData?['tdee'] ?? 2000).toDouble();
    final weightGoal = userProfile.primaryGoal ?? 'maintain_weight';
    
    // Calculate goals
    double dailyCalories;
    if (weightGoal.toLowerCase().contains('lose')) {
      dailyCalories = tdee * 0.82;
    } else if (weightGoal.toLowerCase().contains('gain')) {
      dailyCalories = tdee * 1.12;
    } else {
      dailyCalories = tdee;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Calorie Goal',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dailyCalories.round()} kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}