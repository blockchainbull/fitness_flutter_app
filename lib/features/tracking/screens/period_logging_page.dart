// lib/features/tracking/screens/period_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:intl/intl.dart';

class PeriodLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const PeriodLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<PeriodLoggingPage> createState() => _PeriodLoggingPageState();
}

class _PeriodLoggingPageState extends State<PeriodLoggingPage> {
  final List<Map<String, dynamic>> _cycleHistory = [
    {
      'start_date': DateTime.now().subtract(const Duration(days: 62)),
      'end_date': DateTime.now().subtract(const Duration(days: 58)),
      'length': 28,
      'flow': 'Medium',
      'symptoms': ['Cramps', 'Bloating'],
    },
    {
      'start_date': DateTime.now().subtract(const Duration(days: 34)),
      'end_date': DateTime.now().subtract(const Duration(days: 30)),
      'length': 29,
      'flow': 'Heavy',
      'symptoms': ['Cramps', 'Headache', 'Mood swings'],
    },
    {
      'start_date': DateTime.now().subtract(const Duration(days: 5)),
      'end_date': DateTime.now().subtract(const Duration(days: 1)),
      'length': 0, // Current cycle
      'flow': 'Light',
      'symptoms': ['Cramps'],
    },
  ];

  final List<String> _symptoms = [
    'Cramps', 'Bloating', 'Headache', 'Mood swings', 'Acne', 
    'Breast tenderness', 'Fatigue', 'Back pain', 'Nausea'
  ];

  final List<String> _moods = [
    'Happy', 'Sad', 'Anxious', 'Irritable', 'Energetic', 'Tired', 'Calm'
  ];

  @override
  Widget build(BuildContext context) {
    final currentCycle = _cycleHistory.last;
    final isOnPeriod = _isCurrentlyOnPeriod();
    final nextPeriodDate = _calculateNextPeriod();
    final cycleDay = _getCurrentCycleDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Period Tracking'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showCycleCalendar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentStatus(isOnPeriod, cycleDay, nextPeriodDate),
            const SizedBox(height: 20),
            _buildCycleOverview(),
            const SizedBox(height: 20),
            _buildSymptomTracker(),
            const SizedBox(height: 20),
            _buildMoodTracker(),
            const SizedBox(height: 20),
            _buildRecentCycles(),
            const SizedBox(height: 20),
            _buildInsights(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLogPeriodDialog,
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentStatus(bool isOnPeriod, int cycleDay, DateTime nextPeriod) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade400, Colors.pink.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isOnPeriod ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            isOnPeriod ? 'Period Day ${_getCurrentPeriodDay()}' : 'Cycle Day $cycleDay',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOnPeriod 
              ? 'Your period is currently active'
              : 'Next period in ${nextPeriod.difference(DateTime.now()).inDays} days',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusStat('Cycle Length', '${_getAverageCycleLength()} days'),
              _buildStatusStat('Period Length', '${_getAveragePeriodLength()} days'),
              _buildStatusStat('Next Period', DateFormat('MMM dd').format(nextPeriod)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCycleOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cycle Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              child: Row(
                children: List.generate(28, (index) {
                  final day = index + 1;
                  final currentDay = _getCurrentCycleDay();
                  final isPeriodDay = day <= 5; // Assuming 5-day period
                  final isCurrentDay = day == currentDay;
                  final isOvulationDay = day == 14;
                  
                  Color color;
                  if (isCurrentDay) {
                    color = Colors.pink;
                  } else if (isPeriodDay) {
                    color = Colors.pink.shade200;
                  } else if (isOvulationDay) {
                    color = Colors.blue.shade200;
                  } else {
                    color = Colors.grey.shade300;
                  }
                  
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: isCurrentDay ? 
                          const Icon(Icons.circle, color: Colors.white, size: 8) :
                          null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Period', Colors.pink.shade200),
                _buildLegendItem('Ovulation', Colors.blue.shade200),
                _buildLegendItem('Today', Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSymptomTracker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptoms.map((symptom) => _buildSymptomChip(symptom)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomChip(String symptom) {
    final isSelected = _cycleHistory.last['symptoms']?.contains(symptom) ?? false;
    
    return GestureDetector(
      onTap: () => _toggleSymptom(symptom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.withOpacity(0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.grey.shade300,
          ),
        ),
        child: Text(
          symptom,
          style: TextStyle(
            color: isSelected ? Colors.pink : Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodTracker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moods.take(4).map((mood) => _buildMoodButton(mood)).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moods.skip(4).map((mood) => _buildMoodButton(mood)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(String mood) {
    return GestureDetector(
      onTap: () => _selectMood(mood),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getMoodIcon(mood),
              color: Colors.pink,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mood,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCycles() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Cycles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _showCycleHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._cycleHistory.reversed.take(3).map((cycle) => _buildCycleTile(cycle)),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleTile(Map<String, dynamic> cycle) {
    final startDate = cycle['start_date'] as DateTime;
    final endDate = cycle['end_date'] as DateTime?;
    final length = cycle['length'] as int;
    final flow = cycle['flow'] as String;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Colors.pink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Started ${DateFormat('MMM dd').format(startDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  endDate != null 
                    ? '${endDate.difference(startDate).inDays + 1} days • $flow flow'
                    : 'Current cycle • $flow flow',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (length > 0)
            Text(
              '${length}d cycle',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    final avgCycleLength = _getAverageCycleLength();
    final avgPeriodLength = _getAveragePeriodLength();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.pink),
                const SizedBox(width: 8),
                const Text(
                  'Cycle Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('• Your average cycle is $avgCycleLength days'),
            Text('• Your period typically lasts $avgPeriodLength days'),
            const Text('• Most common symptoms: Cramps, Bloating'),
            const Text('• Your cycles are fairly regular'),
            const Text('• Consider tracking basal body temperature for better predictions'),
          ],
        ),
      ),
    );
  }

  bool _isCurrentlyOnPeriod() {
    final lastCycle = _cycleHistory.last;
    final startDate = lastCycle['start_date'] as DateTime;
    final endDate = lastCycle['end_date'] as DateTime?;
    final now = DateTime.now();
    
    return endDate == null && now.difference(startDate).inDays < 7;
  }

  int _getCurrentCycleDay() {
    final lastCycle = _cycleHistory.last;
    final startDate = lastCycle['start_date'] as DateTime;
    return DateTime.now().difference(startDate).inDays + 1;
  }

  int _getCurrentPeriodDay() {
    if (!_isCurrentlyOnPeriod()) return 0;
    final lastCycle = _cycleHistory.last;
    final startDate = lastCycle['start_date'] as DateTime;
    return DateTime.now().difference(startDate).inDays + 1;
  }

  DateTime _calculateNextPeriod() {
    final lastCycle = _cycleHistory.last;
    final startDate = lastCycle['start_date'] as DateTime;
    final avgCycleLength = _getAverageCycleLength();
    return startDate.add(Duration(days: avgCycleLength));
  }

  int _getAverageCycleLength() {
    final completedCycles = _cycleHistory.where((c) => c['length'] > 0).toList();
    if (completedCycles.isEmpty) return 28;
    final total = completedCycles.fold<int>(0, (sum, cycle) => sum + (cycle['length'] as int));
    return (total / completedCycles.length).round();
  }

  int _getAveragePeriodLength() {
    final cyclesWithEndDate = _cycleHistory.where((c) => c['end_date'] != null).toList();
    if (cyclesWithEndDate.isEmpty) return 5;
    final total = cyclesWithEndDate.fold<int>(0, (sum, cycle) {
      final start = cycle['start_date'] as DateTime;
      final end = cycle['end_date'] as DateTime;
      return sum + end.difference(start).inDays + 1;
    });
    return (total / cyclesWithEndDate.length).round();
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy': return Icons.sentiment_very_satisfied;
      case 'Sad': return Icons.sentiment_very_dissatisfied;
      case 'Anxious': return Icons.sentiment_dissatisfied;
      case 'Irritable': return Icons.mood_bad;
      case 'Energetic': return Icons.battery_charging_full;
      case 'Tired': return Icons.battery_0_bar;
      case 'Calm': return Icons.sentiment_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      final symptoms = _cycleHistory.last['symptoms'] as List<String>? ?? <String>[];
      if (symptoms.contains(symptom)) {
        symptoms.remove(symptom);
      } else {
        symptoms.add(symptom);
      }
      _cycleHistory.last['symptoms'] = symptoms;
    });
  }

  void _selectMood(String mood) {
    setState(() {
      _cycleHistory.last['mood'] = mood;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mood logged: $mood')),
    );
  }

  void _showLogPeriodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Period'),
        content: const Text('Would you like to start or end your period tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add period start logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Period started!')),
              );
            },
            child: const Text('Start Period'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add period end logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Period ended!')),
              );
            },
            child: const Text('End Period'),
          ),
        ],
      ),
    );
  }

  void _showCycleCalendar() {
    // Navigate to calendar view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cycle calendar coming soon!')),
    );
  }

  void _showCycleHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Cycle History'),
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cycleHistory.reversed.length,
            itemBuilder: (context, index) {
              final cycle = _cycleHistory.reversed.toList()[index];
              return _buildCycleTile(cycle);
            },
          ),
        ),
      ),
    );
  }
}