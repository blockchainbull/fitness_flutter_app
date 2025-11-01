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
    try {
      setState(() => _isLoading = true);
      
      final cycleLength = widget.userProfile.cycleLength ?? 28;
      
      final history = await PeriodRepository.getPeriodHistory(
        widget.userProfile.id ?? '',
        limit: 12,
      );
      
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
      _loadPeriodData();
      widget.onUpdate?.call();
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
              color: (_isOnPeriod ? const Color(0xFFE91E63) : Colors.purple)
                  .withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isOnPeriod ? Icons.water_drop : Icons.favorite_border,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Text(
              'Period Tracker',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              _isOnPeriod
                  ? 'Day ${DateTime.now().difference(_currentPeriod!.startDate).inDays + 1} of period'
                  : 'Day $_cycleDay of cycle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isOnPeriod
                    ? 'Period in progress'
                    : _isFertileWindow
                        ? 'Fertile window'
                        : _nextPeriodDate != null
                            ? 'Next in ${_nextPeriodDate!.difference(DateTime.now()).inDays} days'
                            : 'Tap to start tracking',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}