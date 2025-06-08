// lib/features/onboarding/screens/onboarding_flow.dart

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/connectivity_service.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/features/home/screens/home_page.dart';
import 'package:user_onboarding/features/onboarding/screens/basic_info_page.dart';
import 'package:user_onboarding/features/onboarding/screens/sleep_info_page.dart';
import 'package:user_onboarding/features/onboarding/screens/weight_goal_page.dart';
import 'package:user_onboarding/features/onboarding/screens/primary_goal_page.dart';
import 'package:user_onboarding/features/onboarding/screens/exercise_setup_page.dart';
import 'package:user_onboarding/features/onboarding/screens/dietary_preferences_page.dart';
import 'package:user_onboarding/features/onboarding/screens/workout_preferences_page.dart';


class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  // Form data
  final _formData = {
    'name': '',
    'email': '',
    'gender': '',
    'age': 0,
    'height': 0.0,
    'weight': 0.0,
    'activityLevel': '',
    'primaryGoal': '',
    'weightGoal': '',
    'targetWeight': 0.0,
     'goalTimeline': '',
    'sleepHours': 7.0,
    'bedtime': '',
    'wakeupTime': '',
    'sleepIssues': <String>[],
    'dietaryPreferences': <String>[],
    'waterIntake': 2.0,
    'medicalConditions': <String>[],
    'otherMedicalCondition': '',
    'preferredWorkouts': <String>[],
    'workoutFrequency': 3,
    'workoutDuration': 30,
    'workoutLocation': '',
    'availableEquipment': <String>[],
    'fitnessLevel': 'Beginner',
    'hasTrainer': false,
  };

  final DataManager _dataManager = DataManager();
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Check connectivity when the widget is initialized
    _checkConnectivity();
    // Listen to connectivity changes
    _setupConnectivityListener();
  }

  void _checkConnectivity() async {
    final isConnected = await _connectivityService.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  void _setupConnectivityListener() {
    _connectivityService.setupConnectivityListener((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit form data and navigate to home screen
      _submitFormData();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitFormData() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    
    try {
      // Convert form data to unified onboarding format
      final onboardingData = {
        'basicInfo': {
          'name': _formData['name'],
          'email': _formData['email'],
          'password': 'defaultpassword123', // You might want to add a password field to your form
          'gender': _formData['gender'],
          'age': _formData['age'],
          'height': _formData['height'],
          'weight': _formData['weight'],
          'activityLevel': _formData['activityLevel'],
          'bmi': _formData['bmi'] ?? 0.0,
          'bmr': _formData['bmr'] ?? 0.0,
          'tdee': _formData['tdee'] ?? 0.0,
        },
        'primaryGoal': _formData['primaryGoal'],
        'weightGoal': {
          'weightGoal': _formData['weightGoal'],
          'targetWeight': _formData['targetWeight'],
          'timeline': _formData['goalTimeline'] ?? '',
        },
        'sleepInfo': {
          'sleepHours': _formData['sleepHours'],
          'bedtime': _formData['bedtime'],
          'wakeupTime': _formData['wakeupTime'],
          'sleepIssues': _formData['sleepIssues'],
        },
        'dietaryPreferences': {
          'dietaryPreferences': _formData['dietaryPreferences'],
          'waterIntake': _formData['waterIntake'],
          'medicalConditions': _formData['medicalConditions'],
          'otherCondition': _formData['otherMedicalCondition'],
        },
        'workoutPreferences': {
          'workoutTypes': _formData['preferredWorkouts'],
          'frequency': _formData['workoutFrequency'],
          'duration': _formData['workoutDuration'],
        },
        'exerciseSetup': {
          'workoutLocation': _formData['workoutLocation'],
          'equipment': _formData['availableEquipment'],
          'fitnessLevel': _formData['fitnessLevel'],
          'hasTrainer': _formData['hasTrainer'],
        },
      };

      print('🌙 Final sleep data being sent:');
      print('  sleepHours: ${_formData['sleepHours']}');
      print('  bedtime: ${_formData['bedtime']}');
      print('  wakeupTime: ${_formData['wakeupTime']}');
      print('  sleepIssues: ${_formData['sleepIssues']}');

      // Complete onboarding using the new unified format
      final userId = await _dataManager.completeOnboarding(onboardingData);
      
      if (userId == null) {
        throw Exception('Failed to complete onboarding');
      }

      // Create UserProfile object for navigation
      final userProfile = UserProfile.fromMap(_formData);
      
      // Close loading indicator
      Navigator.pop(context);
      
      // Show connectivity warning if offline
      if (!_isConnected) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Offline Mode'),
              content: const Text(
                'You are currently offline. Your data has been saved locally and will be synchronized with the server when you reconnect to the internet.'
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      
      // Show success dialog and navigate
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'You\'re all set!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Thank you for providing your information. Your personalized health journey is ready!',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    // Navigate to home screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(userProfile: userProfile),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      // Close loading indicator
      Navigator.pop(context);
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to create profile: $error'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Try Again'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Connectivity indicator
            if (!_isConnected)
              Container(
                width: double.infinity,
                color: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, size: 16, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      'Offline Mode - Data will be saved locally',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  BasicInfoPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  PrimaryHealthGoalPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  WeightGoalPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  SleepInfoPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  DietaryPreferencesPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  WorkoutPreferencesPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                  CurrentExerciseSetupPage(
                    formData: _formData,
                    onDataChanged: (key, value) {
                      setState(() {
                        _formData[key] = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _previousPage,
                          child: const Text('Back'),
                        )
                      : const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage < _totalPages - 1 ? 'Next' : 'Finish'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}