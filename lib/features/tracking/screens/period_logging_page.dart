import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/period_repository.dart';
import 'package:user_onboarding/data/managers/user_manager.dart';
import 'package:user_onboarding/data/services/api_service.dart';

class PeriodCalendarPage extends StatefulWidget {
  const PeriodCalendarPage({Key? key}) : super(key: key);

  @override
  State<PeriodCalendarPage> createState() => _PeriodCalendarPageState();
}

class _PeriodCalendarPageState extends State<PeriodCalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  
  UserProfile? _userProfile;
  List<PeriodEntry> _periodHistory = [];
  PeriodEntry? _currentPeriod;
  bool _isLoading = true;
  
  final ApiService _apiService = ApiService();
  
  Map<DateTime, List<String>> _events = {};
  Set<DateTime> _periodDays = {};
  Set<DateTime> _fertileDays = {};
  Set<DateTime> _ovulationDays = {};
  
  // UI State
  final List<String> _flowOptions = ['Light', 'Medium', 'Heavy', 'Spotting'];
  String _selectedFlow = 'Medium';
  List<String> _selectedSymptoms = [];
  String? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = await UserManager.getCurrentUser();
      if (user != null && user.id != null) {
        final periods = await PeriodRepository.getPeriodHistory(user.id!, limit: 24);
        final currentPeriod = await PeriodRepository.getCurrentPeriod(user.id!);
        
        setState(() {
          _userProfile = user;
          _periodHistory = periods;
          _currentPeriod = currentPeriod;
          _calculatePeriodDays();
          _calculateFertileDays();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading period data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _calculatePeriodDays() {
    _periodDays.clear();
    _events.clear();
    
    for (var period in _periodHistory) {
      final startDate = DateTime(period.startDate.year, period.startDate.month, period.startDate.day);
      final endDate = period.endDate ?? DateTime.now();
      
      for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
        final day = startDate.add(Duration(days: i));
        _periodDays.add(day);
        _events[day] = ['Period'];
      }
    }
  }

  void _calculateFertileDays() {
    if (_userProfile == null) return;
    
    final cycleLength = _userProfile!.cycleLength ?? 28;
    _fertileDays.clear();
    _ovulationDays.clear();
    
    for (var period in _periodHistory) {
      final ovulationDay = period.startDate.add(Duration(days: cycleLength - 14));
      final normalizedOvulation = DateTime(ovulationDay.year, ovulationDay.month, ovulationDay.day);
      _ovulationDays.add(normalizedOvulation);
      
      // Fertile window is 5 days before and 1 day after ovulation
      for (int i = -5; i <= 1; i++) {
        final fertileDay = ovulationDay.add(Duration(days: i));
        final normalizedDay = DateTime(fertileDay.year, fertileDay.month, fertileDay.day);
        _fertileDays.add(normalizedDay);
        
        if (!_periodDays.contains(normalizedDay)) {
          _events[normalizedDay] = (_events[normalizedDay] ?? [])..add('Fertile');
        }
      }
    }
  }

  Widget _buildCalendarDay(DateTime day, DateTime focusedDay) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final isToday = isSameDay(day, DateTime.now());
    final isSelected = isSameDay(day, _selectedDay);
    final isPeriod = _periodDays.contains(normalizedDay);
    final isFertile = _fertileDays.contains(normalizedDay);
    final isOvulation = _ovulationDays.contains(normalizedDay);
    
    Color? backgroundColor;
    Color? textColor;
    Color? borderColor;
    
    if (isPeriod) {
      backgroundColor = const Color(0xFFE91E63).withOpacity(0.8);
      textColor = Colors.white;
    } else if (isOvulation) {
      backgroundColor = Colors.purple.shade400;
      textColor = Colors.white;
    } else if (isFertile) {
      backgroundColor = Colors.purple.shade100;
      textColor = Colors.purple.shade900;
    } else if (isSelected) {
      backgroundColor = Colors.blue.withOpacity(0.1);
      textColor = Colors.blue.shade900;
      borderColor = Colors.blue;
    } else {
      backgroundColor = Colors.transparent;
      textColor = Colors.grey.shade800;
    }
    
    if (isToday) {
      borderColor = Colors.blue.shade600;
    }
    
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
          if (isPeriod || isFertile || isOvulation)
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isPeriod 
                          ? Colors.white 
                          : isOvulation 
                              ? Colors.white
                              : Colors.purple.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDayDetails(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final isPeriod = _periodDays.contains(normalizedDay);
    final isFertile = _fertileDays.contains(normalizedDay);
    final isOvulation = _ovulationDays.contains(normalizedDay);
    
    // Find period entry for this day
    PeriodEntry? dayPeriod;
    for (var period in _periodHistory) {
      if (day.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
          (period.endDate == null || day.isBefore(period.endDate!.add(const Duration(days: 1))))) {
        dayPeriod = period;
        break;
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDayDetailsSheet(day, isPeriod, isFertile, isOvulation, dayPeriod),
    );
  }

  Widget _buildDayDetailsSheet(DateTime day, bool isPeriod, bool isFertile, bool isOvulation, PeriodEntry? periodEntry) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(day),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Cycle day
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Cycle Day ${_getCycleDay(day)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Status cards
                  if (isPeriod) _buildStatusCard(
                    'Period Day ${_getPeriodDay(day, periodEntry)}',
                    'Track your flow and symptoms',
                    Icons.water_drop,
                    const Color(0xFFE91E63),
                  ),
                  
                  if (isOvulation) _buildStatusCard(
                    'Ovulation Day',
                    'Peak fertility - highest chance of conception',
                    Icons.bubble_chart,
                    Colors.purple,
                  ),
                  
                  if (isFertile && !isOvulation) _buildStatusCard(
                    'Fertile Window',
                    'High chance of pregnancy',
                    Icons.favorite,
                    Colors.purple.shade400,
                  ),
                  
                  if (!isPeriod && !isFertile) _buildStatusCard(
                    'Regular Day',
                    'Low fertility',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  if (_canEditDay(day)) ...[
                    if (!isPeriod)
                      _buildActionButton(
                        'Start Period',
                        Icons.add,
                        const Color(0xFFE91E63),
                        () => _startPeriodOnDay(day),
                      ),
                    
                    if (isPeriod && periodEntry?.endDate == null)
                      _buildActionButton(
                        'End Period',
                        Icons.stop,
                        Colors.orange,
                        () => _endPeriodOnDay(day),
                      ),
                    
                    if (isPeriod)
                      _buildActionButton(
                        'Log Symptoms',
                        Icons.edit,
                        Colors.blue,
                        () {
                          Navigator.pop(context);
                          _showEditPeriodDialog(day, periodEntry);
                        },
                      ),
                    
                    const SizedBox(height: 16),
                  ],
                  
                  // Period details
                  if (periodEntry != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Period Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          if (periodEntry.flowIntensity != null)
                            _buildDetailItem(
                              Icons.water_drop,
                              'Flow',
                              periodEntry.flowIntensity!,
                              const Color(0xFFE91E63),
                            ),
                          
                          if (periodEntry.symptoms != null && periodEntry.symptoms!.isNotEmpty)
                            _buildDetailItem(
                              Icons.warning_amber_rounded,
                              'Symptoms',
                              periodEntry.symptoms!.join(', '),
                              Colors.orange,
                            ),
                          
                          if (periodEntry.mood != null)
                            _buildDetailItem(
                              Icons.mood,
                              'Mood',
                              periodEntry.mood!,
                              Colors.blue,
                            ),
                          
                          if (periodEntry.notes != null && periodEntry.notes!.isNotEmpty)
                            _buildDetailItem(
                              Icons.note,
                              'Notes',
                              periodEntry.notes!,
                              Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getCycleDay(DateTime day) {
    if (_periodHistory.isEmpty || _userProfile == null) return 1;
    
    PeriodEntry? recentPeriod;
    for (var period in _periodHistory) {
      if (period.startDate.isBefore(day.add(const Duration(days: 1)))) {
        recentPeriod = period;
        break;
      }
    }
    
    if (recentPeriod == null) return 1;
    
    return day.difference(recentPeriod.startDate).inDays + 1;
  }

  int _getPeriodDay(DateTime day, PeriodEntry? period) {
    if (period == null) return 1;
    return day.difference(period.startDate).inDays + 1;
  }

  bool _canEditDay(DateTime day) {
    return !day.isAfter(DateTime.now());
  }

  Future<void> _startPeriodOnDay(DateTime day) async {
    if (_userProfile == null || _userProfile!.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newPeriod = PeriodEntry(
        userId: _userProfile!.id!,
        startDate: day,
        flowIntensity: 'Medium',
        symptoms: [],
        mood: null,
        notes: null,
      );
      
      await PeriodRepository.savePeriodEntry(newPeriod);
      
      // Update the user profile with new last period date
      final updatedProfile = _userProfile!.copyWith(
        lastPeriodDate: day,
      );
      
      await _apiService.updateUserProfile(updatedProfile);
      
      setState(() {
        _userProfile = updatedProfile;
      });
      
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Period started on ${DateFormat('MMM d').format(day)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error starting period: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endPeriodOnDay(DateTime day) async {
    if (_currentPeriod == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updatedPeriod = _currentPeriod!.copyWith(endDate: day);
      await PeriodRepository.savePeriodEntry(updatedPeriod);
      
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Period ended on ${DateFormat('MMM d').format(day)}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error ending period: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEditPeriodDialog(DateTime day, PeriodEntry? periodEntry) {
    _selectedFlow = periodEntry?.flowIntensity ?? 'Medium';
    _selectedSymptoms = List<String>.from(periodEntry?.symptoms ?? []);
    _selectedMood = periodEntry?.mood;
    _notesController.text = periodEntry?.notes ?? '';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Log Symptoms - ${DateFormat('MMM d').format(day)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Flow Intensity:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _flowOptions.map((flow) => ChoiceChip(
                    label: Text(flow),
                    selected: _selectedFlow == flow,
                    onSelected: (selected) {
                      setDialogState(() => _selectedFlow = flow);
                    },
                    selectedColor: const Color(0xFFE91E63).withOpacity(0.2),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                const Text('Symptoms:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Cramps', 'Headache', 'Bloating', 'Fatigue',
                    'Breast tenderness', 'Mood swings', 'Back pain', 'Acne'
                  ].map((symptom) => FilterChip(
                    label: Text(symptom, style: const TextStyle(fontSize: 12)),
                    selected: _selectedSymptoms.contains(symptom),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) {
                          _selectedSymptoms.add(symptom);
                        } else {
                          _selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                    selectedColor: Colors.orange.withOpacity(0.2),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _savePeriodData(day, periodEntry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePeriodData(DateTime day, PeriodEntry? existingEntry) async {
    if (_userProfile == null || _userProfile!.id == null) return;
    
    try {
      final periodEntry = existingEntry ?? PeriodEntry(
        userId: _userProfile!.id!,
        startDate: day,
        flowIntensity: _selectedFlow,
        symptoms: _selectedSymptoms,
        mood: _selectedMood,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      final updatedEntry = periodEntry.copyWith(
        flowIntensity: _selectedFlow,
        symptoms: _selectedSymptoms,
        mood: _selectedMood,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      await PeriodRepository.savePeriodEntry(updatedEntry);
      await _loadData();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Symptoms saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving period data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE91E63)),
        ),
      );
    }
    
    final cycleDay = _getCycleDay(DateTime.now());
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Period Tracker',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentPeriod != null
                  ? 'Period Day ${_getPeriodDay(DateTime.now(), _currentPeriod)}'
                  : 'Cycle Day $cycleDay',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: _showLegend,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.grey.shade700),
                defaultTextStyle: TextStyle(color: Colors.grey.shade800),
                selectedTextStyle: const TextStyle(color: Colors.white),
                todayTextStyle: const TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                titleTextStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                weekendStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, focusedDay);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, focusedDay);
                },
                todayBuilder: (context, day, focusedDay) {
                  return _buildCalendarDay(day, focusedDay);
                },
              ),
              
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showDayDetails(selectedDay);
              },
              
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          
          // Bottom action button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _currentPeriod != null
                  ? () => _endPeriodOnDay(DateTime.now())
                  : () => _startPeriodOnDay(DateTime.now()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentPeriod != null
                    ? Colors.orange
                    : const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentPeriod != null ? 'End Period' : 'Start Period',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(
              color: const Color(0xFFE91E63),
              label: 'Period Days',
              icon: Icons.water_drop,
            ),
            _buildLegendItem(
              color: Colors.purple.shade400,
              label: 'Ovulation Day',
              icon: Icons.bubble_chart,
            ),
            _buildLegendItem(
              color: Colors.purple.shade100,
              label: 'Fertile Window',
              icon: Icons.favorite,
            ),
            _buildLegendItem(
              color: Colors.blue,
              label: 'Today',
              icon: Icons.today,
            ),
            _buildLegendItem(
              color: Colors.green,
              label: 'Regular Days',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}