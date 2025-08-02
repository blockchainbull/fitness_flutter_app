// lib/features/home/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/home/screens/dashboard_home.dart';
import 'package:user_onboarding/features/home/screens/weight_loss_home.dart';
import 'package:user_onboarding/features/home/screens/weight_gain_home.dart';
import 'package:user_onboarding/features/home/screens/muscle_gain_home.dart';
import 'package:user_onboarding/features/home/screens/custom_home.dart';
import 'package:user_onboarding/features/chat/screens/chat_page.dart';
import 'package:user_onboarding/features/profile/screens/profile_page.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  final UserProfile userProfile;
  
  const HomePage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late PageController _pageController;
  String? _overrideHomeType;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Build developer controls for testing different home screens
  Widget _buildDeveloperControls() {
    if (!kDebugMode) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.yellow[100],
      child: Column(
        children: [
          const Text(
            'Developer Controls', 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildDevButton('Dashboard', 'dashboard'),
              _buildDevButton('Weight Loss', 'weight_loss'),
              _buildDevButton('Weight Gain', 'weight_gain'),
              _buildDevButton('Muscle Gain', 'muscle_gain'),
              _buildDevButton('Custom', 'custom'),
              _buildDevButton('Reset', null),
            ],
          ),
          if (_overrideHomeType != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Currently showing: ${_overrideHomeType?.replaceAll('_', ' ').toUpperCase()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDevButton(String label, String? type) {
    return ElevatedButton(
      onPressed: () => setState(() => _overrideHomeType = type),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  // Determine which home screen to show based on user goal or override
  String _getHomeType() {
    // If developer override is active, use that
    if (_overrideHomeType != null) {
      return _overrideHomeType!;
    }

    // Otherwise, use the new dashboard as default
    return 'dashboard';
    
    // Previous logic for goal-based homes (commented out for now):
    // final goal = widget.userProfile.primaryGoal?.toLowerCase() ?? '';
    // if (goal.contains('weight') && goal.contains('loss')) {
    //   return 'weight_loss';
    // } else if (goal.contains('weight') && goal.contains('gain')) {
    //   return 'weight_gain';
    // } else if (goal.contains('muscle')) {
    //   return 'muscle_gain';
    // } else {
    //   return 'dashboard'; // Default to new dashboard
    // }
  }

  // Build the appropriate home screen based on determined type
  Widget _buildHomeByGoal() {
    final homeType = _getHomeType();
    
    switch (homeType) {
      case 'dashboard':
        return DashboardHome(userProfile: widget.userProfile);
      case 'weight_loss':
        return WeightLossHome(userProfile: widget.userProfile);
      case 'weight_gain':
        return WeightGainHome(userProfile: widget.userProfile);
      case 'muscle_gain':
        return MuscleGainHome(userProfile: widget.userProfile);
      case 'custom':
        return CustomHome(userProfile: widget.userProfile);
      default:
        return DashboardHome(userProfile: widget.userProfile);
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Developer controls (only visible in debug mode)
          _buildDeveloperControls(),
          
          // Main content with page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                _buildHomeByGoal(),
                ChatPage(userProfile: widget.userProfile),
                ProfilePage(userProfile: widget.userProfile),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}