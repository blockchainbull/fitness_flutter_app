// lib/features/home/screens/dashboard_home.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/activity_drawer.dart';
import 'package:user_onboarding/features/tracking/screens/activity_logging_menu.dart';
import 'package:user_onboarding/features/reports/screens/today_report_screen.dart';
import 'package:provider/provider.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'package:user_onboarding/config/environment.dart';
import 'dart:async';
import 'package:user_onboarding/utils/profile_update_notifier.dart';
import 'package:user_onboarding/data/services/metrics_service.dart';
import 'package:user_onboarding/data/services/insights_service.dart';
import 'package:user_onboarding/data/services/schedule_service.dart';
import 'package:user_onboarding/data/services/goal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final GoalService _goalService = GoalService();
  Map<String, dynamic> goalProgress = {};
  StreamSubscription? _stepsSubscription;
  StreamSubscription? _waterSubscription;
  bool _isLoadingMetrics = false;
  final supabase = Supabase.instance.client;
  
  // Feature flags - turn these on as we implement each section
  final bool _calendarEnabled = true;
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
    _stepsSubscription?.cancel();
    _waterSubscription?.cancel();
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
      if (_goalProgressEnabled) _loadGoalProgress(),
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
        _isLoadingMetrics = false;
      });
    } catch (e) {
      print('Error loading today progress: $e');
      setState(() => _isLoadingMetrics = false);
    }
  }

  Future<void> _loadGoalProgress() async {
    if (!_goalProgressEnabled) return;
    
    try {
      final progress = await _goalService.getGoalProgress(_currentUserProfile);
      setState(() {
        goalProgress = progress;
      });
    } catch (e) {
      print('Error loading goal progress: $e');
    }
  }

  void _setupRealtimeListeners() {
    final userId = _currentUserProfile.id;
    if (userId == null) return;
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Listen to steps changes
    void _setupRealtimeListeners() {
      final userId = _currentUserProfile.id;
      if (userId == null) return;
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Correct Supabase stream syntax
      _stepsSubscription = Supabase.instance.client
          .from('daily_steps:user_id=eq.$userId,date=eq.$today')
          .stream(primaryKey: ['user_id', 'date'])
          .listen((List<Map<String, dynamic>> data) {
            if (data.isNotEmpty && mounted) {
              setState(() {
                todayProgress['steps'] = data.first['step_count'] ?? 0;
              });
            }
          });
      
      // Water subscription
      _waterSubscription = Supabase.instance.client
          .from('daily_water:user_id=eq.$userId,date=eq.$today')
          .stream(primaryKey: ['user_id', 'date'])
          .listen((List<Map<String, dynamic>> data) {
            if (data.isNotEmpty && mounted) {
              setState(() {
                todayProgress['water'] = data.first['glasses'] ?? 0;
              });
            }
          });
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
              if (_goalProgressEnabled)
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
              
              // Today's Progress
              if (_todayProgressEnabled)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildTodayProgress(),
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

  Widget _buildTodayProgress() {
    if (_isLoadingMetrics) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Progress",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _ProgressCard(
              title: 'Steps',
              value: todayProgress['steps'].toString(),
              goal: todayProgress['stepsGoal'].toString(),
              icon: Icons.directions_walk,
              color: Colors.blue,
              progress: todayProgress['steps'] / todayProgress['stepsGoal'],
              onTap: _showStepsUpdateDialog,
            ),
            _ProgressCard(
              title: 'Water',
              value: '${todayProgress['water']}',
              goal: '${todayProgress['waterGoal']} glasses',
              icon: Icons.water_drop,
              color: Colors.cyan,
              progress: todayProgress['water'] / todayProgress['waterGoal'],
              onTap: _showWaterUpdateDialog,
            ),
            _ProgressCard(
              title: 'Active Time',
              value: '${todayProgress['activeMinutes']}',
              goal: '${todayProgress['activeGoal']} min',
              icon: Icons.timer,
              color: Colors.orange,
              progress: todayProgress['activeMinutes'] / todayProgress['activeGoal'],
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
            _ProgressCard(
              title: 'Calories',
              value: todayProgress['calories'].toString(),
              goal: todayProgress['caloriesGoal'].toString(),
              icon: Icons.local_fire_department,
              color: Colors.red,
              progress: todayProgress['calories'] / todayProgress['caloriesGoal'],
              onTap: null, // Calories are calculated, not directly editable
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

  Widget _buildGoalProgress() {
    if (goalProgress.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal: ${goalProgress['type']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getProgressColor(goalProgress['percentage']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${goalProgress['percentage'].toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Progress visualization
          if (goalProgress['type'].contains('Weight'))
            _buildWeightProgress(),
          
          // Streaks
          if (goalProgress['streaks'] != null && 
              (goalProgress['streaks'] as Map).isNotEmpty)
            _buildStreaks(goalProgress['streaks']),
          
          // Achievements
          if (goalProgress['achievements'] != null &&
              (goalProgress['achievements'] as List).isNotEmpty)
            _buildAchievements(goalProgress['achievements']),
          
          // Message
          if (goalProgress['message'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                goalProgress['message'],
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightProgress() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${goalProgress['start']?.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.arrow_forward, color: Colors.blue),
                Text(
                  'Current',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${goalProgress['current']?.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Target',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${goalProgress['target']?.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (goalProgress['percentage'] / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation(
            _getProgressColor(goalProgress['percentage']),
          ),
          minHeight: 8,
        ),
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

  Color _getProgressColor(double percentage) {
    if (percentage < 30) return Colors.red;
    if (percentage < 60) return Colors.orange;
    if (percentage < 80) return Colors.yellow[700]!;
    return Colors.green;
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

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final String goal;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback? onTap; 

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.goal,
    required this.icon,
    required this.color,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(  
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Row(
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (onTap != null)
                      const Icon(Icons.edit, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' / $goal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ],
      ),
    )
    );
  }
}