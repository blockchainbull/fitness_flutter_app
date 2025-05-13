// lib/features/home/widgets/water_tracker.dart

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class WaterTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onWaterUpdated;
  
  const WaterTracker({
    Key? key,
    required this.userProfile,
    this.onWaterUpdated,
  }) : super(key: key);
  
  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> with SingleTickerProviderStateMixin {
  late int _waterGoal;
  late int _waterConsumed;
  bool _isUpdating = false;
  
  // Animation controller for the adding glass effect
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    // Get water intake goal and consumed values from user profile or use defaults
    _waterGoal = 10; // Default goal of 10 glasses
    _waterConsumed = 0; // Start with 0 consumed
    
    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Load data from user profile
    _loadWaterData();
  }
  
  void _loadWaterData() {
    // If a water intake record for today exists, load it
    // For now, we'll just use the waterConsumed field from UserProfile
    // In a real app, you might want to store daily water records
    setState(() {
      _waterConsumed = widget.userProfile.waterIntake.toInt();
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _addWaterGlass() async {
    if (_isUpdating || _waterConsumed >= _waterGoal) return;
    
    setState(() {
      _isUpdating = true;
    });
    
    // Play animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    try {
      // Update local state
      setState(() {
        _waterConsumed += 1;
      });
      
      // Update user profile
      final updatedProfile = widget.userProfile.copyWith(
        waterIntake: _waterConsumed.toDouble(),
      );
      
      // Save to database
      final dataManager = DataManager();
      await dataManager.updateUserProfile(updatedProfile);
      
      // Notify parent if needed
      if (widget.onWaterUpdated != null) {
        widget.onWaterUpdated!();
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update water intake: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Rollback if failed
      setState(() {
        _waterConsumed -= 1;
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final progress = (_waterConsumed / _waterGoal).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Water Intake',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$_waterConsumed/$_waterGoal glasses',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: 10,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Foreground progress
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 10,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Water drop icons
          Center(
            child: Wrap(
              spacing: 8,
              children: List.generate(_waterGoal, (index) {
                bool isFilled = index < _waterConsumed;
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Apply scale animation only to the latest filled drop
                    final shouldAnimate = index == _waterConsumed - 1 && _isUpdating;
                    final scale = shouldAnimate ? _scaleAnimation.value : 1.0;
                    
                    return Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.water_drop,
                        color: isFilled 
                            ? Colors.blue 
                            : Colors.blue.withOpacity(0.2),
                        size: 24,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          
          const SizedBox(height: 20),
          // Add glass button
          Center(
            child: ElevatedButton.icon(
              onPressed: _waterConsumed < _waterGoal ? _addWaterGlass : null,
              icon: const Icon(Icons.add, size: 16),
              label: Text(_waterConsumed < _waterGoal ? 'Add Glass' : 'Goal Completed!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          
          // Reset button (optional - you might want to add this)
          if (_waterConsumed > 0)
            Center(
              child: TextButton(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldReset = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset Water Intake'),
                      content: const Text('Are you sure you want to reset your water intake for today?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldReset == true) {
                    setState(() {
                      _waterConsumed = 0;
                    });
                    
                    // Update user profile
                    final updatedProfile = widget.userProfile.copyWith(
                      waterIntake: 0.0,
                    );
                    
                    // Save to database
                    final dataManager = DataManager();
                    await dataManager.updateUserProfile(updatedProfile);
                    
                    // Notify parent if needed
                    if (widget.onWaterUpdated != null) {
                      widget.onWaterUpdated!();
                    }
                  }
                },
                child: const Text('Reset'),
              ),
            ),
        ],
      ),
    );
  }
}