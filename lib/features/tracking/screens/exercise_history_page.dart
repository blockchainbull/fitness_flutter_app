import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';

class ExerciseHistoryPage extends StatefulWidget {
  final UserProfile userProfile;

  const ExerciseHistoryPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<ExerciseHistoryPage> createState() => _ExerciseHistoryPageState();
}

class _ExerciseHistoryPageState extends State<ExerciseHistoryPage> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;
  String? _selectedType;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    try {
      final exercises = await _apiService.getExerciseLogs(
        widget.userProfile.id!,
        exerciseType: _selectedType,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      );
      
      setState(() {
        _exercises = exercises;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load exercises: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      await _loadExercises();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise History'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_selectedType != null || _selectedDateRange != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedType != null)
                    Chip(
                      label: Text(_selectedType!.toUpperCase()),
                      onDeleted: () {
                        setState(() => _selectedType = null);
                        _loadExercises();
                      },
                    ),
                  if (_selectedDateRange != null)
                    Chip(
                      label: Text(
                        '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                      ),
                      onDeleted: () {
                        setState(() => _selectedDateRange = null);
                        _loadExercises();
                      },
                    ),
                ],
              ),
            ),
          
          // Exercise list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _exercises.isEmpty
                    ? const Center(
                        child: Text(
                          'No exercises found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _exercises[index];
                          return _buildExerciseCard(exercise);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final date = DateTime.parse(exercise['exercise_date']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          exercise['exercise_name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(date)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Type', exercise['exercise_type'].toUpperCase()),
                _buildDetailRow('Duration', '${exercise['duration_minutes']} minutes'),
                if (exercise['calories_burned'] != null)
                  _buildDetailRow('Calories', '${exercise['calories_burned'].toStringAsFixed(0)} cal'),
                if (exercise['distance_km'] != null)
                  _buildDetailRow('Distance', '${exercise['distance_km'].toStringAsFixed(2)} km'),
                if (exercise['sets'] != null)
                  _buildDetailRow('Sets', exercise['sets'].toString()),
                if (exercise['reps'] != null)
                  _buildDetailRow('Reps', exercise['reps'].toString()),
                if (exercise['weight_kg'] != null)
                  _buildDetailRow('Weight', '${exercise['weight_kg']} kg'),
                _buildDetailRow('Intensity', exercise['intensity'].toUpperCase()),
                if (exercise['notes'] != null && exercise['notes'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Notes: ${exercise['notes']}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Exercises'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Exercise Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ...['cardio', 'strength', 'flexibility', 'sports', 'other']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        )),
              ],
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(_selectedDateRange == null
                  ? 'Select Date Range'
                  : 'Change Date Range'),
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
              Navigator.pop(context);
              _loadExercises();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}