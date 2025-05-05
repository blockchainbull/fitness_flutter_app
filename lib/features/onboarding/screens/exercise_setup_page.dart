import 'package:flutter/material.dart';


class CurrentExerciseSetupPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const CurrentExerciseSetupPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<CurrentExerciseSetupPage> createState() => _CurrentExerciseSetupPageState();
}

class _CurrentExerciseSetupPageState extends State<CurrentExerciseSetupPage> {
  String _workoutLocation = '';
  List<String> _availableEquipment = [];
  String _fitnessLevel = 'Beginner';
  bool _hasTrainer = false;

  final List<Map<String, dynamic>> _locationOptions = [
    {
      'title': 'Gym',
      'description': 'Commercial gym or fitness center',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'Home',
      'description': 'Working out in your living space',
      'icon': Icons.home,
    },
    {
      'title': 'Outdoors',
      'description': 'Parks, trails, or outdoor spaces',
      'icon': Icons.park,
    },
    {
      'title': 'Office',
      'description': 'Workplace gym or during breaks',
      'icon': Icons.work,
    },
    {
      'title': 'Studio',
      'description': 'Specialized fitness studios',
      'icon': Icons.storefront,
    },
  ];

  final List<String> _equipmentOptions = [
    'Dumbbells',
    'Barbell & Plates',
    'Resistance bands',
    'Kettlebells',
    'Cardio machines',
    'Yoga mat',
    'Pull-up bar',
    'Bench',
    'TRX/Suspension trainer',
    'Medicine ball',
    'None',
  ];

  final List<String> _fitnessLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _workoutLocation = widget.formData['workoutLocation'] ?? '';
    if (widget.formData['availableEquipment'] != null) {
      _availableEquipment = List<String>.from(widget.formData['availableEquipment']);
    }
    _fitnessLevel = widget.formData['fitnessLevel'] ?? 'Beginner';
    _hasTrainer = widget.formData['hasTrainer'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Current Exercise Setup',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about where and how you currently exercise.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Workout location
          const Text(
            'Where do you usually workout?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _locationOptions.length,
            itemBuilder: (context, index) {
              final location = _locationOptions[index];
              final isSelected = _workoutLocation == location['title'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _workoutLocation = location['title'];
                  });
                  widget.onDataChanged('workoutLocation', location['title']);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        location['icon'],
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        location['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        location['description'],
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          // Available equipment
          const Text(
            'What equipment do you have access to?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that apply',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipmentOptions.map((equipment) {
              final isSelected = _availableEquipment.contains(equipment);
              return FilterChip(
                label: Text(equipment),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (equipment == 'None') {
                        _availableEquipment = ['None'];
                      } else {
                        _availableEquipment.remove('None');
                        _availableEquipment.add(equipment);
                      }
                    } else {
                      _availableEquipment.remove(equipment);
                    }
                  });
                  widget.onDataChanged('availableEquipment', _availableEquipment);
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Fitness level
          const Text(
            'What\'s your current fitness level?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _fitnessLevels.map((level) {
              final isSelected = _fitnessLevel == level;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _fitnessLevel = level;
                  });
                  widget.onDataChanged('fitnessLevel', level);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Personal trainer
          SwitchListTile(
            title: const Text(
              'Do you work with a personal trainer?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: _hasTrainer,
            onChanged: (value) {
              setState(() {
                _hasTrainer = value;
              });
              widget.onDataChanged('hasTrainer', value);
            },
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}