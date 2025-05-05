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
          
          // Water intake
          const Text(
            'Daily Water Intake Goal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '${_waterIntake.toStringAsFixed(1)} liters',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _waterIntake,
                min: 0.5,
                max: 5.0,
                divisions: 18,
                label: '${_waterIntake.toStringAsFixed(1)} L',
                onChanged: (value) {
                  setState(() {
                    _waterIntake = value;
                  });
                  widget.onDataChanged('waterIntake', value);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('0.5L', style: TextStyle(color: Colors.grey)),
                  Text('5.0L', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Medical conditions
          const Text(
            'Pre-existing Medical Conditions',
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _commonMedicalConditions.length,
            itemBuilder: (context, index) {
              final condition = _commonMedicalConditions[index];
              final isSelected = _medicalConditions.contains(condition);
              
              return CheckboxListTile(
                title: Text(condition),
                value: isSelected,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (condition == 'None') {
                        _medicalConditions = ['None'];
                      } else {
                        _medicalConditions.remove('None');
                        _medicalConditions.add(condition);
                      }
                    } else {
                      _medicalConditions.remove(condition);
                    }
                  });
                  widget.onDataChanged('medicalConditions', _medicalConditions);
                },
              );
            },
          ),
          
          // Other medical condition text field
          if (_medicalConditions.contains('Other (please specify)'))
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 32.0, right: 16.0),
              child: TextField(
                controller: _otherMedicalController,
                decoration: const InputDecoration(
                  hintText: 'Please specify your condition',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  widget.onDataChanged('otherMedicalCondition', value);
                },
              ),
            ),
        ],
      ),
    );
  }
}