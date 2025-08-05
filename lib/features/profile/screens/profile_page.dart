// lib/features/profile/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/features/profile/screens/edit_profile_page.dart';
import 'package:user_onboarding/features/profile/screens/settings_page.dart';
import 'package:user_onboarding/features/profile/widgets/stat_card.dart';
import 'package:user_onboarding/features/profile/widgets/goal_progress.dart';
import 'package:user_onboarding/features/auth/screens/login_screens.dart';

class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;
  
  const ProfilePage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late UserProfile currentProfile;
  final DataManager _dataManager = DataManager(); // Use DataManager instead of ApiService
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.userProfile;
  }

  Future<void> _refreshProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Use DataManager to load profile instead of direct API call
      final updatedProfile = await _dataManager.loadUserProfile();
      
      if (updatedProfile != null) {
        setState(() {
          currentProfile = updatedProfile;
        });
        print('[ProfilePage] Profile refreshed successfully');
      } else {
        print('[ProfilePage] No updated profile found, keeping current');
      }
    } catch (e) {
      print('[ProfilePage] Error refreshing profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    try {
      print('[ProfilePage] Navigating to edit profile');
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfilePage(userProfile: currentProfile),
        ),
      );
      
      print('[ProfilePage] Returned from edit profile with result: $result');
      
      if (result != null && result is UserProfile) {
        setState(() {
          currentProfile = result;
        });
        print('[ProfilePage] Profile updated from edit page');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('[ProfilePage] Error navigating to edit profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open edit profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToSettings() async {
    try {
      print('[ProfilePage] Navigating to settings');
      
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsPage(userProfile: currentProfile),
        ),
      );
      
      if (result == true) {
        await _refreshProfile();
      }
    } catch (e) {
      print('[ProfilePage] Error navigating to settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Clear user data
        await _dataManager.clearData();
        
        // Navigate to login page and clear the navigation stack
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        print('[ProfilePage] Error during logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildGoalsSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildMenuItems(),
                    const SizedBox(height: 24),
                    _buildLogoutSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.blue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          currentProfile.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue, Colors.blue.shade700],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: _navigateToSettings,
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _navigateToEditProfile, // FIXED: Use the new method
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              currentProfile.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currentProfile.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentProfile.email,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProfileStat('Age', '${currentProfile.age ?? 0}'),
              _buildProfileStat('Height', '${currentProfile.height.toInt()} cm'),
              _buildProfileStat('Weight', '${currentProfile.weight.toInt()} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    // Safe null handling for formData
    final Map<String, dynamic> formData = currentProfile.formData ?? {};
    final double bmi = (formData['bmi'] as num?)?.toDouble() ?? 0.0;
    final double bmr = (formData['bmr'] as num?)?.toDouble() ?? 0.0;
    final double tdee = (formData['tdee'] as num?)?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'BMI',
                value: bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                subtitle: bmi > 0 ? _getBMICategory(bmi) : 'Not calculated',
                icon: Icons.accessibility,
                color: bmi > 0 ? _getBMIColor(bmi) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'BMR',
                value: bmr > 0 ? bmr.toInt().toString() : '--',
                subtitle: 'cal/day',
                icon: Icons.local_fire_department,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatCard(
          title: 'Total Daily Energy',
          value: tdee > 0 ? tdee.toInt().toString() : '--',
          subtitle: 'calories needed per day',
          icon: Icons.energy_savings_leaf,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildGoalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Goals & Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GoalProgress(
          title: currentProfile.primaryGoal ?? 'General Fitness',
          subtitle: currentProfile.weightGoal ?? 'Maintain current weight',
          progress: 0.65, // Mock progress
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _navigateToEditProfile,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _refreshProfile,
            icon: isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          'Account Settings',
          'Manage your account preferences',
          Icons.settings,
          _navigateToSettings,
        ),
        _buildMenuItem(
          'Health Data',
          'View your health metrics and history',
          Icons.health_and_safety,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Health data page coming soon!')),
            );
          },
        ),
        _buildMenuItem(
          'Privacy & Security',
          'Manage your privacy settings',
          Icons.security,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon!')),
            );
          },
        ),
        _buildMenuItem(
          'Help & Support',
          'Get help and contact support',
          Icons.help,
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help page coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLogoutSection() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign out of your account and return to the login screen.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}