import 'package:flutter/material.dart';


class PrimaryHealthGoalPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const PrimaryHealthGoalPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<PrimaryHealthGoalPage> createState() => _PrimaryHealthGoalPageState();
}

class _PrimaryHealthGoalPageState extends State<PrimaryHealthGoalPage> {
  String _selectedGoal = '';

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Lose Weight',
      'description': 'Reduce body fat and achieve a healthier weight',
      'icon': Icons.trending_down,
    },
    {
      'title': 'Build Muscle',
      'description': 'Increase muscle mass and strength',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Improve Fitness',
      'description': 'Enhance overall fitness and endurance',
      'icon': Icons.directions_run,
    },
    {
      'title': 'Maintain Health',
      'description': 'Keep current weight and maintain wellness',
      'icon': Icons.favorite,
    },
    {
      'title': 'Reduce Stress',
      'description': 'Focus on mental wellbeing and stress reduction',
      'icon': Icons.self_improvement,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.formData['primaryGoal'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your primary health goal?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the goal that best describes what you want to achieve.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Goal selection cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final goal = _goals[index];
              final isSelected = _selectedGoal == goal['title'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGoal = goal['title'];
                  });
                  widget.onDataChanged('primaryGoal', goal['title']);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          goal['icon'],
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.blue[700] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}