import 'package:flutter/material.dart';


class BasicInfoPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const BasicInfoPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<BasicInfoPage> createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = '';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedActivityLevel = '';

  final List<String> _activityLevels = [
    'Sedentary (little or no exercise)',
    'Lightly active (light exercise 1-3 days/week)',
    'Moderately active (moderate exercise 3-5 days/week)',
    'Very active (hard exercise 6-7 days/week)',
    'Extra active (very hard exercise & physical job)'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing values
    _nameController.text = widget.formData['name'] ?? '';
    _emailController.text = widget.formData['email'] ?? '';
    _selectedGender = widget.formData['gender'] ?? '';
    _ageController.text = widget.formData['age']?.toString() ?? '';
    _heightController.text = widget.formData['height']?.toString() ?? '';
    _weightController.text = widget.formData['weight']?.toString() ?? '';
    _selectedActivityLevel = widget.formData['activityLevel'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
            'Let\'s get to know you',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We need some basic information to personalize your experience.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name field
          const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person),
            ),
            onChanged: (value) {
              widget.onDataChanged('name', value);
            },
          ),
          const SizedBox(height: 16),
          
          // Email field
          const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              widget.onDataChanged('email', value);
            },
          ),
          const SizedBox(height: 16),
          
          // Gender selection
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                    widget.onDataChanged('gender', 'Male');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Male' ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedGender == 'Male'
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          color: _selectedGender == 'Male' ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Male',
                          style: TextStyle(
                            color: _selectedGender == 'Male' ? Colors.blue : Colors.black,
                            fontWeight: _selectedGender == 'Male' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                    widget.onDataChanged('gender', 'Female');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Female' ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedGender == 'Female'
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: _selectedGender == 'Female' ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Female',
                          style: TextStyle(
                            color: _selectedGender == 'Female' ? Colors.blue : Colors.black,
                            fontWeight: _selectedGender == 'Female' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Other';
                    });
                    widget.onDataChanged('gender', 'Other');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Other' ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedGender == 'Other'
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person,
                          color: _selectedGender == 'Other' ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Other',
                          style: TextStyle(
                            color: _selectedGender == 'Other' ? Colors.blue : Colors.black,
                            fontWeight: _selectedGender == 'Other' ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Age, Height, Weight row
          Row(
            children: [
              // Age field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        hintText: 'Years',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('age', int.parse(value));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Height field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Height', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        hintText: 'cm',
                        prefixIcon: Icon(Icons.height),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('height', double.parse(value));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Weight field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        hintText: 'kg',
                        prefixIcon: Icon(Icons.monitor_weight),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('weight', double.parse(value));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity level
          const Text('Activity Level', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              hint: const Text('Select your activity level'),
              value: _selectedActivityLevel.isNotEmpty ? _selectedActivityLevel : null,
              items: _activityLevels.map((String level) {
                return DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedActivityLevel = newValue;
                  });
                  widget.onDataChanged('activityLevel', newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
