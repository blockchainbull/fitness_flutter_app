// lib/features/home/widgets/compact_water_tracker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/repositories/water_repository.dart';
import 'package:user_onboarding/features/tracking/screens/water_logging_page.dart';

class CompactWaterTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const CompactWaterTracker({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CompactWaterTracker> createState() => _CompactWaterTrackerState();
}

class _CompactWaterTrackerState extends State<CompactWaterTracker> 
    with SingleTickerProviderStateMixin {
  WaterEntry? _todayEntry;
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;

  static const double mlPerGlass = 250.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadTodayEntry();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayEntry() async {
    if (widget.userProfile.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final entry = await WaterRepository.getTodayWaterEntry(widget.userProfile.id!);
      final targetGlasses = widget.userProfile.waterIntakeGlasses ?? 8;
      
      setState(() {
        _todayEntry = entry ?? WaterEntry(
          userId: widget.userProfile.id!,
          date: DateTime.now(),
          glassesConsumed: 0,
          totalMl: 0.0,
          targetMl: targetGlasses * mlPerGlass,
        );
        _isLoading = false;
      });
      
      // Animate the fill
      _fillAnimation = Tween<double>(
        begin: 0.0,
        end: (_todayEntry!.glassesConsumed / targetGlasses).clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _animationController.forward();
    } catch (e) {
      print('Error loading water entry: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _quickAddGlass() async {
    if (_todayEntry == null || _isSaving) return;
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _todayEntry = _todayEntry!.copyWith(
        glassesConsumed: _todayEntry!.glassesConsumed + 1,
        totalMl: (_todayEntry!.glassesConsumed + 1) * mlPerGlass,
        updatedAt: DateTime.now(),
      );
      _isSaving = true;
    });
    
    // Update animation
    final targetGlasses = widget.userProfile.waterIntakeGlasses ?? 8;
    _fillAnimation = Tween<double>(
      begin: _fillAnimation.value,
      end: (_todayEntry!.glassesConsumed / targetGlasses).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
    
    try {
      await WaterRepository.saveWaterEntry(_todayEntry!);
      widget.onUpdate?.call();
    } catch (e) {
      print('Error saving water entry: $e');
      // Revert on error
      setState(() {
        _todayEntry = _todayEntry!.copyWith(
          glassesConsumed: _todayEntry!.glassesConsumed - 1,
          totalMl: (_todayEntry!.glassesConsumed - 1) * mlPerGlass,
        );
      });
    } finally {
      setState(() => _isSaving = false);
    }
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

    final targetGlasses = widget.userProfile.waterIntakeGlasses ?? 8;
    final glassesConsumed = _todayEntry!.glassesConsumed;
    final progress = (glassesConsumed / targetGlasses).clamp(0.0, 1.0);
    final isGoalReached = glassesConsumed >= targetGlasses;

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
                builder: (context) => WaterLoggingPage(
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
                // Water icon with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.water_drop,
                    color: isGoalReached ? Colors.blue : Colors.blue.shade300,
                    size: 24,
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
                            '$glassesConsumed / $targetGlasses glasses',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          if (isGoalReached) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Animated progress bar
                      AnimatedBuilder(
                        animation: _fillAnimation,
                        builder: (context, child) {
                          return Stack(
                            children: [
                              // Background track
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.blue.shade50,
                                ),
                              ),
                              // Filled progress with wave effect
                              Container(
                                height: 8,
                                width: MediaQuery.of(context).size.width * 
                                       _fillAnimation.value * 0.65,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: isGoalReached 
                                        ? [Colors.blue, Colors.blue.shade600]
                                        : [Colors.blue.shade300, Colors.blue.shade400],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    if (_fillAnimation.value > 0)
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                              ),
                              // Water droplets overlay (visual enhancement)
                              if (_fillAnimation.value > 0 && _fillAnimation.value < 1)
                                Positioned(
                                  right: MediaQuery.of(context).size.width * 
                                         (1 - _fillAnimation.value) * 0.65 - 4,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Quick add button
                IconButton(
                  onPressed: _isSaving || isGoalReached ? null : _quickAddGlass,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Icon(
                          Icons.add_circle,
                          color: isGoalReached 
                              ? Colors.grey.shade400 
                              : Colors.blue,
                        ),
                  tooltip: 'Add glass',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}