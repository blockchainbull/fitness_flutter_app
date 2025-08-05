// lib/features/tracking/screens/supplements_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:intl/intl.dart';

class SupplementsLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const SupplementsLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<SupplementsLoggingPage> createState() => _SupplementsLoggingPageState();
}

class _SupplementsLoggingPageState extends State<SupplementsLoggingPage> {
  final List<Map<String, dynamic>> _supplements = [
    {
      'name': 'Vitamin D',
      'dosage': '1000 IU',
      'frequency': 'Daily',
      'time': '9:00 AM',
      'taken_today': true,
      'color': Colors.orange,
      'icon': Icons.wb_sunny,
      'notes': 'With breakfast',
    },
    {
      'name': 'Omega-3',
      'dosage': '1000 mg',
      'frequency': 'Daily',
      'time': '9:00 AM',
      'taken_today': true,
      'color': Colors.blue,
      'icon': Icons.water,
      'notes': 'Fish oil capsule',
    },
    {
      'name': 'Multivitamin',
      'dosage': '1 tablet',
      'frequency': 'Daily',
      'time': '9:00 AM',
      'taken_today': false,
      'color': Colors.green,
      'icon': Icons.medication,
      'notes': '',
    },
    {
      'name': 'Magnesium',
      'dosage': '400 mg',
      'frequency': 'Evening',
      'time': '9:00 PM',
      'taken_today': false,
      'color': Colors.purple,
      'icon': Icons.nightlight_round,
      'notes': 'Before bed',
    },
    {
      'name': 'Protein Powder',
      'dosage': '30g',
      'frequency': 'Post-workout',
      'time': 'Variable',
      'taken_today': true,
      'color': Colors.red,
      'icon': Icons.fitness_center,
      'notes': 'After gym',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final takenCount = _supplements.where((s) => s['taken_today'] == true).length;
    final totalCount = _supplements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplements'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSupplementDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodaysSummary(takenCount, totalCount),
            const SizedBox(height: 20),
            _buildSupplementsList(),
            const SizedBox(height: 20),
            _buildWeeklyOverview(),
            const SizedBox(height: 20),
            _buildSupplementTips(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSupplementDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodaysSummary(int taken, int total) {
    final progress = total > 0 ? taken / total : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$taken / $total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryStat('Completed', '$taken'),
              _buildSummaryStat('Remaining', '${total - taken}'),
              _buildSummaryStat('Adherence', '${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSupplementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Supplements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._supplements.map((supplement) => _buildSupplementCard(supplement)),
      ],
    );
  }

  Widget _buildSupplementCard(Map<String, dynamic> supplement) {
    final taken = supplement['taken_today'] as bool;
    final color = supplement['color'] as Color;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: taken ? color.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              supplement['icon'] as IconData,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplement['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${supplement['dosage']} • ${supplement['frequency']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if ((supplement['notes'] as String).isNotEmpty)
                  Text(
                    supplement['notes'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                supplement['time'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _toggleSupplement(supplement),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: taken ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    taken ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final adherenceData = [0.8, 1.0, 0.6, 0.9, 1.0, 0.7, 0.8]; // Mock data
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Adherence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final adherence = adherenceData[index];
                final color = adherence >= 0.8 ? Colors.green : 
                            adherence >= 0.5 ? Colors.orange : Colors.red;
                
                return Column(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: adherence,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      weekDays[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdherenceIndicator('Excellent', Colors.green),
                _buildAdherenceIndicator('Good', Colors.orange),
                _buildAdherenceIndicator('Needs Work', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceIndicator(String label, Color color) {
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
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSupplementTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Supplement Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Take fat-soluble vitamins (A, D, E, K) with meals'),
            const Text('• Space out iron and calcium supplements'),
            const Text('• Set reminders to maintain consistency'),
            const Text('• Store supplements in a cool, dry place'),
            const Text('• Check expiration dates regularly'),
          ],
        ),
      ),
    );
  }

  void _toggleSupplement(Map<String, dynamic> supplement) {
    setState(() {
      supplement['taken_today'] = !(supplement['taken_today'] as bool);
    });
    
    final taken = supplement['taken_today'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          taken 
            ? '${supplement['name']} marked as taken!'
            : '${supplement['name']} marked as not taken',
        ),
        backgroundColor: taken ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showAddSupplementDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    String frequency = 'Daily';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Supplement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Supplement Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: ['Daily', 'Twice Daily', 'Weekly', 'As Needed']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) => frequency = value!,
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
              if (nameController.text.isNotEmpty && dosageController.text.isNotEmpty) {
                setState(() {
                  _supplements.add({
                    'name': nameController.text,
                    'dosage': dosageController.text,
                    'frequency': frequency,
                    'time': '9:00 AM',
                    'taken_today': false,
                    'color': Colors.teal,
                    'icon': Icons.medication,
                    'notes': '',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Supplement added!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}