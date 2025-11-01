// lib/features/home/widgets/compact_step_tracker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';
import 'package:user_onboarding/features/tracking/screens/steps_logging_page.dart';

class CompactStepTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const CompactStepTracker({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CompactStepTracker> createState() => _CompactStepTrackerState();
}

class _CompactStepTrackerState extends State<CompactStepTracker> 
    with SingleTickerProviderStateMixin {
  StepEntry? _todayEntry;
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;
  final TextEditingController _quickAddController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadTodayEntry();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayEntry() async {
    if (widget.userProfile.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final entry = await StepRepository.getTodayStepEntry(widget.userProfile.id!);
      final stepGoal = widget.userProfile.dailyStepGoal ?? 
                      (widget.userProfile.dailyStepGoal as int?) ?? 
                      10000;
      
      setState(() {
        _todayEntry = entry ?? StepEntry(
          userId: widget.userProfile.id!,
          date: DateTime.now(),
          steps: 0,
          goal: stepGoal,
          sourceType: 'manual',
        );
        _isLoading = false;
      });
      
      // Start the animation (it goes from 0 to 1)
      _animationController.forward();
    } catch (e) {
      print('Error loading step entry: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showQuickAddDialog() {
    _quickAddController.text = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Add Steps'),
        content: TextField(
          controller: _quickAddController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter steps to add',
            prefixIcon: const Icon(Icons.add),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _quickAddSteps(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _quickAddSteps,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _quickAddSteps() async {
    final stepsToAdd = int.tryParse(_quickAddController.text);
    if (stepsToAdd == null || stepsToAdd <= 0) return;
    
    Navigator.pop(context); // Close dialog
    
    if (_todayEntry == null || _isSaving) return;
    
    HapticFeedback.lightImpact();
    
    final newSteps = _todayEntry!.steps + stepsToAdd;
    
    setState(() {
      _todayEntry = _todayEntry!.copyWith(
        steps: newSteps,
        updatedAt: DateTime.now(),
      );
      _isSaving = true;
    });
    
    // Update animation
    _fillAnimation = Tween<double>(
      begin: _fillAnimation.value,
      end: (newSteps / _todayEntry!.goal).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
    
    try {
      await StepRepository.saveStepEntry(_todayEntry!);
      widget.onUpdate?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $stepsToAdd steps!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving step entry: $e');
      // Revert on error
      setState(() {
        _todayEntry = _todayEntry!.copyWith(
          steps: _todayEntry!.steps - stepsToAdd,
        );
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_todayEntry == null) return const SizedBox.shrink();

    final steps = _todayEntry!.steps;
    final goal = _todayEntry!.goal;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final isGoalReached = steps >= goal;
    final formatter = NumberFormat('#,###');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StepsLoggingPage(
                  userProfile: widget.userProfile,
                ),
              ),
            ).then((_) => _loadTodayEntry());
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Row(
              children: [
                // Step icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: isGoalReached ? Colors.green : Colors.orange.shade400,
                        size: 24,
                      ),
                      if (isGoalReached)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Progress content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${formatter.format(steps)} / ${_formatSteps(goal)} steps',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (isGoalReached) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '🎯 Goal!',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Animated progress bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedBuilder(
                            animation: _fillAnimation,
                            builder: (context, child) {
                              // Calculate the actual fill width based on progress
                              final fillWidth = constraints.maxWidth * progress * _fillAnimation.value;
                              
                              return Stack(
                                children: [
                                  // Background track
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[200],  // Use grey instead of orange.shade50
                                    ),
                                  ),
                                  // Filled progress with gradient
                                  Container(
                                    height: 8,
                                    width: fillWidth,  // Use the calculated fill width
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      gradient: LinearGradient(
                                        colors: isGoalReached 
                                            ? [Colors.green, Colors.green.shade600]
                                            : progress > 0.7
                                                ? [Colors.orange.shade400, Colors.orange.shade500]
                                                : [Colors.orange.shade300, Colors.orange.shade400],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        if (progress > 0)
                                          BoxShadow(
                                            color: (isGoalReached ? Colors.green : Colors.orange)
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Step indicators along the bar (optional - you can remove this if not needed)
                                  if (progress > 0.25 && progress < 1)
                                    ...List.generate(3, (index) {
                                      final indicatorPosition = 0.25 + (index * 0.25);
                                      if (indicatorPosition <= progress) {
                                        return Positioned(
                                          left: constraints.maxWidth * indicatorPosition - 2,
                                          top: 2,
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Quick add button
                IconButton(
                  onPressed: _isSaving ? null : _showQuickAddDialog,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                          ),
                        )
                      : Icon(
                          Icons.add_circle,
                          color: Colors.orange.shade500,
                        ),
                  tooltip: 'Quick add steps',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}