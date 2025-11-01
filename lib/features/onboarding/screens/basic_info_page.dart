// lib/features/onboarding/screens/basic_info_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Validation
  bool _showValidationErrors = false;

  final List<String> _activityLevels = [
    'Sedentary (Little or no exercise)',
    'Lightly active (Light exercise 1-3 days/week)',
    'Moderately active (Moderate exercise 3-5 days/week)',
    'Very active (Hard exercise 6-7 days/week)',
    'Extra active (Very hard exercise daily)'
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

  // Validation helpers
  bool _isFieldValid(String fieldName) {
    if (!_showValidationErrors) return true;
    
    switch (fieldName) {
      case 'name':
        return _nameController.text.trim().isNotEmpty;
      case 'email':
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return _emailController.text.trim().isNotEmpty && 
               emailRegex.hasMatch(_emailController.text);
      case 'password':
        return _passwordController.text.length >= 6;
      case 'confirmPassword':
        return _confirmPasswordController.text.isNotEmpty && _doPasswordsMatch();
      case 'gender':
        return _selectedGender.isNotEmpty;
      case 'age':
        int? age = int.tryParse(_ageController.text);
        return age != null && age >= 13 && age <= 120;
      case 'height':
        double? height = double.tryParse(_heightController.text);
        return height != null && height >= 100 && height <= 250;
      case 'weight':
        double? weight = double.tryParse(_weightController.text);
        return weight != null && weight >= 30 && weight <= 300;
      case 'activityLevel':
        return _selectedActivityLevel.isNotEmpty;
      default:
        return true;
    }
  }

  bool _areAllFieldsValid() {
    return _isFieldValid('name') &&
          _isFieldValid('email') &&
          _isFieldValid('password') &&
          _isFieldValid('confirmPassword') &&
          _isFieldValid('gender') &&
          _isFieldValid('age') &&
          _isFieldValid('height') &&
          _isFieldValid('weight') &&
          _isFieldValid('activityLevel');
}

  Widget _buildRequiredIndicator() {
    return const Text(
      ' *',
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
  }

  // Check if passwords match
  bool _doPasswordsMatch() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  void _updateLocalMetrics() {
    if (widget.formData['bmi'] != null) {
      _bmi = widget.formData['bmi'] as double;
    }
    if (widget.formData['bmr'] != null) {
      _bmr = widget.formData['bmr'] as double;
    }
    if (widget.formData['tdee'] != null) {
      _tdee = widget.formData['tdee'] as double;
    }
  }

  void _calculateHealthMetrics() {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 0;
    final gender = _selectedGender;
    final activityLevel = _selectedActivityLevel;

    if (height > 0 && weight > 0 && age > 0 && gender.isNotEmpty) {
      // Calculate BMI
      final heightInMeters = height / 100;
      setState(() {
        _bmi = weight / (heightInMeters * heightInMeters);
      });
      widget.onDataChanged('bmi', _bmi);

      // Calculate BMR
      double bmr;
      if (gender == 'Male') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
      setState(() {
        _bmr = bmr;
      });
      widget.onDataChanged('bmr', _bmr);

      // Calculate TDEE
      if (activityLevel.isNotEmpty) {
        double activityMultiplier = 1.2;
        switch (activityLevel.toLowerCase()) {
          case 'sedentary':
            activityMultiplier = 1.2;
            break;
          case 'lightly active':
            activityMultiplier = 1.375;
            break;
          case 'moderately active':
            activityMultiplier = 1.55;
            break;
          case 'very active':
            activityMultiplier = 1.725;
            break;
          case 'extra active':
            activityMultiplier = 1.9;
            break;
        }
        setState(() {
          _tdee = bmr * activityMultiplier;
        });
        widget.onDataChanged('tdee', _tdee);
      }
    }
  }

  // Get BMI category
  String _getBmiCategory() {
    if (_bmi < 18.5) {
      return 'Underweight';
    } else if (_bmi >= 18.5 && _bmi < 25) {
      return 'Normal weight';
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
            'Fields marked with * are required',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name field
          Row(
            children: [
              const Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _isFieldValid('name') ? Colors.grey : Colors.red,
                ),
              ),
              errorText: !_isFieldValid('name') ? 'Name is required' : null,
            ),
            onChanged: (value) {
              widget.onDataChanged('name', value);
              if (_showValidationErrors) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Email field
          Row(
            children: [
              const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: !_isFieldValid('email') ? 'Valid email is required' : null,
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) {
              widget.onDataChanged('email', value);
              if (_showValidationErrors) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Password field
          Row(
            children: [
              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: !_isFieldValid('password') 
                  ? 'Password must be at least 6 characters' 
                  : null,
            ),
            onChanged: (value) {
              widget.onDataChanged('password', value);
              if (_showValidationErrors) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Confirm Password field
          Row(
            children: [
              const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: !_isFieldValid('confirmPassword') 
                ? _confirmPasswordController.text.isEmpty 
                    ? 'Please confirm your password'
                    : 'Passwords do not match' 
                : null,
            ),
            onChanged: (value) {
              widget.onDataChanged('confirmPassword', value);
              if (_showValidationErrors) setState(() {});
            },
          ),
          const SizedBox(height: 16),
          
          // Gender selection
          Row(
            children: [
              const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          if (!_isFieldValid('gender'))
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Please select your gender', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                      _showValidationErrors = false;
                    });
                    widget.onDataChanged('gender', 'Male');
                    Future.microtask(() => _calculateHealthMetrics());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Male' ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedGender == 'Male'
                            ? Colors.blue
                            : (!_isFieldValid('gender') ? Colors.red[300]! : Colors.grey[300]!),
                        width: _selectedGender == 'Male' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.male,
                          color: _selectedGender == 'Male' ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Male'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                      _showValidationErrors = false;
                    });
                    widget.onDataChanged('gender', 'Female');
                    Future.microtask(() => _calculateHealthMetrics());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedGender == 'Female' ? Colors.pink.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedGender == 'Female'
                            ? Colors.pink
                            : (!_isFieldValid('gender') ? Colors.red[300]! : Colors.grey[300]!),
                        width: _selectedGender == 'Female' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.female,
                          color: _selectedGender == 'Female' ? Colors.pink : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Text('Female'),
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
                    Row(
                      children: [
                        const Text('Age', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildRequiredIndicator(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        hintText: 'Years',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: !_isFieldValid('age') ? 'Required' : null,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('age', int.tryParse(value));
                          Future.microtask(() => _calculateHealthMetrics());
                        }
                        if (_showValidationErrors) setState(() {});
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
                    Row(
                      children: [
                        const Text('Height', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildRequiredIndicator(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 170.5 cm',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: !_isFieldValid('height') ? 'Required' : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')), // Allow 1 decimal for height
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('height', double.tryParse(value));
                          Future.microtask(() => _calculateHealthMetrics());
                        }
                        if (_showValidationErrors) setState(() {});
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
                    Row(
                      children: [
                        const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildRequiredIndicator(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 65.75 kg',
                        prefixIcon: const Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: !_isFieldValid('weight') ? 'Required' : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), 
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          widget.onDataChanged('weight', double.tryParse(value));
                          Future.microtask(() => _calculateHealthMetrics());
                        }
                        if (_showValidationErrors) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activity level
          Row(
            children: [
              const Text('Activity Level', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildRequiredIndicator(),
            ],
          ),
          const SizedBox(height: 8),
          if (!_isFieldValid('activityLevel'))
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Please select your activity level', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: !_isFieldValid('activityLevel') ? Colors.red[300]! : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActivityLevel.isEmpty ? null : _selectedActivityLevel,
                hint: const Text('Select your activity level'),
                isExpanded: true,
                items: _activityLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedActivityLevel = newValue ?? '';
                    _showValidationErrors = false;
                  });
                  widget.onDataChanged('activityLevel', newValue);
                  _calculateHealthMetrics();
                },
              ),
            ),
          ),
          
          // Health Metrics Display (if calculated)
          if (_bmi > 0)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Health Metrics',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'BMI',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bmi.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getBmiColor(),
                            ),
                          ),
                          Text(
                            _getBmiCategory(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getBmiColor(),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'BMR',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_bmr.toStringAsFixed(0)} cal',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Daily burn',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'TDEE',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_tdee.toStringAsFixed(0)} cal',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Total need',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  bool validateFields() {
    setState(() {
      _showValidationErrors = true;
    });
    return _areAllFieldsValid();
  }
}