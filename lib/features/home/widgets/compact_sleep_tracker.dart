import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/features/tracking/screens/sleep_logging_page.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:intl/intl.dart';

class CompactSleepTracker extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback? onUpdate;

  const CompactSleepTracker({
    Key? key,
    required this.userProfile,
    this.onUpdate,
  }) : super(key: key);

  @override
  State<CompactSleepTracker> createState() => _CompactSleepTrackerState();
}

class _CompactSleepTrackerState extends State<CompactSleepTracker> {
  final ApiService _apiService = ApiService();
  double _lastNightHours = 0;
  String _sleepQuality = '';
  bool _isLoading = true;
  late double _sleepGoal;

  @override
  void initState() {
    super.initState();
    _initializeSleepGoal();
    _loadSleepData();
  }

  void _initializeSleepGoal() {
    // Get sleep goal from user profile
    // Check various possible fields where sleep goal might be stored
    if (widget.userProfile.sleepHours != null) {
      _sleepGoal = widget.userProfile.sleepHours!.toDouble();
    } else {
      // Default fallback if no sleep goal is set in profile
      _sleepGoal = 8.0;
    }
    
    // Ensure sleep goal is reasonable (between 4 and 12 hours)
    _sleepGoal = _sleepGoal.clamp(4.0, 12.0);
  }

  @override
  void didUpdateWidget(CompactSleepTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _initializeSleepGoal();
      _loadSleepData();
    }
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    _sleepGoal = widget.userProfile.sleepHours ?? 8.0;
    
    try {
      // Check for today's sleep first (if already logged)
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      
      var sleepLog = await _apiService.getSleepEntryByDate(
        widget.userProfile.id, todayStr);
      
      // If no entry for today, check yesterday
      if (sleepLog == null || sleepLog['entry'] == null) {
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
        sleepLog = await _apiService.getSleepEntryByDate(
          widget.userProfile.id, yesterdayStr);
      }
      
      // Parse the response correctly
      if (sleepLog != null && sleepLog['success'] == true && sleepLog['entry'] != null) {
        final entry = sleepLog['entry'];
        
        // Use the correct field names from your API
        _lastNightHours = (entry['total_hours'] as num?)?.toDouble() ?? 0;
        
        // Convert quality_score (0.0-1.0) to quality string
        final qualityScore = (entry['quality_score'] as num?)?.toDouble() ?? 0;
        _sleepQuality = _getQualityFromScore(qualityScore);
        
        print('Loaded sleep data: ${_lastNightHours} hours, quality: $_sleepQuality');
      } else {
        _lastNightHours = 0;
        _sleepQuality = '';
      }
    } catch (e) {
      print('Error loading sleep data: $e');
      _lastNightHours = 0;
      _sleepQuality = '';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getQualityFromScore(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.7) return 'Good';
    if (score >= 0.5) return 'Fair';
    return 'Poor';
  }

  void _navigateToSleepLogging() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepLoggingPage(
          userProfile: widget.userProfile,
        ),
      ),
    ).then((_) {
      _loadSleepData();
      widget.onUpdate?.call();
    });
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getQualityIcon(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'fair':
        return Icons.sentiment_neutral;
      case 'poor':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.bedtime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_lastNightHours / _sleepGoal).clamp(0.0, 1.0);
    final bool goalMet = _lastNightHours >= _sleepGoal;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B68EE),
            const Color(0xFF9D88F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToSleepLogging,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sleep Tracker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Goal: ${_sleepGoal.toStringAsFixed(0)} hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_sleepQuality.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getQualityColor(_sleepQuality).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getQualityIcon(_sleepQuality),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Last night's sleep
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last Night',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _lastNightHours > 0 
                                  ? '${_lastNightHours.toStringAsFixed(1)} hrs'
                                  : 'Not logged',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (_lastNightHours > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              goalMet ? Colors.green : Colors.orange,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sleep quality or prompt to log
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_lastNightHours > 0 && _sleepQuality.isNotEmpty) ...[
                        Icon(
                          _getQualityIcon(_sleepQuality),
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Quality: $_sleepQuality',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Track your sleep for insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Log button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToSleepLogging,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(_lastNightHours > 0 ? 'Update Sleep' : 'Log Sleep'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7B68EE),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}