// lib/features/tracking/screens/water_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/repositories/water_repository.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:user_onboarding/features/tracking/screens/water_history_page.dart';
import 'package:intl/intl.dart';


class WaterLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const WaterLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<WaterLoggingPage> createState() => _WaterLoggingPageState();
}

class _WaterLoggingPageState extends State<WaterLoggingPage> {
  WaterEntry? _todayEntry;
  bool _isLoading = true;
  bool _isSaving = false;
  int _dailyGoal = 8; 
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool _showCalendar = false;

  // Constants for calculations
  static const double mlPerGlass = 250.0; // 250ml per glass
  static const double defaultTarget = 2000.0; // 2L default target

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.userProfile.waterIntakeGlasses ?? 8;
    _loadWaterForDate(_selectedDate);
  }

  Future<void> _loadWaterForDate(DateTime date) async {
    if (widget.userProfile.id == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final entry = await WaterRepository.getWaterEntryByDate(
        widget.userProfile.id!, 
        date
      );
      
      setState(() {
        _selectedDate = date;
        _todayEntry = entry ?? WaterEntry(
          userId: widget.userProfile.id!,
          date: date,
          glassesConsumed: 0,
          totalMl: 0.0,
          targetMl: defaultTarget,
        );
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading water data for date: $e');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to load water data: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadWaterForDate(date),
            ),
          ),
        );
      }
      
      // Initialize with empty entry on error
      setState(() {
        _selectedDate = date;
        _todayEntry = WaterEntry(
          userId: widget.userProfile.id!,
          date: date,
          glassesConsumed: 0,
          totalMl: 0.0,
          targetMl: defaultTarget,
        );
      });
    }
  }

  Future<void> _saveWaterEntry() async {
    if (_todayEntry == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      await WaterRepository.saveWaterEntry(_todayEntry!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Water intake saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving water entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving water intake: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addGlass() {
    if (_todayEntry == null) return;
    
    setState(() {
      _todayEntry = _todayEntry!.copyWith(
        glassesConsumed: _todayEntry!.glassesConsumed + 1,
        totalMl: (_todayEntry!.glassesConsumed + 1) * mlPerGlass,
        updatedAt: DateTime.now(),
      );
    });
    
    _saveWaterEntry();
  }

  void _removeGlass() {
    if (_todayEntry == null || _todayEntry!.glassesConsumed <= 0) return;
    
    setState(() {
      _todayEntry = _todayEntry!.copyWith(
        glassesConsumed: _todayEntry!.glassesConsumed - 1,
        totalMl: (_todayEntry!.glassesConsumed - 1) * mlPerGlass,
        updatedAt: DateTime.now(),
      );
    });
    
    _saveWaterEntry();
  }

  void _resetDaily() {
    if (_todayEntry == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Daily Water'),
        content: const Text('Are you sure you want to reset today\'s water intake to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _todayEntry = _todayEntry!.copyWith(
                  glassesConsumed: 0,
                  totalMl: 0.0,
                  updatedAt: DateTime.now(),
                );
              });
              _saveWaterEntry();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_showCalendar 
            ? 'Select Date' 
            : 'Water Tracking - ${DateFormat('MMM d').format(_selectedDate)}'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_showCalendar ? Icons.close : Icons.calendar_month),
              onPressed: () {
                setState(() {
                  _showCalendar = !_showCalendar;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaterHistoryPage(userProfile: widget.userProfile),
                  ),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadWaterForDate(_selectedDate),
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Calendar (collapsible)
                    if (_showCalendar) _buildCalendar(),
                    
                    // Date indicator if not today
                    if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
                      _buildDateIndicator(),
                    
                    // Existing widgets
                    _buildWaterProgress(),
                    const SizedBox(height: 30),
                    _buildWaterControls(),
                    const SizedBox(height: 30),
                    _buildWaterTips(),
                  ],
                ),
              ),
        ),
      );
    }

  Widget _buildTodayHeader() {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(today);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now(),
        focusedDay: _selectedDate,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _showCalendar = false;
          });
          _loadWaterForDate(selectedDay);
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDateIndicator() {
    if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
      return const SizedBox.shrink();
    }
    
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Viewing water intake for ${DateFormat('EEEE, MMM d').format(_selectedDate)}',
            style: const TextStyle(color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterProgress() {
    if (_todayEntry == null) return const SizedBox.shrink();
    
    final progress = _todayEntry!.totalMl / _todayEntry!.targetMl;
    final progressClamped = progress.clamp(0.0, 1.0);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Circular Progress
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 180,
                      width: 180,
                      child: CircularProgressIndicator(
                        value: progressClamped,
                        strokeWidth: 12,
                        backgroundColor: Colors.blue.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress >= 1.0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 40,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_todayEntry!.glassesConsumed}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'glasses',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Progress Text
            Text(
              '${_todayEntry!.totalMl.toInt()}ml / ${_todayEntry!.targetMl.toInt()}ml',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '${(progress * 100).toInt()}% of daily goal',
              style: TextStyle(
                fontSize: 14,
                color: progress >= 1.0 ? Colors.green : Colors.grey[600],
              ),
            ),
            
            if (progress >= 1.0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 4),
                  const Text(
                    'Goal achieved! 🎉',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Remove Glass Button
                ElevatedButton.icon(
                  onPressed: _todayEntry?.glassesConsumed != null && _todayEntry!.glassesConsumed > 0 
                      ? _removeGlass 
                      : null,
                  icon: const Icon(Icons.remove),
                  label: const Text('Remove Glass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade700,
                  ),
                ),
                
                // Add Glass Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _addGlass,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_isSaving ? 'Saving...' : 'Add Glass'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Reset Button
            OutlinedButton.icon(
              onPressed: _resetDaily,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Today'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWaterTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Hydration Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Drink a glass of water when you wake up'),
            const Text('• Set reminders every 2 hours'),
            const Text('• Eat water-rich foods like fruits and vegetables'),
            const Text('• Monitor urine color for hydration levels'),
            const Text('• Drink more during exercise and hot weather'),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      await _loadWaterForDate(_selectedDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Water data refreshed successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing water data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}