// lib/features/onboarding/screens/dietary_preferences_page.dart
import 'package:flutter/material.dart';

class DietaryPreferencesPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const DietaryPreferencesPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<DietaryPreferencesPage> createState() => _DietaryPreferencesPageState();
}

class _DietaryPreferencesPageState extends State<DietaryPreferencesPage> {
  List<String> _selectedDiets = [];
  double _waterIntake = 2.0; // Default 2 liters
  int _waterIntakeGlasses = 8;
  bool _useGlasses = true;
  List<String> _medicalConditions = [];
  final _otherMedicalController = TextEditingController();

  final List<String> _dietOptions = [
    'No restrictions',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'Gluten-free',
    'Dairy-free',
    'Keto',
    'Paleo',
    'Low carb',
    'Low fat',
    'Mediterranean',
    'Halal',
    'Kosher',
  ];

  final List<String> _commonMedicalConditions = [
    'None',
    'Diabetes',
    'Hypertension',
    'Heart disease',
    'Asthma',
    'Thyroid issues',
    'Food allergies',
    'Digestive disorders',
    'Arthritis',
    'Other (please specify)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.formData['dietaryPreferences'] != null) {
      _selectedDiets = List<String>.from(widget.formData['dietaryPreferences']);
    }
    _waterIntake = widget.formData['waterIntake'] ?? 2.0;
    if (widget.formData['medicalConditions'] != null) {
      _medicalConditions = List<String>.from(widget.formData['medicalConditions']);
    }
  }

  @override
  void dispose() {
    _otherMedicalController.dispose();
    super.dispose();
  }

  void _updateWaterIntake({double? liters, int? glasses}) {
    setState(() {
      if (liters != null) {
        _waterIntake = liters;
        _waterIntakeGlasses = (liters * 4).round(); // 250ml per glass
      } else if (glasses != null) {
        _waterIntakeGlasses = glasses;
        _waterIntake = glasses / 4.0; // Convert to liters
      }
    });
    
    widget.onDataChanged('waterIntake', _waterIntake);
    widget.onDataChanged('waterIntakeGlasses', _waterIntakeGlasses);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dietary & Health Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your diet preferences and health conditions.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Dietary preferences
          const Text(
            'Dietary Preferences',
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
            children: _dietOptions.map((diet) {
              final isSelected = _selectedDiets.contains(diet);
              return FilterChip(
                label: Text(diet),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (diet == 'No restrictions') {
                        _selectedDiets = ['No restrictions'];
                      } else {
                        _selectedDiets.remove('No restrictions');
                        _selectedDiets.add(diet);
                      }
                    } else {
                      _selectedDiets.remove(diet);
                    }
                  });
                  widget.onDataChanged('dietaryPreferences', _selectedDiets);
                },
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Water intake section with toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Water Intake Goal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Toggle button
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                isSelected: [_useGlasses, !_useGlasses],
                onPressed: (index) {
                  setState(() {
                    _useGlasses = index == 0;
                  });
                },
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Glasses'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Liters'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Water intake display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Text(
                          _useGlasses 
                              ? '$_waterIntakeGlasses glasses'
                              : '${_waterIntake.toStringAsFixed(1)} liters',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          _useGlasses 
                              ? '(${_waterIntake.toStringAsFixed(1)} liters)'
                              : '($_waterIntakeGlasses glasses)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Slider for adjustment
                if (_useGlasses) ...[
                  Slider(
                    value: _waterIntakeGlasses.toDouble(),
                    min: 4,
                    max: 16,
                    divisions: 12,
                    label: '$_waterIntakeGlasses glasses',
                    onChanged: (value) {
                      _updateWaterIntake(glasses: value.round());
                    },
                  ),
                  Text(
                    'Recommended: 8-10 glasses per day',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ] else ...[
                  Slider(
                    value: _waterIntake,
                    min: 1.0,
                    max: 4.0,
                    divisions: 12,
                    label: '${_waterIntake.toStringAsFixed(1)} L',
                    onChanged: (value) {
                      _updateWaterIntake(liters: value);
                    },
                  ),
                  Text(
                    'Recommended: 2-2.5 liters per day',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Medical conditions section
          const Text(
            'Medical Conditions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select any that apply to you:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonMedicalConditions.map((condition) {
              final isSelected = _medicalConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (condition == 'None') {
                      _medicalConditions.clear();
                      if (selected) {
                        _medicalConditions.add(condition);
                      }
                    } else {
                      _medicalConditions.remove('None');
                      if (selected) {
                        _medicalConditions.add(condition);
                      } else {
                        _medicalConditions.remove(condition);
                      }
                    }
                  });
                  widget.onDataChanged('medicalConditions', _medicalConditions);

                  if (condition == 'Other (please specify)' && selected) {
                    _showOtherMedicalDialog();
                  }
                },
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showOtherMedicalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Other Medical Condition'),
        content: TextField(
          controller: _otherMedicalController,
          decoration: const InputDecoration(
            hintText: 'Please specify...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDataChanged('otherMedicalCondition', _otherMedicalController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}