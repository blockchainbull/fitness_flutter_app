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
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeupTime = const TimeOfDay(hour: 5, minute: 0);
  List<String> _sleepIssues = [];

  final List<String> _sleepIssueOptions = [
    'Trouble falling asleep',
    'Waking up during the night',
    'Waking up too early',
    'Feeling tired after sleep',
    'Snoring',
    'Sleep apnea',
    'None',
  ];
  
  @override
  void initState() {
    super.initState();
    _sleepHours = widget.formData['sleepHours'] ?? 7.0;
    
    // Initialize bedtime from data if available
    if (widget.formData['bedtime'] != null && widget.formData['bedtime'].isNotEmpty) {
      final timeParts = widget.formData['bedtime'].split(':');
      if (timeParts.length == 2) {
        _bedtime = TimeOfDay(
          hour: int.parse(timeParts[0]), 
          minute: int.parse(timeParts[1])
        );
      }
    }
    
    // Initialize wakeup time from data if available
    if (widget.formData['wakeupTime'] != null && widget.formData['wakeupTime'].isNotEmpty) {
      final timeParts = widget.formData['wakeupTime'].split(':');
      if (timeParts.length == 2) {
        _wakeupTime = TimeOfDay(
          hour: int.parse(timeParts[0]), 
          minute: int.parse(timeParts[1])
        );
      }
    }
    
    // Initialize sleep issues
    if (widget.formData['sleepIssues'] != null) {
      _sleepIssues = List<String>.from(widget.formData['sleepIssues']);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveInitialValues();
    });

  }
  
  void _saveInitialValues() {
    // Save default sleep hours if not set
    if (widget.formData['sleepHours'] == null) {
      widget.onDataChanged('sleepHours', _sleepHours);
    }
    
    // Save default bedtime if not set
    if (widget.formData['bedtime'] == null || widget.formData['bedtime'].isEmpty) {
      widget.onDataChanged('bedtime', _formatTimeOfDay(_bedtime));
    }
    
    // Save default wakeup time if not set
    if (widget.formData['wakeupTime'] == null || widget.formData['wakeupTime'].isEmpty) {
      widget.onDataChanged('wakeupTime', _formatTimeOfDay(_wakeupTime));
    }
    
    // Save default sleep issues if not set
    if (widget.formData['sleepIssues'] == null) {
      widget.onDataChanged('sleepIssues', _sleepIssues);
    }
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    // Convert to 12-hour format for web compatibility
    final hour24 = timeOfDay.hour;
    final minute = timeOfDay.minute;
    
    // Convert to 12-hour format
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final period = hour24 < 12 ? 'AM' : 'PM';
    
    final hourStr = hour12.toString();
    final minuteStr = minute.toString().padLeft(2, '0');
    
    return '$hourStr:$minuteStr $period';
  }

    void _selectBedtime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (picked != null && picked != _bedtime) {
      setState(() {
        _bedtime = picked;
        
        // Calculate and update wake-up time based on sleep hours
        final int totalMinutes = picked.hour * 60 + picked.minute + (_sleepHours * 60).toInt();
        final int adjustedHours = (totalMinutes ~/ 60) % 24;
        final int adjustedMinutes = totalMinutes % 60;
        
        _wakeupTime = TimeOfDay(hour: adjustedHours, minute: adjustedMinutes);
      });
      final bedtimeFormatted = _formatTimeOfDay(picked);
      final wakeupTimeFormatted = _formatTimeOfDay(_wakeupTime);
      
      print('🛏️ Sleep time selected:');
      print('  Bedtime: $bedtimeFormatted');
      print('  Wake-up time: $wakeupTimeFormatted');

      widget.onDataChanged('bedtime', _formatTimeOfDay(picked));
      widget.onDataChanged('wakeupTime', _formatTimeOfDay(_wakeupTime));
    }
  }

    void _selectWakeupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeupTime,
    );
    if (picked != null && picked != _wakeupTime) {
      setState(() {
        _wakeupTime = picked;
        
        // Calculate and update bedtime based on sleep hours
        final int totalMinutes = picked.hour * 60 + picked.minute - (_sleepHours * 60).toInt();
        // Handle negative time by adding 24 hours (1440 minutes)
        final int adjustedTotalMinutes = totalMinutes < 0 ? totalMinutes + 24 * 60 : totalMinutes;
        final int adjustedHours = adjustedTotalMinutes ~/ 60;
        final int adjustedMinutes = adjustedTotalMinutes % 60;
        
        _bedtime = TimeOfDay(hour: adjustedHours, minute: adjustedMinutes);
      });
      widget.onDataChanged('wakeupTime', _formatTimeOfDay(picked));
      widget.onDataChanged('bedtime', _formatTimeOfDay(_bedtime));
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
            'Tell us about your sleep',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Quality sleep is essential for recovery and overall health.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Sleep hours slider
          const Text(
            'How many hours do you sleep per night?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Text(
                '${_sleepHours.toStringAsFixed(1)} hours',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Slider(
                value: _sleepHours,
                min: 3,
                max: 12,
                divisions: 18,
                label: _sleepHours.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _sleepHours = value;
                    
                    // Recalculate wakeup time based on new sleep duration
                    final int totalMinutes = _bedtime.hour * 60 + _bedtime.minute + (value * 60).toInt();
                    final int adjustedHours = (totalMinutes ~/ 60) % 24;
                    final int adjustedMinutes = totalMinutes % 60;
                    
                    _wakeupTime = TimeOfDay(hour: adjustedHours, minute: adjustedMinutes);
                  });
                  widget.onDataChanged('sleepHours', value);
                  widget.onDataChanged('wakeupTime', _formatTimeOfDay(_wakeupTime));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('3h', style: TextStyle(color: Colors.grey)),
                  Text('12h', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Bedtime and wake up time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bedtime',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectBedtime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bedtime, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              _bedtime.format(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wake up time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectWakeupTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              _wakeupTime.format(context),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sleep issues
          const Text(
            'Do you experience any sleep issues?',
            style: TextStyle(
              fontSize: 16,
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
            itemCount: _sleepIssueOptions.length,
            itemBuilder: (context, index) {
              final issue = _sleepIssueOptions[index];
              final isSelected = _sleepIssues.contains(issue);
              
              return CheckboxListTile(
                title: Text(issue),
                value: isSelected,
                activeColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (issue == 'None') {
                        _sleepIssues = ['None'];
                      } else {
                        _sleepIssues.remove('None');
                        _sleepIssues.add(issue);
                      }
                    } else {
                      _sleepIssues.remove(issue);
                    }
                  });
                  widget.onDataChanged('sleepIssues', _sleepIssues);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}