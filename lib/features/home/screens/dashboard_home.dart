// lib/features/home/screens/dashboard_home.dart
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/services/api/supplement_api.dart';
import 'package:user_onboarding/data/services/notification_service.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/widgets/activity_drawer.dart';
import 'package:user_onboarding/features/tracking/screens/meal_logging_page.dart';
import 'package:user_onboarding/providers/user_provider.dart';
import 'package:user_onboarding/utils/profile_update_notifier.dart';
import 'package:user_onboarding/data/services/metrics_service.dart';
import 'package:user_onboarding/features/home/widgets/dashboard_weight_goal_card.dart';
import 'package:user_onboarding/features/home/widgets/daily_meal_card.dart';
import 'package:user_onboarding/features/home/widgets/compact_water_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_step_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_exercise_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_sleep_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_supplements_tracker.dart';
import 'package:user_onboarding/features/home/widgets/compact_period_tracker.dart';
import 'package:user_onboarding/features/home/widgets/weekly_stats_card.dart';
import 'package:user_onboarding/features/notifications/screens/notifications_screen.dart';
import 'package:user_onboarding/services/fcm_service.dart';
// import 'package:user_onboarding/utils/user_diagnostic_widget.dart';


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
  int _unreadNotificationCount = 0;
  Timer? _notificationRefreshTimer;

  // Feature flags
  final bool _dailyMacros = true;
  final bool _goalProgressEnabled = true;
  final bool _waterTrackerEnabled = true;
  final bool _stepTrackerEnabled = true;
  final bool _exerciseTrackerEnabled = true;
  final bool _sleepTrackerEnabled = true;
  bool _supplementsTrackerEnabled = true;
  bool _hasSupplementsSetup = false;
  
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
    _checkSupplementsSetup();
    _loadUnreadCount();
    _notificationRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        if (mounted) {
          // If the calendar day has rolled over, re-schedule (which re-logs
          // today's notifications) so new notifications appear without needing
          // to log out and back in. Guarded to run once per day.
          _checkAndRescheduleNotifications();
          _loadUnreadCount();
        }
      },
    );
    _loadInitialData();
    _subscribeFCM();
    _checkAndRescheduleNotifications();
  }

  @override
  void dispose() {
    _notificationRefreshTimer?.cancel();
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

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;
    
    try {
      print('🔔 Loading unread notification count...');
      final count = await NotificationService().getUnreadCount(_currentUserProfile.id);
      
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
        print('✅ Unread count updated: $count');
      }
    } catch (e) {
      print('❌ Error loading unread count: $e');
      // Don't show error to user, just log it
    }
  }

  Future<void> _checkSupplementsSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUserProfile.id ?? '';
      
      // Check if supplements are set up (not disabled and has supplements list)
      final isDisabled = prefs.getBool('supplement_setup_${userId}_disabled') ?? false;
      if (isDisabled) {
        setState(() => _hasSupplementsSetup = false);
        return;
      }
      
      // Check for setup flag or supplements list
      final hasSetup = prefs.getBool('supplement_setup_$userId') ?? false;
      final supplementsJson = prefs.getString('supplement_setup_${userId}_list');
      
      if (hasSetup || (supplementsJson != null && supplementsJson.isNotEmpty)) {
        setState(() => _hasSupplementsSetup = true);
        return;
      }
      
      // Check database as fallback
      final apiService = SupplementApi();
      final preferences = await apiService.getSupplementPreferences(userId);
      setState(() => _hasSupplementsSetup = preferences.isNotEmpty);
    } catch (e) {
      print('Error checking supplement setup: $e');
      setState(() => _hasSupplementsSetup = false);
    }
  }

  // Re-schedules (and re-logs) today's notifications once per calendar day.
  // Previously this only ran at login with a rolling 24h guard and an
  // `pending.isEmpty` check, so once notifications were scheduled they were
  // never re-logged during a session — the badge froze and today's
  // notifications only appeared after a logout/login. Keying off the calendar
  // day (and calling it from the periodic timer + on resume) makes them refresh
  // automatically at day rollover.
  bool _isReschedulingNotifications = false;

  Future<void> _checkAndRescheduleNotifications() async {
    // Set synchronously (before any await) so overlapping calls from the timer
    // and the resume handler can't both schedule.
    if (_isReschedulingNotifications) return;
    _isReschedulingNotifications = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _currentUserProfile.id;
      if (userId == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastScheduledDate =
          prefs.getString('notifications_last_scheduled_date_$userId');

      // Already scheduled for today — nothing to do.
      if (lastScheduledDate == today) return;

      print('📱 Scheduling notifications for $today (last: $lastScheduledDate)');

      await NotificationService().scheduleAllNotifications(
        userId,
        _currentUserProfile.toMap(),
      );

      await prefs.setString('notifications_last_scheduled_date_$userId', today);

      // Reflect the freshly logged notifications in the badge immediately.
      if (mounted) await _loadUnreadCount();

      print('✅ Notifications scheduled for $today');
    } catch (e) {
      print('⚠️ Error scheduling notifications: $e');
    } finally {
      _isReschedulingNotifications = false;
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      if (_dailyMacros) _loadTodayProgress(),
    ]);
  }

  Future<void> _subscribeFCM() async {
    try {
      final fcmService = FCMService();
      await fcmService.subscribeToNotifications(_currentUserProfile.id);
      print('✅ FCM subscription refreshed on app start');
    } catch (e) {
      print('⚠️ FCM subscription error: $e');
    }
  }

  Future<void> _loadTodayProgress() async {
    if (!_dailyMacros) return;

    try {
      final metrics = await _metricsService.getTodayMetrics(_currentUserProfile.id!);
      if (!mounted) return;

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
      });
    } catch (e) {
      print('Error loading today progress: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    super.didChangeAppLifecycleState(state);
  
    // Refresh unread count when app comes to foreground, and re-schedule
    // today's notifications if the day rolled over while backgrounded.
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - refreshing notification count');
      _checkAndRescheduleNotifications();
      _loadUnreadCount();
    }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: ActivityDrawer(userProfile: _currentUserProfile),
      body: 
        // Stack(
        // children: [   
          RefreshIndicator(
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
                  if (_goalProgressEnabled || 
                    _currentUserProfile.weightGoal != null && 
                    _currentUserProfile.weightGoal!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: DashboardWeightGoalCard(
                      userProfile: _currentUserProfile,
                      onUpdate: () {
                        _loadTodayProgress();
                      },
                    ),
                  ),

                  // This Week's Progress (taps through to Weekly Summary)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: WeeklyStatsCard(
                        userId: widget.userProfile.id!,
                        userProfile: widget.userProfile,
                      ),
                    ),
                  ),

                  // Daily Macros
                  if (_dailyMacros)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

                  // Water Tracker
                  if (_waterTrackerEnabled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactWaterTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
                      ),
                    ),

                  // Step Tracker
                  if (_stepTrackerEnabled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactStepTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
                      ),
                    ),

                  if (_exerciseTrackerEnabled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactExerciseTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
                      ),
                    ),

                  // Sleep Tracker  
                  if (_sleepTrackerEnabled)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactSleepTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
                      ),
                    ),

                  // Supplements Tracker - only show if setup
                  if (_supplementsTrackerEnabled && _hasSupplementsSetup)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactSupplementsTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
                      ),
                    ),
                  
                  if (widget.userProfile.hasPeriods == true)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: CompactPeriodTracker(
                          userProfile: _currentUserProfile,
                          onUpdate: () {
                            _loadTodayProgress();
                          },
                        ),
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

          // const Positioned(
          //           bottom: 80,
          //           left: 0,
          //           right: 0,
          //           child: UserDiagnosticWidget(),
          //         ),
          //       ],
          //     ),
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
              onPressed: () async {
                // ✅ FIXED: Pass userId parameter
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(
                      userId: _currentUserProfile.id, // ← ADDED THIS
                    ),
                  ),
                );
                // Refresh unread count when returning from notifications screen
                _loadUnreadCount();
              },
              tooltip: 'Notifications',
            ),
            // Show notification badge if there are unread notifications
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      _unreadNotificationCount > 9 
                        ? '9+' 
                        : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

}

// ============== CUSTOM WIDGETS ==============

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
    final tdee = (userProfile.tdee ?? 2000).toDouble();
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
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
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