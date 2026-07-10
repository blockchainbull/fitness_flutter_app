// lib/features/home/widgets/weekly_stats_card.dart

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api/chat_api.dart';
import 'package:user_onboarding/features/reports/screens/weekly_summary_screen.dart';

class WeeklyStatsCard extends StatefulWidget {
  final String userId;
  final UserProfile userProfile; // Add this
  
  const WeeklyStatsCard({
    Key? key,
    required this.userId,
    required this.userProfile, // Add this
  }) : super(key: key);

  @override
  State<WeeklyStatsCard> createState() => _WeeklyStatsCardState();
}

class _WeeklyStatsCardState extends State<WeeklyStatsCard> {
  final ChatApi _apiService = ChatApi();
  Map<String, dynamic>? _weeklyData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    // /weekly/context is a heavy server-side aggregation that can take 15–30s.
    // Kick it off immediately so it starts as early as possible and fills in
    // when it returns.
    _loadWeeklyStats();
  }
  
  Future<void> _loadWeeklyStats() async {
    try {
      // /weekly/context is a heavy aggregation and routinely takes 15–30s, so
      // allow a generous timeout rather than giving up early and leaving a
      // blank card. If it still fails we hide the card (see build()).
      final data = await _apiService
          .getWeeklyContext(widget.userId)
          .timeout(const Duration(seconds: 45));
      if (mounted) {
        setState(() {
          _weeklyData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weekly stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: 12),
                Text(
                  "Loading this week's summary…",
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_weeklyData == null || !_weeklyData!['success']) {
      return const SizedBox.shrink();
    }
    
    final summary = _weeklyData!['summary'] ?? {};
    final weekContext = _weeklyData!['weekly_context'] ?? {};
    final goalsProgress = weekContext['goals_progress'] ?? {};
    
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeeklySummaryScreen(
                userProfile: widget.userProfile,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Week\'s Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    'Calories',
                    '${summary['avg_calories'] ?? 0}',
                    _getProgressColor(goalsProgress['calorie_goal_achievement'] ?? 0),
                  ),
                  _buildMiniStat(
                    'Workouts',
                    '${summary['total_workouts'] ?? 0}',
                    _getProgressColor(goalsProgress['workout_goal_achievement'] ?? 0),
                  ),
                  _buildMiniStat(
                    'Sleep',
                    '${summary['avg_sleep'] ?? 0}h',
                    _getProgressColor(
                      summary['avg_sleep'] != null && summary['avg_sleep'] >= 7 
                        ? 100 
                        : (summary['avg_sleep'] ?? 0) * 14.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (goalsProgress['calorie_goal_achievement'] ?? 0) / 100,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(goalsProgress['calorie_goal_achievement'] ?? 0),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${goalsProgress['calorie_goal_achievement'] ?? 0}% goal achievement',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Color _getProgressColor(num percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}