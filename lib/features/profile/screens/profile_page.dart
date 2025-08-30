// lib/features/profile/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/features/profile/screens/edit_profile_page.dart';
import 'package:user_onboarding/features/profile/screens/settings_page.dart';
import 'package:user_onboarding/features/auth/screens/login_screens.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  
  const ProfilePage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late UserProfile currentProfile;
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final DataManager _dataManager = DataManager();
  bool isLoading = false;
  
  // Weight tracking
  List<WeightEntry> weightHistory = [];
  double? currentWeight;
  double? startingWeight;
  DateTime? lastWeightUpdate;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.userProfile;

    // Debug prints to see what data we have
    print('Activity Level: ${currentProfile.activityLevel}');
    print('Workout Location: ${currentProfile.workoutLocation}');
    print('Preferred Workouts: ${currentProfile.preferredWorkouts}');
    print('Available Equipment: ${currentProfile.availableEquipment}');


    _tabController = TabController(length: 4, vsync: this);
    _refreshProfile();
    _loadWeightData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWeightData() async {
    try {
      if (currentProfile.id == null) return;
      
      // Get weight history from weight_entries table
      final history = await _dataManager.getWeightHistory(currentProfile.id!);
      
      if (history.isNotEmpty) {
        // Sort by date to get most recent
        history.sort((a, b) => b.date.compareTo(a.date));
        
        setState(() {
          weightHistory = history;
          currentWeight = history.first.weight; // Most recent weight
          lastWeightUpdate = history.first.date;
          
          // Get starting weight (oldest entry)
          startingWeight = history.last.weight;
        });
      }
    } catch (e) {
      print('Error loading weight data: $e');
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => isLoading = true);
    try {
      final updatedProfile = await _apiService.getUserProfileById(currentProfile.id!);
      if (mounted) {
        setState(() {
          currentProfile = updatedProfile;
        });
      }
      await _loadWeightData(); // Refresh weight data too
    } catch (e) {
      print('Error refreshing profile: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userProfile: currentProfile),
      ),
    );
    
    if (result != null && result is UserProfile) {
      setState(() {
        currentProfile = result;
      });
      await _loadWeightData(); // Reload weight data after edit
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserManager.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar with Profile Header
            SliverAppBar(
              expandedHeight: 320, // Increased from 280
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(userProfile: currentProfile),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _handleLogout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax, // Better collapse animation
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 56), // Space for app bar icons
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                currentProfile.name.isNotEmpty 
                                    ? currentProfile.name[0].toUpperCase() 
                                    : '?',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Edit Profile Button
                          ElevatedButton.icon(
                            onPressed: _navigateToEditProfile,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 20),
                          
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Goals'),
                      Tab(text: 'Health'),
                      Tab(text: 'Exercise'),
                    ],
                  ),
                ),
              ),
            ),
            
            // Tab Content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildGoalsTab(),
                  _buildHealthTab(),
                  _buildExerciseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    final activityInfo = _getActivityLevelInfo(currentProfile.activityLevel);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildCard(
            title: 'Basic Information',
            icon: Icons.person,
            children: [
              _buildInfoRow('Name', currentProfile.name),
              _buildInfoRow('Email', currentProfile.email),
              _buildInfoRow('Age', '${currentProfile.age ?? 0} years'),
              _buildInfoRow('Gender', currentProfile.gender ?? 'Not specified'),
              _buildInfoRow('Height', '${currentProfile.height?.toStringAsFixed(0) ?? 0} cm'),
              _buildInfoRow('Current Weight', '${currentWeight?.toStringAsFixed(1) ?? currentProfile.weight?.toStringAsFixed(1) ?? 0} kg'),
              if (lastWeightUpdate != null)
                _buildInfoRow('Last Weight Update', DateFormat('MMM d, yyyy').format(lastWeightUpdate!)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Body Metrics Card
          _buildCard(
            title: 'Body Metrics',
            icon: Icons.analytics,
            children: [
              _buildMetricRow('BMI', 
                _calculateBMI()?.toStringAsFixed(1) ?? 'Not calculated',
                _getBMICategory(_calculateBMI() ?? 0),
                _getBMIColor(_calculateBMI() ?? 0),
              ),
              _buildMetricRow('BMR', 
                '${_calculateBMR()?.toStringAsFixed(0) ?? 0} cal/day',
                'Basal Metabolic Rate',
              ),
              _buildMetricRow('TDEE', 
                '${_calculateTDEE()?.toStringAsFixed(0) ?? 0} cal/day',
                'Total Daily Energy Expenditure',
              ),
              _buildMetricRow('Activity Level', activityInfo['name']!, activityInfo['description']!),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Account Info Card
          _buildCard(
            title: 'Account Information',
            icon: Icons.account_circle,
            children: [
              _buildInfoRow('Profile Completion', '${_calculateProfileCompletion()}%'),
              if (weightHistory.isNotEmpty)
                _buildInfoRow('Weight Entries', '${weightHistory.length} records'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    // Use weight from weight_entries for calculations
    final latestWeight = currentWeight ?? currentProfile.weight ?? 0;
    final targetWeight = currentProfile.targetWeight ?? latestWeight;
    final initialWeight = startingWeight ?? currentProfile.weight ?? latestWeight;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary Goal Card
          _buildCard(
            title: 'Primary Goal',
            icon: Icons.star,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: Colors.orange, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentProfile.primaryGoal ?? 'Not Set',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGoalDescription(currentProfile.primaryGoal ?? ''),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Weight Management Card - Using data from weight_entries
          _buildCard(
            title: 'Weight Management',
            icon: _getWeightGoalIcon(currentProfile.weightGoal ?? ''),
            children: [
              // Goal-specific header
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _getWeightGoalColor(currentProfile.weightGoal ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getWeightGoalColor(currentProfile.weightGoal ?? '').withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getWeightGoalIcon(currentProfile.weightGoal ?? ''),
                      color: _getWeightGoalColor(currentProfile.weightGoal ?? ''),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatWeightGoal(currentProfile.weightGoal ?? ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getWeightGoalDescription(currentProfile.weightGoal ?? ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weight stats based on goal
              _buildInfoRow('Starting Weight', '${initialWeight.toStringAsFixed(1)} kg'),
              _buildInfoRow('Current Weight', '${latestWeight.toStringAsFixed(1)} kg'),
              
              // Only show target weight if not maintaining
              if (currentProfile.weightGoal != 'maintain_weight' && 
                  currentProfile.weightGoal != 'Maintain Weight') ...[
                _buildInfoRow('Target Weight', '${targetWeight.toStringAsFixed(1)} kg'),
                _buildInfoRow('Timeline', _formatTimeline(currentProfile.goalTimeline ?? '')),
                const Divider(),
                _buildWeightProgressForGoal(
                  latestWeight, 
                  targetWeight, 
                  initialWeight, 
                  currentProfile.weightGoal ?? ''
                ),
              ] else ...[
                const Divider(),
                _buildMaintenanceProgress(latestWeight, initialWeight),
              ],
              
              // Weight trend for all goals
              if (weightHistory.length > 1) ...[
                const SizedBox(height: 16),
                _buildWeightTrendForGoal(currentProfile.weightGoal ?? ''),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fitness Goals Card
          _buildCard(
            title: 'Fitness Goals',
            icon: Icons.sports_score,
            children: [
              _buildInfoRow('Fitness Level', currentProfile.fitnessLevel ?? 'Beginner'),
              _buildInfoRow('Workout Frequency', '${currentProfile.workoutFrequency ?? 0} days/week'),
              _buildInfoRow('Session Duration', '${currentProfile.workoutDuration ?? 0} minutes'),
              _buildInfoRow('Daily Steps', '${currentProfile.dailyStepGoal ?? 10000} steps'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           
          // Medical Conditions Card
          _buildCard(
            title: 'Medical Conditions',
            icon: Icons.medical_services,
            children: [
              if (currentProfile.medicalConditions?.isEmpty ?? true)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No medical conditions reported'),
                )
              else
                ...currentProfile.medicalConditions!.map((condition) => 
                  _buildChip(condition, Colors.red.withOpacity(0.1), Colors.red)
                ),
              if (currentProfile.otherMedicalCondition?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildInfoRow('Other', currentProfile.otherMedicalCondition!),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sleep Health Card
          _buildCard(
            title: 'Sleep Health',
            icon: Icons.bedtime,
            children: [
              _buildInfoRow('Sleep Target', '${currentProfile.sleepHours ?? 8} hours'),
              _buildInfoRow('Bedtime', currentProfile.bedtime ?? 'Not set'),
              _buildInfoRow('Wake Time', currentProfile.wakeupTime ?? 'Not set'),
              const Divider(),
              const Text('Sleep Issues:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (currentProfile.sleepIssues?.isEmpty ?? true)
                const Text('No sleep issues reported')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProfile.sleepIssues!.map((issue) => 
                    _buildChip(issue, Colors.purple.withOpacity(0.1), Colors.purple)
                  ).toList(),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Nutrition Card
          _buildCard(
            title: 'Nutrition',
            icon: Icons.restaurant,
            children: [
              _buildInfoRow('Water Goal', '${currentProfile.waterIntake ?? 2} L (${currentProfile.waterIntakeGlasses ?? 8} glasses)'),
              _buildInfoRow('Daily Meals Target', '${currentProfile.dailyMealsCount ?? 3} meals'),
              const Divider(),
              const Text('Dietary Preferences:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (currentProfile.dietaryPreferences?.isEmpty ?? true)
                const Text('No dietary preferences set')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProfile.dietaryPreferences!.map((pref) => 
                    _buildChip(pref, Colors.green.withOpacity(0.1), Colors.green)
                  ).toList(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Women's Health Card (conditional)
          if (currentProfile.gender?.toLowerCase() == 'female') ...[
            const SizedBox(height: 16),
            _buildCard(
              title: "Women's Health",
              icon: Icons.favorite,
              children: [
                _buildInfoRow('Period Tracking', 
                  _formatPeriodTracking(currentProfile.periodTrackingPreference ?? '')
                ),
                if (currentProfile.pregnancyStatus?.isNotEmpty ?? false)
                  _buildInfoRow('Status', _formatPregnancyStatus(currentProfile.pregnancyStatus!)),
                if (currentProfile.cycleLength != null)
                  _buildInfoRow('Cycle Length', '${currentProfile.cycleLength} days'),
                if (currentProfile.cycleLengthRegular != null)
                  _buildInfoRow('Cycle Regularity', 
                    currentProfile.cycleLengthRegular! ? 'Regular' : 'Irregular'
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Workout Preferences Card
          _buildCard(
            title: 'Workout Preferences',
            icon: Icons.fitness_center,
            children: [
              _buildInfoRow('Fitness Level', currentProfile.fitnessLevel ?? 'Beginner'),
              _buildInfoRow('Frequency', '${currentProfile.workoutFrequency ?? 0} days/week'),
              _buildInfoRow('Duration', '${currentProfile.workoutDuration ?? 0} minutes/session'),
              _buildInfoRow('Workout Location', currentProfile.workoutLocation ?? 'Not specified'),
              _buildInfoRow('Personal Trainer', currentProfile.hasTrainer == true ? 'Yes' : 'No'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Preferred Workouts Card
          _buildCard(
            title: 'Preferred Workout Types',
            icon: Icons.sports_martial_arts,
            children: [
              if (currentProfile.preferredWorkouts?.isEmpty ?? true)
                const Text('No workout preferences set')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProfile.preferredWorkouts!.map((workout) => 
                    _buildChip(workout, Colors.orange.withOpacity(0.1), Colors.orange)
                  ).toList(),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Available Equipment Card
          _buildCard(
            title: 'Available Equipment',
            icon: Icons.sports,
            children: [
              if (currentProfile.availableEquipment?.isEmpty ?? true)
                const Text('No equipment specified')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProfile.availableEquipment!.map((equipment) => 
                    Chip(
                      label: Text(
                        equipment,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green.withOpacity(0.1),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    )
                  ).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Updated weight progress using actual weight data
  Widget _buildWeightProgress(double current, double target, double start) {
    final totalChange = (target - start).abs();
    final currentChange = (current - start).abs();
    final progress = totalChange > 0 ? (currentChange / totalChange).clamp(0.0, 1.0) : 0.0;
    
    final isLosing = target < start;
    final progressColor = isLosing ? Colors.green : Colors.orange;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeightStat('Start', start),
            _buildWeightStat('Current', current),
            _buildWeightStat('Target', target),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: progressColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% to goal',
          style: TextStyle(
            color: progressColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper methods remain the same...
  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String subtitle, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color backgroundColor, Color textColor) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildWeightStat(String label, double weight) {
   return Column(
     children: [
       Text(
         label,
         style: TextStyle(
           color: Colors.grey[600],
           fontSize: 12,
         ),
       ),
       const SizedBox(height: 4),
       Text(
         '${weight.toStringAsFixed(1)} kg',
         style: const TextStyle(
           fontWeight: FontWeight.bold,
           fontSize: 14,
         ),
       ),
     ],
   );
 }

 // Weight progress for specific goals
Widget _buildWeightProgressForGoal(
  double current, 
  double target, 
  double start, 
  String goal
) {
  final normalizedGoal = goal.toLowerCase().replaceAll(' ', '_');
  
  if (normalizedGoal == 'lose_weight') {
    // For weight loss: progress from start to target (going down)
    final totalToLose = start - target;
    final alreadyLost = start - current;
    final progress = totalToLose > 0 ? (alreadyLost / totalToLose).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeightStatWithLabel('Start', start, false),
            Icon(Icons.arrow_forward, color: Colors.grey),
            _buildWeightStatWithLabel('Current', current, true),
            Icon(Icons.arrow_forward, color: Colors.grey),
            _buildWeightStatWithLabel('Target', target, false),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: TextStyle(color: Colors.grey[600])),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.green.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Lost ${alreadyLost.toStringAsFixed(1)} kg of ${totalToLose.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  } else if (normalizedGoal == 'gain_weight') {
    // For weight gain: progress from start to target (going up)
    final totalToGain = target - start;
    final alreadyGained = current - start;
    final progress = totalToGain > 0 ? (alreadyGained / totalToGain).clamp(0.0, 1.0) : 0.0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildWeightStatWithLabel('Start', start, false),
            Icon(Icons.arrow_forward, color: Colors.grey),
            _buildWeightStatWithLabel('Current', current, true),
            Icon(Icons.arrow_forward, color: Colors.grey),
            _buildWeightStatWithLabel('Target', target, false),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: TextStyle(color: Colors.grey[600])),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.orange.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Gained ${alreadyGained.toStringAsFixed(1)} kg of ${totalToGain.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Default fallback
  return _buildWeightProgress(current, target, start);
}

// Maintenance progress (no target)
Widget _buildMaintenanceProgress(double current, double initial) {
  final difference = current - initial;
  final isDifferent = difference.abs() > 0.1;
  
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWeightStatWithLabel('Starting', initial, false),
          Icon(
            Icons.swap_horiz,
            color: Colors.blue,
            size: 30,
          ),
          _buildWeightStatWithLabel('Current', current, true),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDifferent 
                ? (difference > 0 ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.check_circle,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isDifferent
                ? 'Weight ${difference > 0 ? "increased" : "decreased"} by ${difference.abs().toStringAsFixed(1)} kg'
                : 'Weight maintained successfully',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Enhanced weight stat with highlighting
Widget _buildWeightStatWithLabel(String label, double weight, bool isHighlighted) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          color: isHighlighted ? Colors.blue : Colors.grey[600],
          fontSize: 12,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isHighlighted 
            ? Border.all(color: Colors.blue.withOpacity(0.3))
            : null,
        ),
        child: Text(
          '${weight.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isHighlighted ? Colors.blue : Colors.black,
          ),
        ),
      ),
    ],
  );
}

  // Weight trend specific to goal
  Widget _buildWeightTrendForGoal(String goal) {
    if (weightHistory.length < 2) return const SizedBox();
    
    final normalizedGoal = goal.toLowerCase().replaceAll(' ', '_');
    final recentWeight = weightHistory.first.weight;
    final previousWeight = weightHistory[1].weight;
    final change = recentWeight - previousWeight;
    
    // Determine if the trend is positive based on goal
    bool isPositiveTrend = false;
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.trending_flat;
    
    if (normalizedGoal == 'lose_weight') {
      isPositiveTrend = change < 0;
      trendColor = isPositiveTrend ? Colors.green : Colors.red;
      trendIcon = change < 0 ? Icons.trending_down : Icons.trending_up;
    } else if (normalizedGoal == 'gain_weight') {
      isPositiveTrend = change > 0;
      trendColor = isPositiveTrend ? Colors.green : Colors.red;
      trendIcon = change > 0 ? Icons.trending_up : Icons.trending_down;
    } else { // maintain_weight
      isPositiveTrend = change.abs() < 0.5; // Within 0.5kg is good for maintenance
      trendColor = isPositiveTrend ? Colors.green : Colors.orange;
      trendIcon = change.abs() < 0.5 ? Icons.horizontal_rule : (change > 0 ? Icons.trending_up : Icons.trending_down);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(trendIcon, color: trendColor),
          const SizedBox(width: 8),
          Text(
            _getTrendMessage(normalizedGoal, change),
            style: TextStyle(
              color: trendColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

 // Calculation Methods
 double? _calculateBMI() {
   final height = currentProfile.height;
   // Use current weight from weight_entries if available
   final weight = currentWeight ?? currentProfile.weight;
   if (height != null && height > 0 && weight != null && weight > 0) {
     final heightInMeters = height / 100;
     return weight / (heightInMeters * heightInMeters);
   }
   return null;
 }

 double? _calculateBMR() {
   final height = currentProfile.height;
   // Use current weight from weight_entries if available
   final weight = currentWeight ?? currentProfile.weight;
   final age = currentProfile.age;
   final gender = currentProfile.gender;
   
   if (height != null && weight != null && age != null && gender != null) {
     if (gender.toLowerCase() == 'male') {
       return (10 * weight) + (6.25 * height) - (5 * age) + 5;
     } else {
       return (10 * weight) + (6.25 * height) - (5 * age) - 161;
     }
   }
   return null;
 }

 double? _calculateTDEE() {
    final bmr = _calculateBMR();
    if (bmr != null) {
      final activityMultipliers = {
        'sedentary': 1.2,
        'lightly_active': 1.375,
        'moderately_active': 1.55,
        'very_active': 1.725,
        'extra_active': 1.9,
      };
      return bmr * (activityMultipliers[currentProfile.activityLevel] ?? 1.55);
   }
   return null;
  }

  // Get trend message based on goal
  String _getTrendMessage(String goal, double change) {
    final absChange = change.abs().toStringAsFixed(1);
    
    if (goal == 'lose_weight') {
      return change < 0 
        ? '✓ Lost $absChange kg since last entry'
        : '⚠ Gained $absChange kg since last entry';
    } else if (goal == 'gain_weight') {
      return change > 0
        ? '✓ Gained $absChange kg since last entry'
        : '⚠ Lost $absChange kg since last entry';
    } else { // maintain_weight
      return change.abs() < 0.5
        ? '✓ Weight stable (${change > 0 ? "+" : ""}${change.toStringAsFixed(1)} kg)'
        : '⚠ Weight changed by ${change > 0 ? "+" : ""}${change.toStringAsFixed(1)} kg';
    }
}

  // Utility Methods
  String _getActivityLevelDisplay(String? level) {
    if (level == null || level.isEmpty) return 'Not set';
    
    // Just format the string nicely - replace underscores and capitalize
    return level
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty 
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' 
        : '')
      .join(' ');
  }

  Map<String, String> _getActivityLevelInfo(String? level) {
    if (level == null || level.isEmpty) {
      return {'name': 'Not set', 'description': 'Activity level not specified'};
    }
    
    // Normalize to lowercase with underscores
    final key = level.toLowerCase().replaceAll(' ', '_');
    
    const activities = {
      'sedentary': {'name': 'Sedentary', 'desc': 'Little or no exercise'},
      'lightly_active': {'name': 'Lightly Active', 'desc': 'Exercise 1-3 days/week'},
      'moderately_active': {'name': 'Moderately Active', 'desc': 'Exercise 3-5 days/week'},
      'very_active': {'name': 'Very Active', 'desc': 'Exercise 6-7 days/week'},
      'extra_active': {'name': 'Extra Active', 'desc': 'Very intense exercise daily'},
    };
    
    final info = activities[key];
    if (info != null) {
      return {'name': info['name']!, 'description': info['desc']!};
    }
    
    // Fallback: just format the original string
    final formatted = level
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '')
      .join(' ');
      
    return {'name': formatted, 'description': 'Activity level: $formatted'};
  }

  String _getBMICategory(double bmi) {
    if (bmi == 0) return 'Not calculated';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal weight';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi == 0) return Colors.grey;
    if (bmi < 18.5) return Colors.orange;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  String _formatWeightGoal(String goal) {
    final Map<String, String> goals = {
      'lose_weight': 'Lose Weight',
      'gain_weight': 'Gain Weight',
      'maintain_weight': 'Maintain Weight',
    };
    return goals[goal] ?? goal;
  }

  String _formatTimeline(String timeline) {
    final Map<String, String> timelines = {
      '4_weeks': '4 Weeks',
      '8_weeks': '8 Weeks',
      '12_weeks': '12 Weeks',
      '16_weeks': '16 Weeks',
      '6_months': '6 Months',
      '1_year': '1 Year',
    };
    return timelines[timeline] ?? timeline;
  }

  String _getGoalDescription(String goal) {
    final Map<String, String> descriptions = {
      'Lose Weight': 'Focus on creating a caloric deficit through diet and exercise',
      'Gain Weight': 'Build muscle mass with strength training and increased nutrition',
      'Build Muscle': 'Progressive overload training with adequate protein intake',
      'Improve Fitness': 'Enhance cardiovascular health and overall endurance',
      'Maintain Health': 'Keep current fitness level with balanced lifestyle',
      'General Wellness': 'Overall health improvement through balanced approach',
    };
    return descriptions[goal] ?? 'Personalized fitness journey';
  }

  String _formatPeriodTracking(String preference) {
    final Map<String, String> preferences = {
      'track_periods': 'Active Tracking',
      'general_wellness': 'General Wellness Only',
      'no_tracking': 'No Tracking',
    };
    return preferences[preference] ?? 'Not specified';
  }

  String _formatPregnancyStatus(String status) {
    final Map<String, String> statuses = {
      'not_pregnant': 'Not Pregnant',
      'pregnant': 'Currently Pregnant',
      'breastfeeding': 'Breastfeeding',
      'trying_to_conceive': 'Trying to Conceive',
      'prefer_not_to_say': 'Prefer Not to Say',
    };
    return statuses[status] ?? status;
  }

  IconData _getEquipmentIcon(String equipment) {
    final Map<String, IconData> icons = {
      'Dumbbells': Icons.fitness_center,
      'Barbell': Icons.fitness_center,
      'Resistance Bands': Icons.sports,
      'Kettlebells': Icons.sports_handball,
      'Pull-up Bar': Icons.height,
      'Treadmill': Icons.directions_run,
      'Exercise Bike': Icons.directions_bike,
      'Rowing Machine': Icons.rowing,
      'Yoga Mat': Icons.self_improvement,
      'Foam Roller': Icons.sports,
      'Jump Rope': Icons.sports,
      'Medicine Ball': Icons.sports_basketball,
      'TRX Straps': Icons.sports,
      'Bench': Icons.weekend,
      'None': Icons.block,
    };
    return icons[equipment] ?? Icons.sports;
  }

    IconData _getWeightGoalIcon(String goal) {
      final normalizedGoal = goal.toLowerCase().replaceAll(' ', '_');
      switch (normalizedGoal) {
        case 'lose_weight':
          return Icons.trending_down;
        case 'gain_weight':
          return Icons.trending_up;
        case 'maintain_weight':
          return Icons.horizontal_rule;
        default:
          return Icons.trending_flat;
      }
    }

    // Color based on weight goal
    Color _getWeightGoalColor(String goal) {
      final normalizedGoal = goal.toLowerCase().replaceAll(' ', '_');
      switch (normalizedGoal) {
        case 'lose_weight':
          return Colors.green;
        case 'gain_weight':
          return Colors.orange;
        case 'maintain_weight':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    // Description for weight goal
    String _getWeightGoalDescription(String goal) {
      final normalizedGoal = goal.toLowerCase().replaceAll(' ', '_');
      switch (normalizedGoal) {
        case 'lose_weight':
          return 'Creating a caloric deficit for healthy weight loss';
        case 'gain_weight':
          return 'Building mass through increased nutrition and training';
        case 'maintain_weight':
          return 'Maintaining current weight with balanced lifestyle';
        default:
          return 'Personalized weight management plan';
      }
    }


  int _calculateProfileCompletion() {
    int filledFields = 0;
    int totalFields = 30; // Adjusted for actual fields
    
    // Basic info (6 fields)
    if (currentProfile.name.isNotEmpty) filledFields++;
    if (currentProfile.email.isNotEmpty) filledFields++;
    if (currentProfile.age != null) filledFields++;
    if (currentProfile.gender != null) filledFields++;
    if (currentProfile.height != null) filledFields++;
    if (currentWeight != null || currentProfile.weight != null) filledFields++;
    
    // Goals (5 fields)
    if (currentProfile.primaryGoal != null) filledFields++;
    if (currentProfile.weightGoal != null) filledFields++;
    if (currentProfile.targetWeight != null) filledFields++;
    if (currentProfile.goalTimeline != null) filledFields++;
    if (currentProfile.activityLevel != null) filledFields++;
    
    // Daily targets (6 fields)
    if (currentProfile.dailyStepGoal != null) filledFields++;
    if (currentProfile.sleepHours != null) filledFields++;
    if (currentProfile.waterIntake != null) filledFields++;
    if (currentProfile.workoutFrequency != null) filledFields++;
    if (currentProfile.workoutDuration != null) filledFields++;
    if (currentProfile.fitnessLevel != null) filledFields++;
    
    // Lifestyle (4 fields)
    if (currentProfile.bedtime != null) filledFields++;
    if (currentProfile.wakeupTime != null) filledFields++;
    if (currentProfile.workoutLocation != null) filledFields++;
    if (currentProfile.hasTrainer != null) filledFields++;
    
    // Lists (5 fields)
    if (currentProfile.sleepIssues?.isNotEmpty ?? false) filledFields++;
    if (currentProfile.dietaryPreferences?.isNotEmpty ?? false) filledFields++;
    if (currentProfile.preferredWorkouts?.isNotEmpty ?? false) filledFields++;
    if (currentProfile.medicalConditions?.isNotEmpty ?? false) filledFields++;
    if (currentProfile.availableEquipment?.isNotEmpty ?? false) filledFields++;
    
    // Women's health (if applicable)
    if (currentProfile.gender?.toLowerCase() == 'female') {
      totalFields += 4;
      if (currentProfile.hasPeriods != null) filledFields++;
      if (currentProfile.pregnancyStatus != null) filledFields++;
      if (currentProfile.periodTrackingPreference != null) filledFields++;
      if (currentProfile.cycleLength != null) filledFields++;
    }
    
    return ((filledFields / totalFields) * 100).round();
  }
}