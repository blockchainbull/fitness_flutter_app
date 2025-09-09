// lib/features/home/widgets/compact_period_tracker.dart

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/repositories/period_repository.dart';
import 'package:user_onboarding/features/tracking/screens/period_logging_page.dart';
import 'package:intl/intl.dart';

class CompactPeriodTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const CompactPeriodTracker({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CompactPeriodTracker> createState() => _CompactPeriodTrackerState();
}

class _CompactPeriodTrackerState extends State<CompactPeriodTracker> {
  PeriodEntry? _currentPeriod;
  List<PeriodEntry> _periodHistory = [];
  bool _isLoading = true;
  
  int _cycleDay = 1;
  DateTime? _nextPeriodDate;
  bool _isOnPeriod = false;
  bool _isFertileWindow = false;

  @override
  void initState() {
    super.initState();
    _loadPeriodData();
  }

  Future<void> _loadPeriodData() async {
    if (widget.userProfile.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load period history
      final history = await PeriodRepository.getPeriodHistory(
        widget.userProfile.id!,
        limit: 3,
      );
      
      // Check for current period
      final currentPeriod = await PeriodRepository.getCurrentPeriod(
        widget.userProfile.id!,
      );
      
      setState(() {
        _periodHistory = history;
        _currentPeriod = currentPeriod;
        _isOnPeriod = currentPeriod != null;
        
        // Calculate cycle day and predictions
        _calculateCycleInfo();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading period data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculateCycleInfo() {
    final cycleLength = widget.userProfile.cycleLength ?? 28;
    final periodLength = widget.userProfile.periodLength ?? 5;
    
    if (_isOnPeriod && _currentPeriod != null) {
      // Currently on period
      _cycleDay = DateTime.now().difference(_currentPeriod!.startDate).inDays + 1;
      _nextPeriodDate = _currentPeriod!.startDate.add(Duration(days: cycleLength));
    } else if (_periodHistory.isNotEmpty) {
      // Calculate based on last period
      final lastPeriod = _periodHistory.first;
      _cycleDay = DateTime.now().difference(lastPeriod.startDate).inDays + 1;
      _nextPeriodDate = lastPeriod.startDate.add(Duration(days: cycleLength));
      
      // Check if in fertile window (typically days 10-16 of cycle)
      _isFertileWindow = _cycleDay >= 10 && _cycleDay <= 16;
    } else if (widget.userProfile.lastPeriodDate != null) {
      // Use profile data if no history
      _cycleDay = DateTime.now().difference(widget.userProfile.lastPeriodDate!).inDays + 1;
      _nextPeriodDate = widget.userProfile.lastPeriodDate!.add(Duration(days: cycleLength));
    } else {
      // No data available
      _cycleDay = 1;
      _nextPeriodDate = DateTime.now().add(Duration(days: cycleLength));
    }
  }

  Future<void> _quickLogPeriod() async {
    if (_isOnPeriod && _currentPeriod != null) {
      // End current period
      await _endPeriod();
    } else {
      // Start new period
      await _startPeriod();
    }
  }

  Future<void> _startPeriod() async {
    try {
      final newPeriod = PeriodEntry(
        userId: widget.userProfile.id!,
        startDate: DateTime.now(),
        flowIntensity: 'Medium',
        symptoms: [],
        mood: null,
      );
      
      await PeriodRepository.savePeriodEntry(newPeriod);
      await _loadPeriodData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Period started!'),
            backgroundColor: Color(0xFFE91E63),
          ),
        );
      }
      
      widget.onUpdate?.call();
    } catch (e) {
      print('Error starting period: $e');
    }
  }

  Future<void> _endPeriod() async {
    if (_currentPeriod == null) return;
    
    try {
      final updatedPeriod = _currentPeriod!.copyWith(
        endDate: DateTime.now(),
      );
      
      await PeriodRepository.savePeriodEntry(updatedPeriod);
      await _loadPeriodData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Period ended!'),
            backgroundColor: Color(0xFFE91E63),
          ),
        );
      }
      
      widget.onUpdate?.call();
    } catch (e) {
      print('Error ending period: $e');
    }
  }

  Color _getStatusColor() {
    if (_isOnPeriod) return const Color(0xFFE91E63);
    if (_isFertileWindow) return Colors.purple;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isOnPeriod) return Icons.water_drop;
    if (_isFertileWindow) return Icons.favorite;
    return Icons.circle_outlined;
  }

  String _getStatusText() {
    if (_isOnPeriod) {
      return 'Day ${_cycleDay} of period';
    } else if (_isFertileWindow) {
      return 'Fertile window';
    } else if (_nextPeriodDate != null) {
      final daysUntil = _nextPeriodDate!.difference(DateTime.now()).inDays;
      if (daysUntil <= 7 && daysUntil > 0) {
        return 'Period in $daysUntil days';
      }
    }
    return 'Day $_cycleDay of cycle';
  }

  @override
  Widget build(BuildContext context) {
    // Fixed: Check if hasPeriods is true (handle nullable properly)
    if (widget.userProfile.hasPeriods != true) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE91E63),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PeriodLoggingPage(
                  userProfile: widget.userProfile,
                ),
              ),
            ).then((_) => _loadPeriodData());
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _getStatusColor(),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Period Tracker',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Day $_cycleDay',
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Status Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusText(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_nextPeriodDate != null && !_isOnPeriod)
                            Text(
                              'Next: ${DateFormat('MMM d').format(_nextPeriodDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Quick Action Button
                    ElevatedButton(
                      onPressed: _quickLogPeriod,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOnPeriod 
                            ? Colors.grey[400]
                            : const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isOnPeriod ? 'End' : 'Start',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Quick Symptoms (if on period)
                if (_isOnPeriod) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'How are you feeling?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to log →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Recent History Preview
                if (!_isOnPeriod && _periodHistory.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last: ${DateFormat('MMM d').format(_periodHistory.first.startDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_periodHistory.first.endDate != null) ...[
                        Text(
                          ' (${_periodHistory.first.endDate!.difference(_periodHistory.first.startDate).inDays + 1} days)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}