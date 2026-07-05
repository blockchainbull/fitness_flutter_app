// lib/data/services/step_counter_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';

class StepCounterService extends ChangeNotifier {
  // Singleton pattern
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  // Pedometer streams
  StreamSubscription<StepCount>? _stepCountStream;
  
  // State
  bool _isListening = false;
  bool _hasPermission = false;
  bool _isPedometerAvailable = false;
  int _todaySteps = 0;
  DateTime _lastResetDate = DateTime.now();
  
  // Getters
  bool get isListening => _isListening;
  bool get hasPermission => _hasPermission;
  bool get isPedometerAvailable => _isPedometerAvailable;
  int get todaySteps => _todaySteps;

  // Initialize the service
  Future<void> initialize(String userId) async {
    print('📱 Initializing StepCounterService for user: $userId');

    // Pedometer & activity-recognition permission have no web implementation,
    // and calling them throws MissingPluginException. Fall back to manual entry.
    if (kIsWeb) {
      _hasPermission = false;
      _isPedometerAvailable = false;
      notifyListeners();
      return;
    }

    // Check if permission is already granted
    _hasPermission = await Permission.activityRecognition.isGranted;
    
    if (_hasPermission) {
      await _startListening(userId);
    } else {
      print('⚠️ Activity recognition permission not granted - using manual tracking');
      _isPedometerAvailable = false;
    }
    
    notifyListeners();
  }

  // Request permission and start listening
  Future<bool> requestPermissionAndStart(String userId) async {
    if (kIsWeb) return false; // No pedometer on web.
    print('🔐 Requesting activity recognition permission...');

    final status = await Permission.activityRecognition.request();
    _hasPermission = status.isGranted;
    
    if (_hasPermission) {
      print('✅ Permission granted - starting pedometer');
      await _startListening(userId);
      return true;
    } else if (status.isPermanentlyDenied) {
      print('❌ Permission permanently denied');
      return false;
    } else {
      print('⚠️ Permission denied');
      return false;
    }
  }

  // Start listening to pedometer
  Future<void> _startListening(String userId) async {
    if (kIsWeb) return; // Pedometer stream is unavailable on web.
    if (_isListening) {
      print('⚠️ Already listening to pedometer');
      return;
    }

    try {
      print('🚶 Starting pedometer listeners...');
      
      // Load last known step count and reset date
      await _loadLastKnownState();
      
      // Listen to step count stream
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _onStepCount(event, userId);
        },
        onError: _onStepCountError,
      );

      _isListening = true;
      _isPedometerAvailable = true;
      
      print('✅ Pedometer listeners started successfully');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error starting pedometer: $e');
      _isPedometerAvailable = false;
      _isListening = false;
      notifyListeners();
    }
  }

  // Handle step count updates
  void _onStepCount(StepCount event, String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(_lastResetDate.year, _lastResetDate.month, _lastResetDate.day);
    
    // Check if it's a new day
    if (!_isSameDay(today, lastReset)) {
      print('📅 New day detected - resetting step count');
      await _resetDailySteps(userId);
      _lastResetDate = now;
      await _saveLastKnownState(0);
    }
    
    // Calculate today's steps
    final prefs = await SharedPreferences.getInstance();
    final baseSteps = prefs.getInt('pedometer_base_steps_$userId') ?? event.steps;
    _todaySteps = event.steps - baseSteps;
    
    if (_todaySteps < 0) {
      // Handle pedometer reset (phone restart, etc.)
      print('⚠️ Negative step count detected - resetting base');
      await prefs.setInt('pedometer_base_steps_$userId', event.steps);
      _todaySteps = 0;
    }
    
    print('👣 Steps updated: $_todaySteps (total: ${event.steps}, base: $baseSteps)');
    
    // Save to database periodically (every 100 steps)
    if (_todaySteps % 100 == 0 || _todaySteps < 100) {
      await _syncStepsToDatabase(userId);
    }
    
    await _saveLastKnownState(_todaySteps);
    notifyListeners();
  }

  // Handle step count errors
  void _onStepCountError(error) {
    print('❌ Step count stream error: $error');
    _isPedometerAvailable = false;
    _isListening = false;
    notifyListeners();
  }

  // Sync steps to database
  Future<void> _syncStepsToDatabase(String userId) async {
    try {
      final today = DateTime.now();
      final entry = await StepRepository.getTodayStepEntry(userId);
      
      if (entry != null) {
        // Update existing entry
        final updatedEntry = entry.copyWith(
          steps: _todaySteps,
          sourceType: 'health_app',
          lastSynced: DateTime.now(),
        );
        await StepRepository.saveStepEntry(updatedEntry);
      } else {
        // Create new entry
        final newEntry = StepEntry(
          userId: userId,
          date: today,
          steps: _todaySteps,
          goal: 10000, // Default goal
          sourceType: 'health_app',
        );
        await StepRepository.saveStepEntry(newEntry);
      }
      
      print('💾 Steps synced to database: $_todaySteps');
    } catch (e) {
      print('❌ Error syncing steps to database: $e');
    }
  }

  // Reset daily steps for new day
  Future<void> _resetDailySteps(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The base will be set on next step count update
      await prefs.remove('pedometer_base_steps_$userId');
      _todaySteps = 0;
      print('🔄 Daily steps reset');
    } catch (e) {
      print('❌ Error resetting daily steps: $e');
    }
  }

  // Save last known state
  Future<void> _saveLastKnownState(int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_known_steps', steps);
      await prefs.setString('last_reset_date', _lastResetDate.toIso8601String());
    } catch (e) {
      print('❌ Error saving last known state: $e');
    }
  }

  // Load last known state
  Future<void> _loadLastKnownState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _todaySteps = prefs.getInt('last_known_steps') ?? 0;
      
      final lastResetStr = prefs.getString('last_reset_date');
      if (lastResetStr != null) {
        _lastResetDate = DateTime.parse(lastResetStr);
      }
      
      print('📂 Loaded last known state: $_todaySteps steps');
    } catch (e) {
      print('❌ Error loading last known state: $e');
    }
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Stop listening to pedometer
  void stopListening() {
    print('🛑 Stopping pedometer listeners');
    _stepCountStream?.cancel();
    _stepCountStream = null;
    _isListening = false;
    notifyListeners();
  }

  // Force sync current steps to database
  Future<void> forceSync(String userId) async {
    if (_hasPermission && _isPedometerAvailable) {
      await _syncStepsToDatabase(userId);
    }
  }

  // Get current step count (either from pedometer or database)
  Future<int> getCurrentStepCount(String userId) async {
    if (_hasPermission && _isPedometerAvailable && _isListening) {
      return _todaySteps;
    } else {
      // Fall back to manual tracking from database
      final entry = await StepRepository.getTodayStepEntry(userId);
      return entry?.steps ?? 0;
    }
  }

  // Dispose
  void dispose() {
    stopListening();
    super.dispose();
  }
}