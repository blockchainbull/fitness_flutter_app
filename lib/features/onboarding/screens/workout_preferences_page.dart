import 'package:flutter/material.dart';


class WorkoutPreferencesPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const WorkoutPreferencesPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<WorkoutPreferencesPage> createState() => _WorkoutPreferencesPageState();
}

class _WorkoutPreferencesPageState extends State<WorkoutPreferencesPage> {
  List<String> _selectedWorkouts = [];
  int _workoutFrequency = 3;
  int _workoutDuration = 30;

  final List<Map<String, dynamic>> _workoutOptions = [
    {
      'title': 'Cardio',
      'description': 'Running, cycling, swimming, etc.',
      'icon': Icons.directions_run,
    },
    {
      'title': 'Strength Training',
      'description': 'Weightlifting, resistance training',
      'icon': Icons.fitness_center,
    },
    {
      'title': 'HIIT',
      'description': 'High-intensity interval training',
      'icon': Icons.timer,
    },
    {
      'title': 'Yoga',
      'description': 'Flexibility, balance, and mindfulness',
      'icon': Icons.self_improvement,
    },
    {
      'title': 'Pilates',
      'description': 'Core strength and stability',
      'icon': Icons.accessibility_new,
    },
    {
      'title': 'Sports',
      'description': 'Basketball, tennis, soccer, etc.',
      'icon': Icons.sports_basketball,
    },
    {
      'title': 'Walking',
      'description': 'Low-impact aerobic exercise',
      'icon': Icons.directions_walk,
    },
    {
      'title': 'Dancing',
      'description': 'Fun, rhythmic movement',
      'icon': Icons.music_note,
    },
    {
      'title': 'Crossfit',
      'description': 'High-intensity functional training',
      'icon': Icons.flash_on,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.formData['preferredWorkouts'] != null) {
      _selectedWorkouts = List<String>.from(widget.formData['preferredWorkouts']);
    }
    _workoutFrequency = widget.formData['workoutFrequency'] ?? 3;
    _workoutDuration = widget.formData['workoutDuration'] ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us what types of workouts you enjoy.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Workout type selection
          const Text(
            'What types of workouts do you prefer?',
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
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _workoutOptions.length,
            itemBuilder: (context, index) {
              final workout = _workoutOptions[index];
              final isSelected = _selectedWorkouts.contains(workout['title']);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWorkouts.remove(workout['title']);
                    } else {
                      _selectedWorkouts.add(workout['title']);
                    }
                  });
                  widget.onDataChanged('preferredWorkouts', _selectedWorkouts);
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
                        workout['icon'],
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        workout['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                      ),
                      Text(
                        workout['description'],
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
          
          // Workout frequency
          const Text(
            'How many days per week do you want to work out?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final days = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _workoutFrequency = days;
                  });
                  widget.onDataChanged('workoutFrequency', days);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _workoutFrequency == days ? Colors.blue : Colors.grey[100],
                  ),
                  child: Center(
                    child: Text(
                      '$days',
                      style: TextStyle(
                        color: _workoutFrequency == days ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'days per week',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Workout duration
          const Text(
            'How long do you prefer your workouts to be?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                '$_workoutDuration minutes',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Slider(
                value: _workoutDuration.toDouble(),
                min: 15,
                max: 90,
                divisions: 15,
                label: '$_workoutDuration min',
                onChanged: (value) {
                  setState(() {
                    _workoutDuration = value.toInt();
                  });
                  widget.onDataChanged('workoutDuration', value.toInt());
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('15 min', style: TextStyle(color: Colors.grey)),
                  Text('90 min', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}