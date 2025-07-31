import 'package:flutter/material.dart';

class PeriodCyclePage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onDataChanged;

  const PeriodCyclePage({
    Key? key,
    required this.formData,
    required this.onDataChanged,
  }) : super(key: key);

  @override
  State<PeriodCyclePage> createState() => _PeriodCyclePageState();
}

class _PeriodCyclePageState extends State<PeriodCyclePage> {
  bool? _hasPeriods;
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  bool _cycleLengthRegular = true;
  String _pregnancyStatus = '';
  String _trackingPreference = '';

  final List<Map<String, String>> _pregnancyOptions = [
    {'id': 'not_pregnant', 'label': 'Not pregnant'},
    {'id': 'pregnant', 'label': 'Currently pregnant'},
    {'id': 'breastfeeding', 'label': 'Breastfeeding'},
    {'id': 'trying_to_conceive', 'label': 'Trying to conceive'},
    {'id': 'prefer_not_to_say', 'label': 'Prefer not to say'},
  ];

  final List<Map<String, String>> _trackingOptions = [
    {'id': 'track_periods', 'label': 'Track my periods in the app'},
    {'id': 'general_wellness', 'label': 'Just general wellness support'},
    {'id': 'no_tracking', 'label': 'No period-related features'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize from existing form data if available
    _hasPeriods = widget.formData['hasPeriods'];
    _trackingPreference = widget.formData['trackingPreference'] ?? '';
    _pregnancyStatus = widget.formData['pregnancyStatus'] ?? '';
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriodDate ?? DateTime.now().subtract(Duration(days: 7)),
      firstDate: DateTime.now().subtract(Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _lastPeriodDate) {
      setState(() {
        _lastPeriodDate = picked;
      });
      widget.onDataChanged('lastPeriodDate', picked.toIso8601String());
    }
  }

  bool get _isFormValid {
    return _hasPeriods != null && 
           _trackingPreference.isNotEmpty && 
           (_hasPeriods == false || (_lastPeriodDate != null && _pregnancyStatus.isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reproductive Health',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Help us provide you with personalized health insights and support.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Do you have periods?
          const Text(
            'Do you currently have menstrual periods?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Yes/No buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _hasPeriods = true;
                    });
                    widget.onDataChanged('hasPeriods', true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasPeriods == true ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _hasPeriods == true ? Border.all(color: Colors.blue, width: 2) : null,
                    ),
                    child: Text(
                      'Yes, I have regular periods',
                      style: TextStyle(
                        color: _hasPeriods == true ? Colors.blue : Colors.black,
                        fontWeight: _hasPeriods == true ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _hasPeriods = false;
                    });
                    widget.onDataChanged('hasPeriods', false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasPeriods == false ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _hasPeriods == false ? Border.all(color: Colors.blue, width: 2) : null,
                    ),
                    child: Text(
                      'No, I don\'t have periods currently',
                      style: TextStyle(
                        color: _hasPeriods == false ? Colors.blue : Colors.black,
                        fontWeight: _hasPeriods == false ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Additional questions if has periods
          if (_hasPeriods == true) ...[
            const SizedBox(height: 32),
            
            // Last period date
            const Text(
              'When was your last period?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      _lastPeriodDate != null 
                          ? '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}'
                          : 'Select date',
                      style: TextStyle(
                        color: _lastPeriodDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cycle length
            const Text(
              'Average cycle length (days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _cycleLength.toString()),
                    onChanged: (value) {
                      setState(() {
                        _cycleLength = int.tryParse(value) ?? 28;
                      });
                      widget.onDataChanged('cycleLength', _cycleLength);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text('days'),
              ],
            ),
            const Text(
              'Typical range: 21-35 days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pregnancy status
            const Text(
              'Current status (optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._pregnancyOptions.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pregnancyStatus = option['id']!;
                  });
                  widget.onDataChanged('pregnancyStatus', option['id']);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _pregnancyStatus == option['id'] ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: _pregnancyStatus == option['id'] ? Border.all(color: Colors.blue, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option['label']!,
                          style: TextStyle(
                            color: _pregnancyStatus == option['id'] ? Colors.blue : Colors.black,
                            fontWeight: _pregnancyStatus == option['id'] ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_pregnancyStatus == option['id'])
                        const Icon(Icons.check_circle, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ],
          
          const SizedBox(height: 32),
          
          // Tracking preference
          const Text(
            'How would you like us to support your reproductive health?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          ..._trackingOptions.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _trackingPreference = option['id']!;
                });
                widget.onDataChanged('trackingPreference', option['id']);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _trackingPreference == option['id'] ? Colors.blue.withOpacity(0.2) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: _trackingPreference == option['id'] ? Border.all(color: Colors.blue, width: 2) : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option['label']!,
                        style: TextStyle(
                          color: _trackingPreference == option['id'] ? Colors.blue : Colors.black,
                          fontWeight: _trackingPreference == option['id'] ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_trackingPreference == option['id'])
                      const Icon(Icons.check_circle, color: Colors.blue),
                  ],
                ),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}