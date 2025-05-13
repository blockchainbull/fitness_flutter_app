// lib/features/home/widgets/exercise_tracker.dart

import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';

class ExerciseTracker extends StatefulWidget {
  final UserProfile userProfile;
  
  const ExerciseTracker({
    Key? key,
    required this.userProfile,
  }) : super(key: key);
  
  @override
  State<ExerciseTracker> createState() => _ExerciseTrackerState();
}

class _ExerciseTrackerState extends State<ExerciseTracker> {
  final List<Map<String, dynamic>> _exercises = [];
  bool _isAddingExercise = false;
  int _caloriesBurned = 0;
  
  @override
  void initState() {
    super.initState();
    _loadExercises();
  }
  
  void _loadExercises() {
    // In a real app, load from database
    // For now, use sample data
    _exercises.clear();
    
    // Calculate total calories burned
    _caloriesBurned = _exercises.fold(0, (sum, exercise) => sum + (exercise['caloriesBurned'] as int));
  }
  
  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final durationController = TextEditingController();
    final caloriesController = TextEditingController();
    final timeController = TextEditingController(text: _getCurrentTime());
    
    setState(() {
      _isAddingExercise = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exercise'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g., Running, Walking, Cycling',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  hintText: 'e.g., 30',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                decoration: const InputDecoration(
                  labelText: 'Calories Burned',
                  hintText: 'e.g., 250',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'e.g., 7:30 AM',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isAddingExercise = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Validate inputs
              if (nameController.text.isEmpty || 
                  durationController.text.isEmpty || 
                  caloriesController.text.isEmpty ||
                  int.tryParse(durationController.text) == null ||
                  int.tryParse(caloriesController.text) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all fields correctly'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final newExercise = {
                'name': nameController.text,
                'duration': int.parse(durationController.text),
                'caloriesBurned': int.parse(caloriesController.text),
                'time': timeController.text,
              };
              
              setState(() {
                _exercises.add(newExercise);
                _caloriesBurned += newExercise['caloriesBurned'] as int;
                _isAddingExercise = false;
              });
              
              // In a real app, save this to the database
              _saveExerciseData();
              
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
  
  Future<void> _saveExerciseData() async {
    // In a real app, save to database
    print('Saving exercises: $_exercises');
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              const Text(
                'Exercise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_caloriesBurned calories burned',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Exercise list
          if (_exercises.isNotEmpty) ...[
            const Text(
              'Today\'s Activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_exercises.length, (index) {
              final exercise = _exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
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
                                exercise['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${exercise['caloriesBurned']} cal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${exercise['duration']} minutes',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            exercise['time'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                      onPressed: () {
                        // Remove exercise
                        setState(() {
                          _caloriesBurned -= exercise['caloriesBurned'] as int;
                          _exercises.removeAt(index);
                        });
                        // Save changes
                        _saveExerciseData();
                      },
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
          
          // Add exercise button
          Center(
            child: _isAddingExercise
                ? const CircularProgressIndicator()
                : OutlinedButton.icon(
                    onPressed: _showAddExerciseDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Exercise'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}