// lib/features/home/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const Text('Developer Controls', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _overrideHomeType = 'weight_loss'),
                child: const Text('Weight Loss'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _overrideHomeType = 'weight_gain'),
                child: const Text('Weight Gain'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _overrideHomeType = 'muscle_gain'),
                child: const Text('Muscle Gain'),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _overrideHomeType = 'custom'),
                child: const Text('Custom'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the home page based on user's primary health goal
  Widget _buildHomeByGoal() {
    if (_overrideHomeType != null) {
      // Developer override is active
      switch (_overrideHomeType) {
        case 'weight_loss':
          return WeightLossHome(userProfile: widget.userProfile);
        case 'weight_gain':
          return WeightGainHome(userProfile: widget.userProfile);
        case 'muscle_gain':
          return MuscleGainHome(userProfile: widget.userProfile);
        case 'custom':
          return CustomHome(userProfile: widget.userProfile);
        default:
          break;
      }
    }
    
    // Normal logic based on user profile
    final primaryGoal = widget.userProfile.primaryGoal.toLowerCase();
    final weightGoal = widget.userProfile.weightGoal.toLowerCase();
    
    if (primaryGoal.contains('lose weight') || weightGoal.contains('lose weight')) {
      return WeightLossHome(userProfile: widget.userProfile);
    } else if (primaryGoal.contains('build muscle') || weightGoal.contains('gain weight')) {
      return WeightGainHome(userProfile: widget.userProfile);
    } else if (primaryGoal.contains('maintain health') || weightGoal.contains('maintain weight')) {
      return MuscleGainHome(userProfile: widget.userProfile);
    } else {
      // Default to custom home for other goals or if no matching goal found
      return CustomHome(userProfile: widget.userProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add the developer controls in debug mode
          if (kDebugMode)
            _buildDeveloperControls(),
          
          // Main content with page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHomeByGoal(),
                const ChatPage(),
                ProfilePage(userProfile: widget.userProfile),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
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