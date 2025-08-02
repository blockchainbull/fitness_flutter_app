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
  final List<String> _readOnlyFields = ['name', 'email', 'age', 'gender'];

  // FIXED: Activity level mapping
  final List<String> _activityLevelOptions = [
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
    'extra_active',
  ];

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
      text: widget.userProfile.targetWeight?.toString() ?? '',
    );

    // FIXED: Map the stored activity level to the correct dropdown value
    _selectedActivityLevel = _mapToActivityLevelKey(widget.userProfile.activityLevel);
    _selectedGender = widget.userProfile.gender ?? 'Male';
    _selectedAge = widget.userProfile.age ?? 25;

    print('[EditProfilePage] Initialized with activity level: ${widget.userProfile.activityLevel}');
    print('[EditProfilePage] Mapped to dropdown value: $_selectedActivityLevel');
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
      
      // Provide default values instead of null
      final String primaryGoal = _primaryGoalController.text.isNotEmpty 
          ? _primaryGoalController.text 
          : widget.userProfile.primaryGoal ?? 'General Fitness';
          
      final String weightGoal = _weightGoalController.text.isNotEmpty 
          ? _weightGoalController.text 
          : widget.userProfile.weightGoal ?? 'Maintain Weight';
          
      final double targetWeight = _targetWeightController.text.isNotEmpty 
          ? (double.tryParse(_targetWeightController.text) ?? weight)
          : widget.userProfile.targetWeight ?? weight;

      print('[EditProfilePage] Saving with activity level: $_selectedActivityLevel');

      // Create updated profile data
      final updatedProfile = UserProfile(
        id: widget.userProfile.id,
        name: widget.userProfile.name, // Read-only
        email: widget.userProfile.email, // Read-only
        password: widget.userProfile.password,
        gender: widget.userProfile.gender, // Read-only
        age: widget.userProfile.age, // Read-only
        height: height,
        weight: weight,
        activityLevel: _selectedActivityLevel, // Use the key, not formatted text
        primaryGoal: primaryGoal,
        weightGoal: weightGoal,
        targetWeight: targetWeight,
        goalTimeline: widget.userProfile.goalTimeline,
        sleepHours: widget.userProfile.sleepHours,
        bedtime: widget.userProfile.bedtime,
        wakeupTime: widget.userProfile.wakeupTime,
        sleepIssues: widget.userProfile.sleepIssues,
        dietaryPreferences: widget.userProfile.dietaryPreferences,
        waterIntake: widget.userProfile.waterIntake,
        medicalConditions: widget.userProfile.medicalConditions,
        otherMedicalCondition: widget.userProfile.otherMedicalCondition,
        preferredWorkouts: widget.userProfile.preferredWorkouts,
        workoutFrequency: widget.userProfile.workoutFrequency,
        workoutDuration: widget.userProfile.workoutDuration,
        workoutLocation: widget.userProfile.workoutLocation,
        availableEquipment: widget.userProfile.availableEquipment,
        fitnessLevel: widget.userProfile.fitnessLevel,
        hasTrainer: widget.userProfile.hasTrainer,
        formData: widget.userProfile.formData,
      );

      // Save to backend
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
            _buildDropdownField(
              'Activity Level',
              _selectedActivityLevel,
              _activityLevelOptions, // FIXED: Use the predefined list
              (value) => setState(() => _selectedActivityLevel = value!),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Goals'),
            _buildTextField(
              'Primary Goal',
              _primaryGoalController,
              'What is your main fitness goal?',
              isRequired: false,
            ),
            _buildTextField(
              'Weight Goal',
              _weightGoalController,
              'Do you want to lose, gain, or maintain weight?',
              isRequired: false,
            ),
            _buildNumberField(
              'Target Weight (kg)',
              _targetWeightController,
              'What is your target weight?',
              min: 30,
              max: 300,
              isRequired: false,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
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
            'This field cannot be edited',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
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