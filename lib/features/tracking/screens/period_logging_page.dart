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
    final ovulationDay = ovulationDate.difference(
      DateTime.now().subtract(Duration(days: cycleDay - 1))
    ).inDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cycle Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          child: Row(
            children: List.generate(28, (index) {
              final day = index + 1;
              final isPeriodDay = day <= _periodLength;
              final isCurrentDay = day == cycleDay;
              final isOvulationDay = day == ovulationDay;
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isCurrentDay
                        ? const Color(0xFFE91E63)
                        : isPeriodDay
                            ? Colors.pink[200]
                            : isOvulationDay
                                ? Colors.blue[200]
                                : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isCurrentDay
                      ? const Center(
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.white,
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend('Period', Colors.pink[200]!),
            const SizedBox(width: 24),
            _buildLegend('Ovulation', Colors.blue[200]!),
            const SizedBox(width: 24),
            _buildLegend('Today', const Color(0xFFE91E63)),
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