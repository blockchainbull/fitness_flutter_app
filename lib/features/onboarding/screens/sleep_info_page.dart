// lib/features/onboarding/screens/sleep_info_page.dart
import 'package:flutter/material.dart';

class SleepInfoPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const SleepInfoPage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<SleepInfoPage> createState() => _SleepInfoPageState();
}

class _SleepInfoPageState extends State<SleepInfoPage> {
  double _sleepHours = 7.0;
  String _bedtime = '';
  String _wakeupTime = '';
  List<String> _selectedSleepIssues = [];
  bool _showValidationErrors = false;

  final List<String> _commonBedtimes = [
    '8:00 PM', '8:30 PM', '9:00 PM', '9:30 PM', '10:00 PM', '10:30 PM',
    '11:00 PM', '11:30 PM', '12:00 AM', '12:30 AM', '1:00 AM', '1:30 AM',
    '2:00 AM'
  ];

  final List<String> _commonWakeupTimes = [
    '4:00 AM', '4:30 AM', '5:00 AM', '5:30 AM', '6:00 AM', '6:30 AM',
    '7:00 AM', '7:30 AM', '8:00 AM', '8:30 AM', '9:00 AM', '9:30 AM',
    '10:00 AM', '10:30 AM', '11:00 AM'
  ];

  final List<Map<String, dynamic>> _sleepIssues = [
    {'id': 'None', 'icon': Icons.check_circle, 'color': Colors.green},
    {'id': 'Difficulty falling asleep', 'icon': Icons.bedtime_off, 'color': Colors.orange},
    {'id': 'Waking up during the night', 'icon': Icons.nights_stay, 'color': Colors.purple},
    {'id': 'Waking up too early', 'icon': Icons.alarm, 'color': Colors.amber},
    {'id': 'Snoring', 'icon': Icons.volume_up, 'color': Colors.blue},
    {'id': 'Sleep apnea', 'icon': Icons.air, 'color': Colors.red},
    {'id': 'Restless legs', 'icon': Icons.accessibility_new, 'color': Colors.teal},
    {'id': 'Insomnia', 'icon': Icons.visibility_off, 'color': Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _sleepHours = widget.formData['sleepHours'] ?? 7.0;
    _bedtime = widget.formData['bedtime'] ?? '';
    _wakeupTime = widget.formData['wakeupTime'] ?? '';
    if (widget.formData['sleepIssues'] != null) {
      _selectedSleepIssues = List<String>.from(widget.formData['sleepIssues']);
    }
  }

  bool _isFieldValid(String fieldName) {
    if (!_showValidationErrors) return true;
    
    switch (fieldName) {
      case 'hours':
        return _sleepHours >= 3 && _sleepHours <= 12;
      case 'bedtime':
        return _bedtime.isNotEmpty;
      case 'wakeup':
        return _wakeupTime.isNotEmpty;
      default:
        return true;
    }
  }

  String _getSleepQualityMessage() {
    if (_sleepHours < 6) {
      return 'Less than recommended. Adults need 7-9 hours for optimal health.';
    } else if (_sleepHours >= 6 && _sleepHours < 7) {
      return 'Slightly below recommended. Consider aiming for 7-9 hours.';
    } else if (_sleepHours >= 7 && _sleepHours <= 9) {
      return 'Perfect! This is the recommended range for adults.';
    } else {
      return 'More than typical. Ensure you\'re getting quality sleep.';
    }
  }

  Color _getSleepQualityColor() {
    if (_sleepHours < 6) return Colors.red;
    if (_sleepHours < 7) return Colors.orange;
    if (_sleepHours <= 9) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sleep Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quality sleep is crucial for your health and fitness goals.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sleep Duration with validation
          Row(
            children: const [
              Text(
                'How many hours do you sleep?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getSleepQualityColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !_isFieldValid('hours') && _showValidationErrors
                    ? Colors.red
                    : _getSleepQualityColor().withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bedtime,
                      size: 32,
                      color: _getSleepQualityColor(),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_sleepHours.toStringAsFixed(1)} hours',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _getSleepQualityColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _sleepHours,
                  min: 3,
                  max: 12,
                  divisions: 18,
                  activeColor: _getSleepQualityColor(),
                  inactiveColor: _getSleepQualityColor().withOpacity(0.2),
                  onChanged: (value) {
                    setState(() {
                      _sleepHours = value;
                      _showValidationErrors = false;
                    });
                    widget.onDataChanged('sleepHours', value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('3h', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text('12h', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: _getSleepQualityColor(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getSleepQualityMessage(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getSleepQualityColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bedtime Selection
          Row(
            children: const [
              Text(
                'Usual Bedtime',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (!_isFieldValid('bedtime') && _showValidationErrors)
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
                  Text('Please select your bedtime', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          
          Container(
            height: 120,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _commonBedtimes.length,
              itemBuilder: (context, index) {
                final time = _commonBedtimes[index];
                final isSelected = _bedtime == time;
                final isPM = time.contains('PM');
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _bedtime = time;
                      _showValidationErrors = false;
                    });
                    widget.onDataChanged('bedtime', time);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isPM ? Colors.indigo : Colors.deepPurple).withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? (isPM ? Colors.indigo : Colors.deepPurple)
                            : (!_isFieldValid('bedtime') && _showValidationErrors
                                ? Colors.red[300]!
                                : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bedtime,
                          size: 16,
                          color: isSelected 
                              ? (isPM ? Colors.indigo : Colors.deepPurple)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? (isPM ? Colors.indigo : Colors.deepPurple)
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Wake-up Time Selection
          Row(
            children: const [
              Text(
                'Usual Wake-up Time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (!_isFieldValid('wakeup') && _showValidationErrors)
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
                  Text('Please select your wake-up time', style: TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ),
            ),
          
          Container(
            height: 120,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _commonWakeupTimes.length,
              itemBuilder: (context, index) {
                final time = _commonWakeupTimes[index];
                final isSelected = _wakeupTime == time;
                final hour = int.parse(time.split(':')[0]);
                final isEarly = hour < 6;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _wakeupTime = time;
                      _showValidationErrors = false;
                    });
                    widget.onDataChanged('wakeupTime', time);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (isEarly ? Colors.orange : Colors.amber).withOpacity(0.2)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? (isEarly ? Colors.orange : Colors.amber)
                            : (!_isFieldValid('wakeup') && _showValidationErrors
                                ? Colors.red[300]!
                                : Colors.grey[300]!),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          size: 16,
                          color: isSelected 
                              ? (isEarly ? Colors.orange : Colors.amber)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? (isEarly ? Colors.orange : Colors.amber[700])
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sleep Issues (Optional)
          const Text(
            'Do you have any sleep issues? (Optional)',
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
            children: _sleepIssues.map((issue) {
              final isSelected = _selectedSleepIssues.contains(issue['id']);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (issue['id'] == 'None') {
                      _selectedSleepIssues = isSelected ? [] : ['None'];
                    } else {
                      if (isSelected) {
                        _selectedSleepIssues.remove(issue['id']);
                      } else {
                        _selectedSleepIssues.remove('None');
                        _selectedSleepIssues.add(issue['id'] as String);
                      }
                    }
                  });
                  widget.onDataChanged('sleepIssues', _selectedSleepIssues);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (issue['color'] as Color).withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? issue['color'] as Color
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        issue['icon'] as IconData,
                        size: 16,
                        color: isSelected 
                            ? issue['color'] as Color
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        issue['id'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? issue['color'] as Color
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  void validateFields() {
    setState(() {
      _showValidationErrors = true;
    });
  }
}