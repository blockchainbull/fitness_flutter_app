// lib/features/home/widgets/compact_period_tracker.dart

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/repositories/period_repository.dart';
import 'package:user_onboarding/features/tracking/screens/period_logging_page.dart';


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
    try {
      // Check mounted before first setState
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final cycleLength = widget.userProfile.cycleLength ?? 28;
      
      final history = await PeriodRepository.getPeriodHistory(
        widget.userProfile.id ?? '',
        limit: 12,
      );
      
      // Check mounted after async operation
      if (!mounted) return;
      
      setState(() {
        _periodHistory = history;
        
        if (history.isNotEmpty && history.first.endDate == null) {
          _isOnPeriod = true;
          _currentPeriod = history.first;
        } else {
          _isOnPeriod = false;
          _currentPeriod = null;
        }
        
        if (widget.userProfile.lastPeriodDate != null) {
          final daysSinceLastPeriod = DateTime.now()
              .difference(widget.userProfile.lastPeriodDate!)
              .inDays + 1;
          _cycleDay = daysSinceLastPeriod % cycleLength;
          if (_cycleDay == 0) _cycleDay = cycleLength;
          
          _nextPeriodDate = widget.userProfile.lastPeriodDate!
              .add(Duration(days: cycleLength));
          
          // Check if in fertile window (days 10-17 of cycle typically)
          _isFertileWindow = _cycleDay >= (cycleLength - 17) && 
                            _cycleDay <= (cycleLength - 11);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading period data: $e');
      // Check mounted before setState on error
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openPeriodTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PeriodCalendarPage(),
      ),
    ).then((_) {
      // Check if widget is still mounted before reloading
      if (mounted) {
        _loadPeriodData();
        widget.onUpdate?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade50,
              Colors.purple.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE91E63),
            strokeWidth: 2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _openPeriodTracking,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isOnPeriod
                ? [
                    const Color(0xFFE91E63).withOpacity(0.9),
                    const Color(0xFFEC407A).withOpacity(0.9),
                  ]
                : _isFertileWindow
                    ? [
                        Colors.purple.shade400,
                        Colors.purple.shade500,
                      ]
                    : [
                        Colors.pink.shade100,
                        Colors.purple.shade100,
                      ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (_isOnPeriod
                      ? const Color(0xFFE91E63)
                      : _isFertileWindow
                          ? Colors.purple.shade400
                          : Colors.pink.shade200)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isOnPeriod
                          ? Icons.favorite
                          : _isFertileWindow
                              ? Icons.local_florist
                              : Icons.calendar_today,
                      color: _isOnPeriod || _isFertileWindow
                          ? Colors.white
                          : Colors.pink.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isOnPeriod
                          ? 'On Period'
                          : _isFertileWindow
                              ? 'Fertile Window'
                              : 'Period Cycle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isOnPeriod || _isFertileWindow
                            ? Colors.white
                            : Colors.pink.shade900,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _isOnPeriod || _isFertileWindow
                      ? Colors.white
                      : Colors.pink.shade700,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnPeriod
                          ? 'Day ${DateTime.now().difference(_currentPeriod!.startDate).inDays + 1}'
                          : 'Day $_cycleDay',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _isOnPeriod || _isFertileWindow
                            ? Colors.white
                            : Colors.pink.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnPeriod
                          ? 'of current period'
                          : 'of ${widget.userProfile.cycleLength ?? 28}-day cycle',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_isOnPeriod || _isFertileWindow
                                ? Colors.white
                                : Colors.pink.shade700)
                            .withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                if (!_isOnPeriod && _nextPeriodDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (_isFertileWindow
                              ? Colors.white
                              : Colors.pink.shade50)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${_nextPeriodDate!.difference(DateTime.now()).inDays}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _isFertileWindow
                                ? Colors.purple.shade700
                                : Colors.pink.shade900,
                          ),
                        ),
                        Text(
                          'days',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isFertileWindow
                                ? Colors.purple.shade600
                                : Colors.pink.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}