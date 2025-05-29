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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedGender = '';
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedActivityLevel = '';

  // Password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Added variables for health metrics
  double _bmi = 0.0;
  double _bmr = 0.0;
  double _tdee = 0.0;

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
    _passwordController.text = widget.formData['password'] ?? '';
    _selectedGender = widget.formData['gender'] ?? '';
    _ageController.text = widget.formData['age']?.toString() ?? '';
    _heightController.text = widget.formData['height']?.toString() ?? '';
    _weightController.text = widget.formData['weight']?.toString() ?? '';
    _selectedActivityLevel = widget.formData['activityLevel'] ?? '';

    // Just calculate metrics locally without updating form data in initState
    _updateLocalMetrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to update metrics after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLocalMetrics();
      setState(() {}); // Trigger UI update with calculated metrics
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Validate password
  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Check if passwords match
  bool _doPasswordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  // Calculate BMI, BMR, and TDEE based on user inputs
  void _calculateHealthMetrics() {
    _updateLocalMetrics();
    
    // Only after updating local metrics, update form data
    widget.onDataChanged('bmi', _bmi);
    widget.onDataChanged('bmr', _bmr);
    widget.onDataChanged('tdee', _tdee);
  }
  
  // Update local metric values without calling widget.onDataChanged
  void _updateLocalMetrics() {
    double? height = double.tryParse(_heightController.text);
    double? weight = double.tryParse(_weightController.text);
    int? age = int.tryParse(_ageController.text);
    String gender = _selectedGender;

    // Calculate BMI if height and weight are available
    if (height != null && weight != null && height > 0) {
      // BMI = weight(kg) / (height(m))²
      double heightInMeters = height / 100; // Convert cm to m
      _bmi = weight / (heightInMeters * heightInMeters);
    } else {
      _bmi = 0.0;
    }

    // Calculate BMR if all required data is available
    if (height != null && weight != null && age != null && gender.isNotEmpty) {
      // Mifflin-St Jeor Equation for BMR - rounded to match expected values
      if (gender == 'Male') {
        _bmr = (10 * weight + 6.25 * height - 5 * age + 5).roundToDouble();
      } else if (gender == 'Female') {
        _bmr = (10 * weight + 6.25 * height - 5 * age - 161).roundToDouble();
      }
    } else {
      _bmr = 0.0;
    }

    // Calculate TDEE if BMR and activity level are available
    if (_bmr > 0 && _selectedActivityLevel.isNotEmpty) {
      double activityMultiplier;
      
      // Assign activity multiplier based on selected level
      if (_selectedActivityLevel.contains('Sedentary')) {
        activityMultiplier = 1.2;
      } else if (_selectedActivityLevel.contains('Lightly active')) {
        activityMultiplier = 1.375;
      } else if (_selectedActivityLevel.contains('Moderately active')) {
        activityMultiplier = 1.55;
      } else if (_selectedActivityLevel.contains('Very active')) {
        activityMultiplier = 1.725;
      } else if (_selectedActivityLevel.contains('Extra active')) {
        activityMultiplier = 1.9;
      } else {
        activityMultiplier = 1.2; // Default to sedentary
      }
      
      // Round to the nearest whole number to match expected values
      _tdee = (_bmr * activityMultiplier).roundToDouble();
    } else {
      _tdee = 0.0;
    }
  }

  // Get BMI category
  String _getBmiCategory() {
    if (_bmi < 18.5) {
      return 'Underweight';
    } else if (_bmi >= 18.5 && _bmi < 25) {
      return 'Normal';
    } else if (_bmi >= 25 && _bmi < 30) {
      return 'Overweight';
    } else if (_bmi >= 30) {
      return 'Obese';
    } else {
      return 'N/A';
    }
  }

  // Get color for BMI category
  Color _getBmiColor() {
    if (_bmi < 18.5) {
      return Colors.blue;
    } else if (_bmi >= 18.5 && _bmi < 25) {
      return Colors.green;
    } else if (_bmi >= 25 && _bmi < 30) {
      return Colors.orange;
    } else if (_bmi >= 30) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
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
          
          // Password field
          const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Enter your password (min 6 characters)',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              errorText: _passwordController.text.isNotEmpty 
                  ? _validatePassword(_passwordController.text) 
                  : null,
            ),
            onChanged: (value) {
              widget.onDataChanged('password', value);
              setState(() {}); // Refresh to show/hide validation error
            },
          ),
          const SizedBox(height: 16),
          
          // Confirm Password field
          const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              errorText: _confirmPasswordController.text.isNotEmpty && !_doPasswordsMatch() 
                  ? 'Passwords do not match' 
                  : null,
            ),
            onChanged: (value) {
              setState(() {}); // Refresh to show/hide validation error
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
                    
                    // We need to wait for the next frame before calculating metrics
                    Future.microtask(() => _calculateHealthMetrics());
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
                    
                    // We need to wait for the next frame before calculating metrics
                    Future.microtask(() => _calculateHealthMetrics());
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
                          // Wait for next frame to calculate metrics
                          Future.microtask(() => _calculateHealthMetrics());
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
                    const Text('Height (cm)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          // Wait for next frame to calculate metrics
                          Future.microtask(() => _calculateHealthMetrics());
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
                    const Text('Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          // Wait for next frame to calculate metrics
                          Future.microtask(() => _calculateHealthMetrics());
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
                  // Wait for next frame to calculate metrics
                  Future.microtask(() => _calculateHealthMetrics());
                }
              },
            ),
          ),
          
          // Health Metrics Section
          if (_bmi > 0 || _bmr > 0 || _tdee > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Health Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // BMI Row
                  if (_bmi > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BMI (Body Mass Index)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A measure of body fat based on height and weight',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _bmi.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getBmiColor(),
                              ),
                            ),
                            Text(
                              _getBmiCategory(),
                              style: TextStyle(
                                fontSize: 14,
                                color: _getBmiColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],
                  
                  // BMR Row
                  if (_bmr > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BMR (Basal Metabolic Rate)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Calories needed for basic functions at rest',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_bmr.toInt()} calories/day',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                  ],
                  
                  // TDEE Row
                  if (_tdee > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TDEE (Total Daily Energy Expenditure)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total calories burned daily based on activity level',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${_tdee.toInt()} calories/day',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}