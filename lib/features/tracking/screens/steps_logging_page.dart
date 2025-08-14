// lib/features/tracking/screens/steps_logging_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';
import 'package:user_onboarding/features/home/widgets/daily_step_tracker.dart';
import 'package:user_onboarding/features/tracking/screens/step_history_page.dart';

class StepsLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const StepsLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<StepsLoggingPage> createState() => _StepsLoggingPageState();
}

class _StepsLoggingPageState extends State<StepsLoggingPage> {
  StepEntry? _todayEntry;
  List<StepEntry> _weeklyHistory = [];
  bool _isLoading = true;
  
  final TextEditingController _manualStepsController = TextEditingController();
  final TextEditingController _goalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStepData();
  }

  @override
  void dispose() {
    _manualStepsController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadStepData() async {
    if (widget.userProfile.id == null) return;

    setState(() => _isLoading = true);

    try {
      // Load today's entry
      final todayEntry = await StepRepository.getTodayStepEntry(widget.userProfile.id!);
      
      // Load weekly history
      final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final weeklyData = await StepRepository.getStepEntriesInRange(
        widget.userProfile.id!,
        weekStart,
        DateTime.now(),
      );

      setState(() {
        _todayEntry = todayEntry ?? StepEntry(
          userId: widget.userProfile.id!,
          date: DateTime.now(),
          steps: 0,
          goal: 10000,
          caloriesBurned: 0.0,
          distanceKm: 0.0,
          activeMinutes: 0,
        );
        _weeklyHistory = weeklyData;
        _goalController.text = _todayEntry!.goal.toString();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading step data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveManualEntry() async {
    if (_todayEntry == null) return;

    final steps = int.tryParse(_manualStepsController.text);
    final goal = int.tryParse(_goalController.text);

    if (steps == null || steps < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid step count'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final updatedEntry = _todayEntry!.copyWith(
        steps: steps,
        goal: goal ?? _todayEntry!.goal,
        caloriesBurned: _calculateCalories(steps),
        distanceKm: _calculateDistance(steps),
        activeMinutes: _calculateActiveMinutes(steps),
        sourceType: 'manual',
        lastSynced: DateTime.now(),
      );

      await StepRepository.saveStepEntry(updatedEntry);
      
      setState(() {
        _todayEntry = updatedEntry;
      });

      _manualStepsController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Steps saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateCalories(int steps) {
    // Rough estimation: 0.04 calories per step (varies by weight)
    final userWeight = widget.userProfile.weight ?? 70;
    return steps * 0.04 * (userWeight / 70);
  }

  double _calculateDistance(int steps) {
    // Average step length: 0.78 meters
    return steps * 0.00078; // km
  }

  int _calculateActiveMinutes(int steps) {
    // Rough estimation: 100 steps = 1 minute of activity
    return (steps / 100).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Steps Tracking'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalytics(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'history':
                  _showHistory();
                  break;
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(
                      color: Colors.black,
                      Icons.history),
                    SizedBox(width: 8),
                    Text('History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      color: Colors.black,
                      Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset Today'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStepData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepTracker(),
                    const SizedBox(height: 24),
                    _buildManualEntry(),
                    const SizedBox(height: 24),
                    _buildWeeklyOverview(),
                    const SizedBox(height: 24),
                    _buildQuickStats(),
                    const SizedBox(height: 24),
                    _buildStepTips(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStepTracker() {
    if (_todayEntry == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Progress',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        DailyStepTracker(
          stepGoal: _todayEntry!.goal,
          stepsWalked: _todayEntry!.steps,
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Log Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _manualStepsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Steps',
                      hintText: 'Enter step count',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_walk),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Goal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveManualEntry,
                icon: const Icon(Icons.save),
                label: const Text('Save Steps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_weeklyHistory.isEmpty)
              const Center(
                child: Text(
                  'No data available for this week',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _buildWeeklyChart(),
            const SizedBox(height: 16),
            _buildWeeklyStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final maxSteps = _weeklyHistory.isNotEmpty 
        ? _weeklyHistory.map((e) => e.steps).reduce((a, b) => a > b ? a : b)
        : 10000;
    
    return Container(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final date = DateTime.now().subtract(Duration(days: 6 - index));
          final entry = _weeklyHistory.firstWhere(
            (e) => DateUtils.isSameDay(e.date, date),
            orElse: () => StepEntry(
              userId: widget.userProfile.id!,
              date: date,
              steps: 0,
              goal: 10000,
            ),
          );
          
          final heightPercent = maxSteps > 0 ? (entry.steps / maxSteps) : 0.0;
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                entry.steps.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 25,
                height: 80 * heightPercent.clamp(0.1, 1.0),
                decoration: BoxDecoration(
                  color: isToday 
                      ? Colors.green.shade700 
                      : entry.steps >= entry.goal
                          ? Colors.green.shade400
                          : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? Colors.green.shade700 : Colors.grey,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    if (_weeklyHistory.isEmpty) return const SizedBox();
    
    final totalSteps = _weeklyHistory.fold(0, (sum, entry) => sum + entry.steps);
    final avgSteps = (totalSteps / 7).round();
    final bestDay = _weeklyHistory.reduce((a, b) => a.steps > b.steps ? a : b);
    final goalsAchieved = _weeklyHistory.where((e) => e.steps >= e.goal).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatColumn('Total', totalSteps.toString()),
        _buildStatColumn('Average', avgSteps.toString()),
        _buildStatColumn('Best Day', bestDay.steps.toString()),
        _buildStatColumn('Goals Hit', '$goalsAchieved/7'),
      ],
    );
  }

  Widget _buildQuickStats() {
    if (_todayEntry == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDetailColumn(
                  'Calories',
                  '${_todayEntry!.caloriesBurned.toStringAsFixed(0)}',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildDetailColumn(
                  'Distance',
                  '${_todayEntry!.distanceKm.toStringAsFixed(2)} km',
                  Icons.straighten,
                  Colors.blue,
                ),
                _buildDetailColumn(
                  'Active Min',
                  '${_todayEntry!.activeMinutes}',
                  Icons.timer,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Step Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Take the stairs instead of the elevator\n'
              '• Park farther away from your destination\n'
              '• Take walking breaks during work\n'
              '• Walk while talking on the phone\n'
              '• Set reminders to move every hour',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Steps Analytics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (_todayEntry != null) ...[
                      ListTile(
                        leading: const Icon(Icons.today, color: Colors.blue),
                        title: const Text('Today\'s Progress'),
                        subtitle: Text('${_todayEntry!.steps} / ${_todayEntry!.goal} steps'),
                        trailing: Text('${((_todayEntry!.steps / _todayEntry!.goal) * 100).toInt()}%'),
                      ),
                      const Divider(),
                    ],
                    if (_weeklyHistory.isNotEmpty) ...[
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.green),
                        title: const Text('Weekly Average'),
                        subtitle: Text('${(_weeklyHistory.fold(0, (sum, e) => sum + e.steps) / 7).round()} steps/day'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.trending_up, color: Colors.orange),
                        title: const Text('Best Day This Week'),
                        subtitle: Text('${_weeklyHistory.reduce((a, b) => a.steps > b.steps ? a : b).steps} steps'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StepHistoryPage(userProfile: widget.userProfile),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Today\'s Steps'),
        content: const Text('Are you sure you want to reset today\'s step count to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_todayEntry != null) {
                final resetEntry = _todayEntry!.copyWith(
                  steps: 0,
                  caloriesBurned: 0.0,
                  distanceKm: 0.0,
                  activeMinutes: 0,
                );
                await StepRepository.saveStepEntry(resetEntry);
                setState(() => _todayEntry = resetEntry);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Steps reset to 0')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}