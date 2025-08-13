// lib/features/tracking/screens/period_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/repositories/period_repository.dart';
import 'package:intl/intl.dart';

class PeriodLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const PeriodLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<PeriodLoggingPage> createState() => _PeriodLoggingPageState();
}

class _PeriodLoggingPageState extends State<PeriodLoggingPage> {
  List<PeriodEntry> _periodHistory = [];
  PeriodEntry? _currentPeriod;
  bool _isLoading = true;
  
  late int _cycleLength;
  late int _periodLength;
  DateTime? _lastPeriodDate;
  
  final List<String> _symptoms = [
    'Cramps', 'Bloating', 'Headache', 'Mood swings', 'Acne', 
    'Breast tenderness', 'Fatigue', 'Back pain', 'Nausea'
  ];

  final List<String> _moods = [
    'Happy', 'Sad', 'Anxious', 'Irritable', 'Energetic', 'Tired', 'Calm'
  ];
  
  List<String> _selectedSymptoms = [];
  String? _selectedMood;
  String _flowIntensity = 'Medium';

  @override
  void initState() {
    super.initState();
    _initializePeriodData();
  }

  Future<void> _initializePeriodData() async {
    setState(() => _isLoading = true);
    
    _cycleLength = widget.userProfile.cycleLength ?? 28;
    _periodLength = widget.userProfile.periodLength ?? 5;
    _lastPeriodDate = widget.userProfile.lastPeriodDate;
    
    await _loadPeriodHistory();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadPeriodHistory() async {
    try {
      final history = await PeriodRepository.getPeriodHistory(
        widget.userProfile.id!,
        limit: 12,
      );
      
      setState(() {
        _periodHistory = history;
        if (history.isNotEmpty && history.first.endDate == null) {
          _currentPeriod = history.first;
          _selectedSymptoms = _currentPeriod!.symptoms ?? [];
          _selectedMood = _currentPeriod!.mood;
          _flowIntensity = _currentPeriod!.flowIntensity ?? 'Medium';
        }
      });
    } catch (e) {
      print('Error loading period history: $e');
    }
  }

  Future<void> _startPeriod() async {
    try {
      final newPeriod = PeriodEntry(
        userId: widget.userProfile.id!,
        startDate: DateTime.now(),
        flowIntensity: _flowIntensity,
        symptoms: _selectedSymptoms,
        mood: _selectedMood,
      );
      
      final id = await PeriodRepository.savePeriodEntry(newPeriod);
      
      setState(() {
        _currentPeriod = newPeriod.copyWith(id: id);
      });
      
      await _loadPeriodHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period started!')),
        );
      }
    } catch (e) {
      print('Error starting period: $e');
    }
  }

  Future<void> _endPeriod() async {
    if (_currentPeriod == null) return;
    
    try {
      final updatedPeriod = _currentPeriod!.copyWith(
        endDate: DateTime.now(),
      );
      
      await PeriodRepository.savePeriodEntry(updatedPeriod);
      
      setState(() {
        _currentPeriod = null;
        _selectedSymptoms = [];
        _selectedMood = null;
      });
      
      await _loadPeriodHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Period ended!')),
        );
      }
    } catch (e) {
      print('Error ending period: $e');
    }
  }

  Future<void> _updateCurrentPeriod() async {
    if (_currentPeriod == null) return;
    
    try {
      final updatedPeriod = _currentPeriod!.copyWith(
        symptoms: _selectedSymptoms,
        mood: _selectedMood,
        flowIntensity: _flowIntensity,
      );
      
      await PeriodRepository.savePeriodEntry(updatedPeriod);
      
      setState(() {
        _currentPeriod = updatedPeriod;
      });
    } catch (e) {
      print('Error updating period: $e');
    }
  }

  DateTime _calculateNextPeriod() {
    if (_periodHistory.isEmpty) {
      if (_lastPeriodDate != null) {
        return _lastPeriodDate!.add(Duration(days: _cycleLength));
      }
      return DateTime.now().add(Duration(days: _cycleLength));
    }
    
    final lastPeriod = _periodHistory.first;
    return lastPeriod.startDate.add(Duration(days: _cycleLength));
  }

  DateTime _calculateOvulation() {
    final nextPeriod = _calculateNextPeriod();
    return nextPeriod.subtract(const Duration(days: 14));
  }

  int _getCurrentCycleDay() {
    if (_periodHistory.isEmpty) {
      if (_lastPeriodDate != null) {
        return DateTime.now().difference(_lastPeriodDate!).inDays + 1;
      }
      return 1;
    }
    
    final lastPeriod = _periodHistory.first;
    return DateTime.now().difference(lastPeriod.startDate).inDays + 1;
  }

  int _getCurrentPeriodDay() {
    if (_currentPeriod == null) return 0;
    return DateTime.now().difference(_currentPeriod!.startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFE91E63),
          title: const Text('Period Tracking'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {},
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOnPeriod = _currentPeriod != null;
    final nextPeriodDate = _calculateNextPeriod();
    final ovulationDate = _calculateOvulation();
    final cycleDay = _getCurrentCycleDay();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE91E63),
        title: const Text('Period Tracking'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(isOnPeriod, cycleDay, nextPeriodDate),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCycleOverview(cycleDay, ovulationDate),
                  const SizedBox(height: 32),
                  _buildSymptomsSection(),
                  const SizedBox(height: 32),
                  _buildMoodSection(),
                  const SizedBox(height: 32),
                  _buildRecentCyclesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isOnPeriod ? _endPeriod : _startPeriod,
        backgroundColor: const Color(0xFFE91E63),
        child: Icon(isOnPeriod ? Icons.stop : Icons.add),
      ),
    );
  }

  Widget _buildHeaderCard(bool isOnPeriod, int cycleDay, DateTime nextPeriod) {
    final daysUntilPeriod = nextPeriod.difference(DateTime.now()).inDays;
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE91E63),
            Color(0xFFEC407A),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          children: [
            Icon(
              isOnPeriod ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isOnPeriod 
                  ? 'Period Day ${_getCurrentPeriodDay()}'
                  : 'Cycle Day $cycleDay',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOnPeriod 
                  ? 'Your period is active'
                  : 'Next period in $daysUntilPeriod days',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn('$_cycleLength days', 'Cycle Length'),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatColumn('$_periodLength days', 'Period Length'),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatColumn(
                  DateFormat('MMM dd').format(nextPeriod), 
                  'Next Period'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleOverview(int cycleDay, DateTime ovulationDate) {
    // Calculate key days in the cycle
    final firstDayOfCycle = DateTime.now().subtract(Duration(days: cycleDay - 1));
    final ovulationDay = ovulationDate.difference(firstDayOfCycle).inDays + 1;
    
    // Add adaptive sizing for different cycle lengths
    final bool isLongCycle = _cycleLength > 35;
    final double barWidth = isLongCycle ? 20 : 30;
  
    // Add cycle regularity indicator
    final bool isRegular = _cycleLength >= 26 && _cycleLength <= 32;

    // Fertile window is typically 5 days before ovulation + ovulation day
    final fertileStartDay = ovulationDay - 5;
    final fertileEndDay = ovulationDay;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRegular)
        Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                _cycleLength < 26 
                  ? 'Short cycle detected - consider consulting a healthcare provider'
                  : 'Long cycle detected - this may be normal for you',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cycle Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Day $cycleDay of $_cycleLength',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Period', const Color(0xFFE91E63)),
            const SizedBox(width: 16),
            _buildLegendItem('Fertile', Colors.lightBlue[300]!),
            const SizedBox(width: 16),
            _buildLegendItem('Ovulation', Colors.blue),
            const SizedBox(width: 16),
            _buildLegendItem('Today', Colors.purple),
          ],
        ),
        const SizedBox(height: 12),
        
        // Cycle bars with scroll view for better display
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            height: 80,
            child: Row(
              children: List.generate(_cycleLength, (index) {
                final day = index + 1;
                final isPeriodDay = day <= _periodLength;
                final isCurrentDay = day == cycleDay;
                final isOvulationDay = day == ovulationDay;
                final isFertileDay = day >= fertileStartDay && day <= fertileEndDay;
                final cycleDate = firstDayOfCycle.add(Duration(days: index));
                
                return GestureDetector(
                  onTap: () => _showDayDetails(day, cycleDate, isOvulationDay, isFertileDay, isPeriodDay),
                  child: Container(
                    width: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Day number
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrentDay ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentDay ? Colors.purple : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Bar
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getBarColor(
                              isPeriodDay: isPeriodDay,
                              isCurrentDay: isCurrentDay,
                              isOvulationDay: isOvulationDay,
                              isFertileDay: isFertileDay,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            border: isCurrentDay 
                                ? Border.all(color: Colors.purple, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: isOvulationDay 
                                ? Icon(Icons.egg, size: 16, color: Colors.white)
                                : isCurrentDay
                                    ? Icon(Icons.circle, size: 8, color: Colors.white)
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Date (show for important days)
                        if (isCurrentDay || isOvulationDay || day == 1 || day == _cycleLength)
                          Text(
                            DateFormat('d/M').format(cycleDate),
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Information cards
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                'Ovulation',
                DateFormat('MMM dd').format(ovulationDate),
                Icons.egg,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                'Fertile Window',
                '${DateFormat('MMM dd').format(firstDayOfCycle.add(Duration(days: fertileStartDay - 1)))} - ${DateFormat('MMM dd').format(ovulationDate)}',
                Icons.favorite,
                Colors.lightBlue[300]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Symptoms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    _selectedSymptoms.add(symptom);
                  }
                });
                if (_currentPeriod != null) {
                  _updateCurrentPeriod();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFE91E63).withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFE91E63)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  symptom,
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFFE91E63)
                        : Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moods.take(4).map((mood) => _buildMoodIcon(mood)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _moods.skip(4).take(3).map((mood) => _buildMoodIcon(mood)).toList(),
        ),
      ],
    );
  }

  Widget _buildMoodIcon(String mood) {
    final isSelected = _selectedMood == mood;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
        if (_currentPeriod != null) {
          _updateCurrentPeriod();
        }
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFE91E63)
                  : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFE91E63)
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              _getMoodIcon(mood),
              color: isSelected ? Colors.white : const Color(0xFFE91E63),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mood,
            style: TextStyle(
              fontSize: 12,
              color: isSelected 
                  ? const Color(0xFFE91E63)
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor({
    required bool isPeriodDay,
    required bool isCurrentDay,
    required bool isOvulationDay,
    required bool isFertileDay,
  }) {
    if (isCurrentDay && isPeriodDay) return Colors.purple;
    if (isPeriodDay) return const Color(0xFFE91E63);
    if (isOvulationDay) return Colors.blue;
    if (isFertileDay) return Colors.lightBlue[300]!;
    return Colors.grey[300]!;
  }

  void _showDayDetails(int day, DateTime date, bool isOvulation, bool isFertile, bool isPeriod) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cycle Day $day',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBarColor(
                      isPeriodDay: isPeriod,
                      isCurrentDay: day == _getCurrentCycleDay(),
                      isOvulationDay: isOvulation,
                      isFertileDay: isFertile,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMM dd').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (isPeriod) ...[
              _buildDetailRow(Icons.water_drop, 'Period Day', 'Day ${day} of $_periodLength', const Color(0xFFE91E63)),
              const SizedBox(height: 12),
            ],
            
            if (isOvulation) ...[
              _buildDetailRow(Icons.egg, 'Ovulation Day', 'Most fertile day', Colors.blue),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.info_outline, 'Note', 'Best time for conception', Colors.orange),
              const SizedBox(height: 12),
            ],
            
            if (isFertile && !isOvulation) ...[
              _buildDetailRow(Icons.favorite, 'Fertile Window', 'High fertility', Colors.lightBlue[300]!),
              const SizedBox(height: 12),
            ],
            
            if (!isPeriod && !isFertile) ...[
              _buildDetailRow(Icons.check_circle, 'Regular Day', 'Low fertility', Colors.grey),
              const SizedBox(height: 12),
            ],
            
            // Next period prediction
            if (day == _getCurrentCycleDay()) ...[
              const Divider(height: 24),
              _buildDetailRow(
                Icons.calendar_today, 
                'Next Period', 
                'Expected ${DateFormat('MMM dd').format(_calculateNextPeriod())}',
                Colors.pink,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCyclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Cycles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showCycleHistory,
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFFE91E63)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_periodHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No period history yet'),
          )
        else
          Column(
            children: _periodHistory.take(3).map((period) {
              final duration = period.endDate != null 
                  ? period.endDate!.difference(period.startDate).inDays + 1
                  : DateTime.now().difference(period.startDate).inDays + 1;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE91E63),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Started ${DateFormat('MMM dd').format(period.startDate)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$duration days • ${period.flowIntensity ?? "Medium"} flow',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (period.endDate == null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Happy': return Icons.sentiment_very_satisfied;
      case 'Sad': return Icons.sentiment_very_dissatisfied;
      case 'Anxious': return Icons.sentiment_dissatisfied;
      case 'Irritable': return Icons.mood_bad;
      case 'Energetic': return Icons.battery_charging_full;
      case 'Tired': return Icons.battery_0_bar;
      case 'Calm': return Icons.sentiment_satisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  void _showCycleHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFE91E63),
            title: const Text('Cycle History'),
            centerTitle: true,
          ),
          body: _periodHistory.isEmpty
              ? const Center(child: Text('No period history yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _periodHistory.length,
                  itemBuilder: (context, index) {
                    final period = _periodHistory[index];
                    final duration = period.endDate != null 
                        ? period.endDate!.difference(period.startDate).inDays + 1
                        : DateTime.now().difference(period.startDate).inDays + 1;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Color(0xFFE91E63),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Started ${DateFormat('MMM dd, yyyy').format(period.startDate)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  period.endDate != null
                                      ? 'Ended ${DateFormat('MMM dd').format(period.endDate!)}'
                                      : 'Ongoing',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$duration days • ${period.flowIntensity ?? "Medium"} flow',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}