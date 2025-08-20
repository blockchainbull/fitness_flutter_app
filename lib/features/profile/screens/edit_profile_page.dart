// lib/features/profile/screens/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  const EditProfilePage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  // Form controllers
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _primaryGoalController;
  late TextEditingController _weightGoalController;
  late TextEditingController _targetWeightController;

  // Form data
  late String _selectedActivityLevel;
  late String _selectedGender;
  late int _selectedAge;

  bool _isSaving = false;
  String? _errorMessage;

  // Read-only fields that cannot be edited
  final List<String> _readOnlyFields = ['name', 'email', 'age', 'gender', 'startingWeight', 'startingWeightDate'];

  // FIXED: Activity level mapping
  final List<String> _activityLevelOptions = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
    'extra_active',
  ];

  String? _selectedPrimaryGoal;
  String? _selectedWeightGoal;
  String? _selectedGoalTimeline;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Handle nullable values with null coalescing
    _heightController = TextEditingController(
      text: widget.userProfile.height.toString(),
    );
    _weightController = TextEditingController(
      text: widget.userProfile.weight.toString(),
    );
    _primaryGoalController = TextEditingController(
      text: widget.userProfile.primaryGoal ?? '',
    );
    _weightGoalController = TextEditingController(
      text: widget.userProfile.weightGoal ?? '',
    );
    _targetWeightController = TextEditingController(
      text: widget.userProfile.targetWeight.toString(),
    );

    // Initialize dropdown values
    _selectedActivityLevel = _mapToActivityLevelKey(widget.userProfile.activityLevel);
    _selectedGender = widget.userProfile.gender ?? 'Male';
    _selectedAge = widget.userProfile.age ?? 25;
    
    // Initialize goal selections
    _selectedPrimaryGoal = widget.userProfile.primaryGoal;
    _selectedWeightGoal = widget.userProfile.weightGoal;
    _selectedGoalTimeline = widget.userProfile.goalTimeline;

    print('🔍 Initialized profile editing with:');
    print('  Primary Goal: $_selectedPrimaryGoal');
    print('  Weight Goal: $_selectedWeightGoal');
    print('  Target Weight: ${_targetWeightController.text}');
  }

  // FIXED: Map stored activity level to dropdown key
  String _mapToActivityLevelKey(String? activityLevel) {
    if (activityLevel == null || activityLevel.isEmpty) {
      return 'moderately_active'; // Default
    }

    // Direct key match
    if (_activityLevelOptions.contains(activityLevel)) {
      return activityLevel;
    }

    // Map formatted text back to keys
    final lowercaseLevel = activityLevel.toLowerCase();
    
    if (lowercaseLevel.contains('sedentary') || lowercaseLevel.contains('little')) {
      return 'sedentary';
    } else if (lowercaseLevel.contains('lightly active') || lowercaseLevel.contains('light exercise')) {
      return 'lightly_active';
    } else if (lowercaseLevel.contains('moderately active') || lowercaseLevel.contains('moderate exercise')) {
      return 'moderately_active';
    } else if (lowercaseLevel.contains('very active') || lowercaseLevel.contains('hard exercise')) {
      return 'very_active';
    } else if (lowercaseLevel.contains('extra active') || lowercaseLevel.contains('very hard exercise')) {
      return 'extra_active';
    }

    // Fallback to default
    print('[EditProfilePage] Unknown activity level: $activityLevel, using default');
    return 'moderately_active';
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _primaryGoalController.dispose();
    _weightGoalController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Parse values with proper null safety
      final double height = double.tryParse(_heightController.text) ?? widget.userProfile.height;
      final double weight = double.tryParse(_weightController.text) ?? widget.userProfile.weight;
      
      // Use dropdown values instead of text controllers
      final String primaryGoal = _selectedPrimaryGoal ?? widget.userProfile.primaryGoal;
      final String weightGoal = _selectedWeightGoal ?? widget.userProfile.weightGoal;
      final double targetWeight = _targetWeightController.text.isNotEmpty 
          ? (double.tryParse(_targetWeightController.text) ?? weight)
          : widget.userProfile.targetWeight;

      print('[EditProfilePage] Saving with:');
      print('  Primary Goal: $primaryGoal');
      print('  Weight Goal: $weightGoal');
      print('  Activity Level: $_selectedActivityLevel');

      // Create updated UserProfile object instead of Map
      final updatedProfile = widget.userProfile.copyWith(
        height: height,
        weight: weight,
        activityLevel: _selectedActivityLevel,
        primaryGoal: primaryGoal,
        weightGoal: weightGoal,
        targetWeight: targetWeight,
      );

      // Save using the existing method that takes UserProfile
      await _apiService.updateUserProfile(updatedProfile);

      // Return updated profile to previous screen
      if (mounted) {
        Navigator.pop(context, updatedProfile);
      }

    } catch (e) {
      print('[EditProfilePage] Error saving profile: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ),
                  ],
                ),
              ),

            _buildSectionHeader('Personal Information'),
            _buildReadOnlyField('Name', widget.userProfile.name),
            _buildReadOnlyField('Email', widget.userProfile.email),
            _buildReadOnlyField('Age', '${widget.userProfile.age ?? 0} years'),
            _buildReadOnlyField('Gender', widget.userProfile.gender ?? 'Not specified'),

            const SizedBox(height: 24),
            _buildSectionHeader('Physical Stats'),
            _buildNumberField(
              'Height (cm)',
              _heightController,
              'Please enter your height',
              min: 100,
              max: 250,
            ),
            _buildNumberField(
              'Weight (kg)',
              _weightController,
              'Please enter your weight',
              min: 30,
              max: 300,
            ),

            if (widget.userProfile.startingWeight != null) ...[
              _buildReadOnlyField(
                'Starting Weight', 
                '${widget.userProfile.startingWeight!.toStringAsFixed(1)} kg'
              ),
              if (widget.userProfile.startingWeightDate != null)
                _buildReadOnlyField(
                  'Started Tracking', 
                  '${widget.userProfile.startingWeightDate!.day}/${widget.userProfile.startingWeightDate!.month}/${widget.userProfile.startingWeightDate!.year}'
                ),
            ],

            _buildDropdownField(
              'Activity Level',
              _selectedActivityLevel,
              _activityLevelOptions, // FIXED: Use the predefined list
              (value) => setState(() => _selectedActivityLevel = value!),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Goals'),
            _buildPrimaryGoalDropdown(),
            _buildWeightGoalDropdown(),
            _buildNumberField(
              'Target Weight (kg)',
              _targetWeightController,
              'What is your target weight?',
              min: 30,
              max: 300,
              isRequired: false,
            ),

            // Show weight progress if starting weight exists
           if (widget.userProfile.startingWeight != null) ...[
             const SizedBox(height: 24),
             _buildSectionHeader('Weight Progress'),
             _buildWeightProgressCard(),
           ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryGoalDropdown() {
    final primaryGoalOptions = [
      'Lose Weight',
      'Gain Weight', 
      'Build Muscle',
      'Improve Fitness',
      'Maintain Health',
      'General Wellness',
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: primaryGoalOptions.contains(_selectedPrimaryGoal) ? _selectedPrimaryGoal : null,
        decoration: InputDecoration(
          labelText: 'Primary Goal',
          hintText: 'What is your main fitness goal?',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: primaryGoalOptions.map((goal) => DropdownMenuItem(
          value: goal,
          child: Text(goal),
        )).toList(),
        onChanged: (value) {
          setState(() {
            _selectedPrimaryGoal = value;
          });
        },
      ),
    );
  }

  Widget _buildWeightGoalDropdown() {
    final weightGoalOptions = [
      'lose_weight',
      'gain_weight',
      'maintain_weight',
    ];

    final weightGoalLabels = {
      'lose_weight': 'Lose Weight',
      'gain_weight': 'Gain Weight', 
      'maintain_weight': 'Maintain Weight',
    };

    // Map current value to the correct format
    String? currentValue = _selectedWeightGoal;
    if (currentValue != null) {
      // Convert display text to key if needed
      if (currentValue.toLowerCase().contains('lose')) {
        currentValue = 'lose_weight';
      } else if (currentValue.toLowerCase().contains('gain')) {
        currentValue = 'gain_weight';
      } else if (currentValue.toLowerCase().contains('maintain')) {
        currentValue = 'maintain_weight';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: weightGoalOptions.contains(currentValue) ? currentValue : null,
        decoration: InputDecoration(
          labelText: 'Weight Goal',
          hintText: 'Do you want to lose, gain, or maintain weight?',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: weightGoalOptions.map((goal) => DropdownMenuItem(
          value: goal,
          child: Text(weightGoalLabels[goal] ?? goal),
        )).toList(),
        onChanged: (value) {
          setState(() {
            _selectedWeightGoal = value;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your weight goal';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildWeightProgressCard() {
    final startingWeight = widget.userProfile.startingWeight!;
    final currentWeight = widget.userProfile.weight;
    final weightChange = startingWeight - currentWeight;
    final isLoss = weightChange > 0;
    final daysTracking = widget.userProfile.startingWeightDate != null 
        ? DateTime.now().difference(widget.userProfile.startingWeightDate!).inDays 
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat('Started', '${startingWeight.toStringAsFixed(1)} kg', Colors.blue),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                _buildProgressStat('Current', '${currentWeight.toStringAsFixed(1)} kg', Colors.indigo),
                Icon(isLoss ? Icons.trending_down : Icons.trending_up, 
                      color: isLoss ? Colors.green : Colors.orange),
                _buildProgressStat(
                  isLoss ? 'Lost' : 'Gained', 
                  '${weightChange.abs().toStringAsFixed(1)} kg', 
                  isLoss ? Colors.green : Colors.orange
                ),
              ],
            ),
            if (daysTracking > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Tracking for $daysTracking days',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Icon(Icons.lock, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getReadOnlyReason(label),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getReadOnlyReason(String label) {
    switch (label) {
      case 'Name':
      case 'Email':
      case 'Age':
      case 'Gender':
        return 'This field cannot be edited for security reasons';
      case 'Starting Weight':
        return 'Starting weight is locked to preserve your progress history';
      case 'Started Tracking':
        return 'This date is automatically set when you first log your weight';
      default:
        return 'This field cannot be edited';
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String hint, {
    double? min,
    double? max,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          if (value != null && value.isNotEmpty) {
            final number = double.tryParse(value);
            if (number == null) {
              return 'Please enter a valid number';
            }
            if (min != null && number < min) {
              return 'Value must be at least $min';
            }
            if (max != null && number > max) {
              return 'Value must be at most $max';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    // FIXED: Ensure the value exists in options
    final validValue = options.contains(value) ? value : options.first;
    
    if (value != validValue) {
      print('[EditProfilePage] Invalid dropdown value: $value, using: $validValue');
      // Update the selected value to a valid one
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedActivityLevel = validValue;
        });
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: validValue, // FIXED: Use validated value
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(_formatActivityLevel(option)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }

  String _formatActivityLevel(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary (little/no exercise)';
      case 'lightly_active':
        return 'Lightly Active (light exercise 1-3 days/week)';
      case 'moderately_active':
        return 'Moderately Active (moderate exercise 3-5 days/week)';
      case 'very_active':
        return 'Very Active (hard exercise 6-7 days/week)';
      case 'extra_active':
        return 'Extra Active (very hard exercise, physical job)';
      default:
        return level;
    }
  }
}