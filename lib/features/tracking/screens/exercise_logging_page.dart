// lib/features/tracking/screens/exercise_logging_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/features/tracking/screens/exercise_history_page.dart';

class ExerciseLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const ExerciseLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<ExerciseLoggingPage> createState() => _ExerciseLoggingPageState();
}

class _ExerciseLoggingPageState extends State<ExerciseLoggingPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _setsController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedExerciseType = 'cardio';
  String _selectedIntensity = 'moderate';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _recentExercises = [];
  Map<String, dynamic>? _exerciseStats;

  final List<String> _exerciseTypes = ['cardio', 'strength', 'flexibility', 'sports', 'other'];
  final List<String> _intensityLevels = ['low', 'moderate', 'high'];

  @override
  void initState() {
    super.initState();
    _loadExerciseData();
  }

  Future<void> _loadExerciseData() async {
    setState(() => _isLoading = true);
    try {
      print('📊 Loading exercise data...');
      
      // Load recent exercises
      final exercises = await _apiService.getExerciseLogs(
        widget.userProfile.id!,
        limit: 20,
      );
      print('📊 Loaded ${exercises.length} exercises');
      
      // Load exercise stats
      final stats = await _apiService.getExerciseStats(
        widget.userProfile.id!,
        days: 30,
      );
      print('📊 Loaded stats: $stats');
      
      setState(() {
        _recentExercises = exercises;
        _exerciseStats = stats;
      });
    } catch (e) {
      print('❌ Error loading exercise data: $e');
      
      // ✅ Set empty defaults on error
      setState(() {
        _recentExercises = [];
        _exerciseStats = {
          'total_workouts': 0,
          'total_minutes': 0,
          'total_calories': 0.0,
          'avg_duration': 0.0,
          'most_common_type': null,
          'type_breakdown': <String, int>{},
        };
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load exercise data: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final exerciseData = {
        'user_id': widget.userProfile.id,
        'exercise_name': _exerciseNameController.text,
        'exercise_type': _selectedExerciseType,
        'duration_minutes': int.parse(_durationController.text),
        'calories_burned': _caloriesController.text.isNotEmpty 
            ? double.parse(_caloriesController.text) 
            : null,
        'distance_km': _distanceController.text.isNotEmpty 
            ? double.parse(_distanceController.text) 
            : null,
        'sets': _setsController.text.isNotEmpty 
            ? int.parse(_setsController.text) 
            : null,
        'reps': _repsController.text.isNotEmpty 
            ? int.parse(_repsController.text) 
            : null,
        'weight_kg': _weightController.text.isNotEmpty 
            ? double.parse(_weightController.text) 
            : null,
        'intensity': _selectedIntensity,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'exercise_date': _selectedDate.toIso8601String(),
      };

      await _apiService.logExercise(exerciseData);
  
      // Save to SharedPreferences for offline access
      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      await prefs.setBool('exercise_logged_$dateStr', true);
      
      final currentMinutes = prefs.getInt('exercise_minutes_$dateStr') ?? 0;
      await prefs.setInt('exercise_minutes_$dateStr', 
          currentMinutes + int.parse(_durationController.text));
      
      final currentCalories = prefs.getDouble('exercise_calories_$dateStr') ?? 0;
      final newCalories = _caloriesController.text.isNotEmpty 
          ? double.parse(_caloriesController.text) 
          : 0.0;
      await prefs.setDouble('exercise_calories_$dateStr', currentCalories + newCalories);
      
      final currentCount = prefs.getInt('exercise_count_$dateStr') ?? 0;
      await prefs.setInt('exercise_count_$dateStr', currentCount + 1);
      
      _showSuccessSnackBar('Exercise logged successfully!');
      _clearForm();
      await _loadExerciseData(); // Reload data




    } catch (e) {
      _showErrorSnackBar('Failed to log exercise');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _exerciseNameController.clear();
    _durationController.clear();
    _caloriesController.clear();
    _distanceController.clear();
    _setsController.clear();
    _repsController.clear();
    _weightController.clear();
    _notesController.clear();
    setState(() {
      _selectedExerciseType = 'cardio';
      _selectedIntensity = 'moderate';
      _selectedDate = DateTime.now();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Tracking'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseHistoryPage(
                    userProfile: widget.userProfile,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  if (_exerciseStats != null) _buildStatsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Log New Exercise Form
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Log New Exercise',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Exercise Name
                            TextFormField(
                              controller: _exerciseNameController,
                              decoration: const InputDecoration(
                                labelText: 'Exercise Name*',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.fitness_center),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter exercise name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Exercise Type and Intensity
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedExerciseType,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _exerciseTypes.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedExerciseType = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedIntensity,
                                    decoration: const InputDecoration(
                                      labelText: 'Intensity',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _intensityLevels.map((level) {
                                      return DropdownMenuItem(
                                        value: level,
                                        child: Text(level.toUpperCase()),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedIntensity = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Duration and Calories
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Duration (min)*',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.timer),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _caloriesController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Calories',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.local_fire_department),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Distance (for cardio)
                            if (_selectedExerciseType == 'cardio')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: _distanceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Distance (km)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.straighten),
                                  ),
                                ),
                              ),
                            
                            // Sets, Reps, Weight (for strength)
                            if (_selectedExerciseType == 'strength')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _setsController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Sets',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _repsController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Reps',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _weightController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Weight (kg)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Date selector
                            ListTile(
                              title: Text(
                                'Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () => _selectDate(context),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Notes
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Notes',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _logExercise,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Log Exercise',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent Exercises
                  if (_recentExercises.isNotEmpty) _buildRecentExercises(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    // ✅ Provide safe defaults
    final stats = _exerciseStats ?? {
      'total_workouts': 0,
      'total_minutes': 0,
      'total_calories': 0.0,
      'avg_duration': 0.0,
      'most_common_type': null,
      'type_breakdown': <String, int>{},
    };
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Month\'s Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Workouts',
                  '${stats['total_workouts'] ?? 0}',
                  Icons.fitness_center,
                ),
                _buildStatItem(
                  'Minutes',
                  '${stats['total_minutes'] ?? 0}',
                  Icons.timer,
                ),
                _buildStatItem(
                  'Calories',
                  '${stats['total_calories']?.toStringAsFixed(0) ?? '0'}',
                  Icons.local_fire_department,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecentExercises() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentExercises.length > 5 ? 5 : _recentExercises.length,
              itemBuilder: (context, index) {
                final exercise = _recentExercises[index];
                return _buildExerciseListItem(exercise);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseListItem(Map<String, dynamic> exercise) {
    final date = exercise['exercise_date'] != null 
        ? DateTime.parse(exercise['exercise_date'])
        : DateTime.now();
    final formattedDate = DateFormat('MMM d').format(date);
    
    return ListTile(
      title: Text(
        exercise['exercise_name'] ?? 'Unknown Exercise',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${exercise['duration_minutes'] ?? 0} min • ${exercise['exercise_type'] ?? 'other'}',
      ),
      trailing: Text(
        formattedDate,
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _distanceController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}