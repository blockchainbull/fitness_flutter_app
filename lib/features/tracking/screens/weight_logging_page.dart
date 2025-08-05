// lib/features/tracking/screens/weight_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:intl/intl.dart';

class WeightLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const WeightLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<WeightLoggingPage> createState() => _WeightLoggingPageState();
}

class _WeightLoggingPageState extends State<WeightLoggingPage> {
  final TextEditingController _weightController = TextEditingController();
  final List<Map<String, dynamic>> _weightHistory = [
    {
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'weight': 75.2,
      'notes': 'Starting weight',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 23)),
      'weight': 74.8,
      'notes': 'Good progress',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 16)),
      'weight': 74.5,
      'notes': '',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 9)),
      'weight': 74.0,
      'notes': 'Feeling great!',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'weight': 73.7,
      'notes': 'Almost at target',
    },
  ];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double get currentWeight => _weightHistory.isNotEmpty ? _weightHistory.last['weight'] : (widget.userProfile.weight ?? 0);
  double get targetWeight => widget.userProfile.targetWeight ?? 0;
  double get startWeight => _weightHistory.isNotEmpty ? _weightHistory.first['weight'] : (widget.userProfile.weight ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showWeightHistory(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentWeightCard(),
            const SizedBox(height: 20),
            _buildProgressChart(),
            const SizedBox(height: 20),
            _buildGoalProgress(),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildRecentEntries(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeightDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentWeightCard() {
    final weightChange = currentWeight - startWeight;
    final isLoss = weightChange < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Current Weight',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeightStat('Target', '${targetWeight.toStringAsFixed(1)} kg'),
              _buildWeightStat('Change', '${isLoss ? '' : '+'}${weightChange.toStringAsFixed(1)} kg'),
              _buildWeightStat('To Go', '${(targetWeight - currentWeight).abs().toStringAsFixed(1)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
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
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _weightHistory.length,
                itemBuilder: (context, index) {
                  final entry = _weightHistory[index];
                  final weight = entry['weight'] as double;
                  final date = entry['date'] as DateTime;
                  final height = (weight / 80) * 150; // Normalize height
                  
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${weight.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM\ndd').format(date),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress() {
    final progress = (startWeight - currentWeight) / (startWeight - targetWeight);
    final progressPercentage = (progress * 100).clamp(0, 100);
    
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
                  'Goal Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${progressPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start: ${startWeight.toStringAsFixed(1)} kg'),
                Text('Target: ${targetWeight.toStringAsFixed(1)} kg'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final weeklyChange = _weightHistory.length > 1 ? 
        (_weightHistory.last['weight'] - _weightHistory[_weightHistory.length - 2]['weight']) : 0.0;
    final monthlyChange = currentWeight - startWeight;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('Weekly Change', '${weeklyChange >= 0 ? '+' : ''}${weeklyChange.toStringAsFixed(1)} kg', 
                    weeklyChange < 0 ? Colors.green : Colors.red),
                _buildStatColumn('Monthly Change', '${monthlyChange >= 0 ? '+' : ''}${monthlyChange.toStringAsFixed(1)} kg',
                    monthlyChange < 0 ? Colors.green : Colors.red),
                _buildStatColumn('BMI', _calculateBMI().toStringAsFixed(1), Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentEntries() {
    final recentEntries = _weightHistory.reversed.take(3).toList();
    
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
                  'Recent Entries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _showWeightHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...recentEntries.map((entry) => _buildEntryTile(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final weight = entry['weight'] as double;
    final notes = entry['notes'] as String;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.monitor_weight, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMM dd').format(date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (notes.isNotEmpty)
                  Text(
                    notes,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBMI() {
    final heightInMeters = (widget.userProfile.height ?? 170) / 100;
    return currentWeight / (heightInMeters * heightInMeters);
  }

  void _showAddWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Weight Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_weightController.text.isNotEmpty) {
                setState(() {
                  _weightHistory.add({
                    'date': DateTime.now(),
                    'weight': double.parse(_weightController.text),
                    'notes': '',
                  });
                });
                _weightController.clear();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Weight entry added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showWeightHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Weight History'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _weightHistory.reversed.length,
            itemBuilder: (context, index) {
              final entry = _weightHistory.reversed.toList()[index];
              return _buildEntryTile(entry);
            },
          ),
        ),
      ),
    );
  }
}