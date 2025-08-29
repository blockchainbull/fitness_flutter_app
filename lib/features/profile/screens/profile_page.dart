// lib/features/profile/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.userProfile;
    _tabController = TabController(length: 5, vsync: this);
    _refreshProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() => isLoading = true);
    try {
      final updatedProfile = await _apiService.fetchUserProfile(currentProfile.id!);
      if (updatedProfile != null && mounted) {
        setState(() {
          currentProfile = updatedProfile;
        });
      }
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
              expandedHeight: 280,
              floating: false,
              pinned: true,
              backgroundColor: Colors.blue,
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
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
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
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name
                        Text(
                          currentProfile.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email
                        Text(
                          currentProfile.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Quick Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildQuickStat(
                              '${currentProfile.age ?? 0}',
                              'Age',
                              Icons.cake,
                            ),
                            _buildQuickStat(
                              currentProfile.gender ?? 'N/A',
                              'Gender',
                              Icons.person,
                            ),
                            _buildQuickStat(
                              '${currentProfile.height?.toStringAsFixed(0) ?? 0} cm',
                              'Height',
                              Icons.height,
                            ),
                            _buildQuickStat(
                              '${currentProfile.weight?.toStringAsFixed(1) ?? 0} kg',
                              'Weight',
                              Icons.monitor_weight,
                            ),
                          ],
                        ),
                      ],
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
                    isScrollable: true,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Goals'),
                      Tab(text: 'Health'),
                      Tab(text: 'Exercise'),
                      Tab(text: 'Lifestyle'),
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
                  _buildLifestyleTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToEditProfile,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.edit),
        label: const Text('Edit Profile'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Body Metrics Card
          _buildCard(
            title: 'Body Metrics',
            icon: Icons.analytics,
            children: [
              _buildMetricRow('BMI', 
                currentProfile.bmi?.toStringAsFixed(1) ?? 'Not calculated',
                _getBMICategory(currentProfile.bmi ?? 0),
                _getBMIColor(currentProfile.bmi ?? 0),
              ),
              _buildMetricRow('BMR', 
                '${currentProfile.bmr?.toStringAsFixed(0) ?? 0} cal/day',
                'Basal Metabolic Rate',
              ),
              _buildMetricRow('TDEE', 
                '${currentProfile.tdee?.toStringAsFixed(0) ?? 0} cal/day',
                'Total Daily Energy Expenditure',
              ),
              _buildMetricRow('Activity Level', 
                _formatActivityLevel(currentProfile.activityLevel ?? ''),
                _getActivityDescription(currentProfile.activityLevel ?? ''),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Daily Targets Card
          _buildCard(
            title: 'Daily Targets',
            icon: Icons.flag,
            children: [
              _buildProgressRow(
                'Steps Goal',
                currentProfile.dailyStepGoal ?? 10000,
                10000,
                'steps',
                Colors.green,
              ),
              _buildProgressRow(
                'Water Intake',
                currentProfile.waterIntakeGlasses ?? 8,
                8,
                'glasses',
                Colors.blue,
              ),
              _buildProgressRow(
                'Sleep Target',
                currentProfile.sleepHours?.toInt() ?? 8,
                8,
                'hours',
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Account Info Card
          _buildCard(
            title: 'Account Information',
            icon: Icons.account_circle,
            children: [
              _buildInfoRow('Member Since', 
                currentProfile.createdAt != null 
                  ? DateFormat('MMMM d, yyyy').format(currentProfile.createdAt!)
                  : 'Unknown'
              ),
              _buildInfoRow('Last Updated', 
                currentProfile.updatedAt != null 
                  ? DateFormat('MMM d, yyyy HH:mm').format(currentProfile.updatedAt!)
                  : 'Never'
              ),
              _buildInfoRow('Profile Completion', '${_calculateProfileCompletion()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
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
          
          // Weight Goals Card
          _buildCard(
            title: 'Weight Management',
            icon: Icons.trending_up,
            children: [
              _buildInfoRow('Current Weight', '${currentProfile.weight?.toStringAsFixed(1) ?? 0} kg'),
              _buildInfoRow('Target Weight', '${currentProfile.targetWeight?.toStringAsFixed(1) ?? 0} kg'),
              _buildInfoRow('Weight Goal', _formatWeightGoal(currentProfile.weightGoal ?? '')),
              _buildInfoRow('Timeline', _formatTimeline(currentProfile.goalTimeline ?? '')),
              const Divider(),
              _buildWeightProgress(),
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
              _buildInfoRow('Location', currentProfile.workoutLocation ?? 'Not specified'),
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: currentProfile.availableEquipment!.length,
                  itemBuilder: (context, index) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getEquipmentIcon(currentProfile.availableEquipment![index]),
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              currentProfile.availableEquipment![index],
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Activity Level Card
          _buildCard(
            title: 'Activity Level',
            icon: Icons.directions_walk,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getActivityColor(currentProfile.activityLevel ?? '').withOpacity(0.2),
                      _getActivityColor(currentProfile.activityLevel ?? '').withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getActivityIcon(currentProfile.activityLevel ?? ''),
                      size: 40,
                      color: _getActivityColor(currentProfile.activityLevel ?? ''),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatActivityLevel(currentProfile.activityLevel ?? ''),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getActivityDescription(currentProfile.activityLevel ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Daily Routine Card
          _buildCard(
            title: 'Daily Routine',
            icon: Icons.schedule,
            children: [
              _buildTimelineItem('Wake Up', currentProfile.wakeupTime ?? 'Not set', Icons.wb_sunny),
              _buildTimelineItem('Bedtime', currentProfile.bedtime ?? 'Not set', Icons.bedtime),
              _buildTimelineItem('Sleep Duration', '${currentProfile.sleepHours ?? 8} hours', Icons.hotel),
              _buildTimelineItem('Workout Frequency', '${currentProfile.workoutFrequency ?? 0} days/week', Icons.fitness_center),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Hydration Card
          _buildCard(
            title: 'Hydration',
            icon: Icons.water_drop,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: (currentProfile.waterIntakeGlasses ?? 0) / 12,
                        strokeWidth: 12,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    Column(
                      children: [
                        const Icon(Icons.water_drop, color: Colors.blue, size: 30),
                        const SizedBox(height: 4),
                        Text(
                          '${currentProfile.waterIntakeGlasses ?? 0}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'glasses/day',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Equivalent to ${currentProfile.waterIntake ?? 2} liters',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper Methods
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

  Widget _buildProgressRow(String label, int current, int target, String unit, Color color) {
    final progress = current / target;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text('$current / $target $unit', style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
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

  Widget _buildTimelineItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
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
          ),
        ],
      ),
    );
  }

  Widget _buildWeightProgress() {
   final currentWeight = currentProfile.weight ?? 0;
   final targetWeight = currentProfile.targetWeight ?? currentWeight;
   final startWeight = currentProfile.startingWeight ?? currentWeight;
   
   final totalChange = (targetWeight - startWeight).abs();
   final currentChange = (currentWeight - startWeight).abs();
   final progress = totalChange > 0 ? (currentChange / totalChange).clamp(0.0, 1.0) : 0.0;
   
   final isLosing = targetWeight < startWeight;
   final progressColor = isLosing ? Colors.green : Colors.orange;
   
   return Column(
     children: [
       Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           _buildWeightStat('Start', startWeight),
           _buildWeightStat('Current', currentWeight),
           _buildWeightStat('Target', targetWeight),
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

 // Utility Methods
 String _formatActivityLevel(String level) {
   final Map<String, String> levels = {
     'sedentary': 'Sedentary',
     'lightly_active': 'Lightly Active',
     'moderately_active': 'Moderately Active',
     'very_active': 'Very Active',
     'extra_active': 'Extra Active',
   };
   return levels[level] ?? level;
 }

 String _getActivityDescription(String level) {
   final Map<String, String> descriptions = {
     'sedentary': 'Little or no exercise',
     'lightly_active': 'Exercise 1-3 days/week',
     'moderately_active': 'Exercise 3-5 days/week',
     'very_active': 'Exercise 6-7 days/week',
     'extra_active': 'Very intense exercise daily',
   };
   return descriptions[level] ?? 'Not specified';
 }

 IconData _getActivityIcon(String level) {
   final Map<String, IconData> icons = {
     'sedentary': Icons.weekend,
     'lightly_active': Icons.directions_walk,
     'moderately_active': Icons.directions_run,
     'very_active': Icons.fitness_center,
     'extra_active': Icons.sports_martial_arts,
   };
   return icons[level] ?? Icons.help_outline;
 }

 Color _getActivityColor(String level) {
   final Map<String, Color> colors = {
     'sedentary': Colors.grey,
     'lightly_active': Colors.lightBlue,
     'moderately_active': Colors.blue,
     'very_active': Colors.orange,
     'extra_active': Colors.red,
   };
   return colors[level] ?? Colors.grey;
 }

 String _getBMICategory(double bmi) {
   if (bmi < 18.5) return 'Underweight';
   if (bmi < 25) return 'Normal weight';
   if (bmi < 30) return 'Overweight';
   return 'Obese';
 }

 Color _getBMIColor(double bmi) {
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

 int _calculateProfileCompletion() {
   int filledFields = 0;
   int totalFields = 35; // Approximate total fields
   
   // Basic info
   if (currentProfile.name.isNotEmpty) filledFields++;
   if (currentProfile.email.isNotEmpty) filledFields++;
   if (currentProfile.age != null) filledFields++;
   if (currentProfile.gender != null) filledFields++;
   if (currentProfile.height != null) filledFields++;
   if (currentProfile.weight != null) filledFields++;
   
   // Goals
   if (currentProfile.primaryGoal != null) filledFields++;
   if (currentProfile.weightGoal != null) filledFields++;
   if (currentProfile.targetWeight != null) filledFields++;
   if (currentProfile.goalTimeline != null) filledFields++;
   
   // Daily targets
   if (currentProfile.dailyStepGoal != null) filledFields++;
   if (currentProfile.sleepHours != null) filledFields++;
   if (currentProfile.waterIntake != null) filledFields++;
   if (currentProfile.workoutFrequency != null) filledFields++;
   if (currentProfile.workoutDuration != null) filledFields++;
   
   // Lifestyle
   if (currentProfile.activityLevel != null) filledFields++;
   if (currentProfile.fitnessLevel != null) filledFields++;
   if (currentProfile.bedtime != null) filledFields++;
   if (currentProfile.wakeupTime != null) filledFields++;
   
   // Lists
   if (currentProfile.sleepIssues?.isNotEmpty ?? false) filledFields++;
   if (currentProfile.dietaryPreferences?.isNotEmpty ?? false) filledFields++;
   if (currentProfile.preferredWorkouts?.isNotEmpty ?? false) filledFields++;
   if (currentProfile.medicalConditions?.isNotEmpty ?? false) filledFields++;
   if (currentProfile.availableEquipment?.isNotEmpty ?? false) filledFields++;
   
   // Additional
   if (currentProfile.workoutLocation != null) filledFields++;
   if (currentProfile.hasTrainer != null) filledFields++;
   
   // Women's health (if applicable)
   if (currentProfile.gender?.toLowerCase() == 'female') {
     totalFields += 5;
     if (currentProfile.hasPeriods != null) filledFields++;
     if (currentProfile.pregnancyStatus != null) filledFields++;
     if (currentProfile.periodTrackingPreference != null) filledFields++;
     if (currentProfile.cycleLength != null) filledFields++;
     if (currentProfile.cycleLengthRegular != null) filledFields++;
   }
   
   return ((filledFields / totalFields) * 100).round();
 }
}