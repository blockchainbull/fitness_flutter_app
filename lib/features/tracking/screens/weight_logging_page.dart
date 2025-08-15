// lib/features/tracking/screens/weight_logging_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/services/data_manager.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/features/profile/screens/edit_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WeightLoggingPage extends StatefulWidget {
  final UserProfile userProfile;

  const WeightLoggingPage({Key? key, required this.userProfile}) : super(key: key);

  @override
  State<WeightLoggingPage> createState() => _WeightLoggingPageState();
}

class _WeightLoggingPageState extends State<WeightLoggingPage> with WidgetsBindingObserver {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final DataManager _dataManager = DataManager();
  final ApiService _apiService = ApiService();
  
  UserProfile? _currentUserProfile;
  List<WeightEntry> _weightHistory = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentUserProfile = widget.userProfile;
    _loadWeightHistory();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Refresh when app comes back to foreground
    if (state == AppLifecycleState.resumed && mounted) {
      print('🔄 App resumed, refreshing weight tracking data...');
      _refreshUserProfile();
    }
  }

  Future<void> _loadInitialData() async {
    print('🔄 Loading initial data for weight tracking data...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh both profile and weight history in parallel
      await Future.wait([
        _refreshUserProfile(),
        _loadWeightHistory(),
      ]);
    } catch (e) {
      print('❌ Error loading initial data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWeightHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _dataManager.getWeightHistory(
        widget.userProfile.id ?? '',
        limit: 100,
      );
      
      setState(() {
        _weightHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading weight history: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load weight history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveWeightEntry(double weight, String notes, DateTime dateTime) async {
    if (widget.userProfile.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final weightEntry = WeightEntry(
        userId: widget.userProfile.id!,
        date: dateTime,
        weight: weight,
        notes: notes.trim().isNotEmpty ? notes.trim() : null,
      );

      await _dataManager.saveWeightEntry(weightEntry);
      
      // Save to SharedPreferences for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      final dateStr = DateFormat('yyyy-MM-dd').format(dateTime);
      await prefs.setBool('weight_logged_$dateStr', true);
      await prefs.setDouble('weight_$dateStr', weight);
      await prefs.setString('weight_time_$dateStr', dateTime.toIso8601String());
      if (notes.trim().isNotEmpty) {
        await prefs.setString('weight_notes_$dateStr', notes.trim());
      }
      print('✅ Weight saved to SharedPreferences: $dateStr = ${weight}kg');
      
      // Update user's current weight in profile only if this is the most recent entry
      final now = DateTime.now();
      if (dateTime.isAfter(now.subtract(const Duration(hours: 24)))) {
        await _dataManager.updateUserWeight(widget.userProfile.id!, weight);
      }
      
      // Reload history to show new entry
      await _loadWeightHistory();
      
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight entry saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving weight entry: $e');
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save weight entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  UserProfile get currentUserProfile => _currentUserProfile ?? widget.userProfile;
  
  double get currentWeight {
    if (_weightHistory.isNotEmpty) {
      return _weightHistory.first.weight;
    }
    return currentUserProfile.weight ?? 0; // Use currentUserProfile
  }
  
  double get targetWeight => widget.userProfile.targetWeight ?? 0;
  
  double get startingWeight {
    // Priority 1: Use the locked starting weight from profile
    if (widget.userProfile.startingWeight != null) {
      return widget.userProfile.startingWeight!;
    }
    
    // Priority 2: Use the last (oldest) weight entry as starting point
    if (_weightHistory.isNotEmpty) {
      return _weightHistory.last.weight;
    }
    
    // Priority 3: Use the current profile weight
    if (widget.userProfile.weight != null && widget.userProfile.weight! > 0) {
      return widget.userProfile.weight!;
    }
    
    // Priority 4: Fallback to current weight
    return currentWeight;
  }

  double get weeklyChange {
    if (_weightHistory.length < 2) return 0;
    
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentEntries = _weightHistory.where((entry) => entry.date.isAfter(oneWeekAgo)).toList();
    
    if (recentEntries.length < 2) return 0;
    
    return recentEntries.first.weight - recentEntries.last.weight;
  }

  double get monthlyChange {
    if (_weightHistory.length < 2) return 0;
    
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentEntries = _weightHistory.where((entry) => entry.date.isAfter(oneMonthAgo)).toList();
    
    if (recentEntries.length < 2) return 0;
    
    return recentEntries.first.weight - recentEntries.last.weight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Tracking'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showWeightHistory(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print('🔄 Manual refresh triggered');
              await _refreshUserProfile();
              await _loadWeightHistory();
            }
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeightHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentWeightCard(),
                    const SizedBox(height: 20),
                    if (_weightHistory.isNotEmpty) ...[
                      _buildProgressChart(),
                      const SizedBox(height: 20),
                      _buildGoalProgress(),
                      const SizedBox(height: 20),
                      _buildQuickStats(),
                      const SizedBox(height: 20),
                    ],
                    _buildRecentEntries(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _showAddWeightDialog,
        backgroundColor: _isSaving ? Colors.grey : Colors.indigo,
        child: _isSaving 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCurrentWeightCard() {
    final weightChange = currentWeight - startingWeight;
    final isLoss = weightChange < 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Current Weight',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currentWeight.toStringAsFixed(1)} kg',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeightStat('Target', '${targetWeight.toStringAsFixed(1)} kg'),
              _buildWeightStat('Change', '${isLoss ? '' : '+'}${weightChange.toStringAsFixed(1)} kg'),
              _buildWeightStat('To Go', '${(targetWeight - currentWeight).abs().toStringAsFixed(1)} kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildWeightJourneyCard() {
    // Use the actual starting weight from profile, with fallback logic
    final actualStartingWeight = widget.userProfile.startingWeight ?? 
                                (currentWeight + 2.0); // Estimated if not set
    
    final weightChange = actualStartingWeight - currentWeight;
    final isLoss = weightChange > 0;
    
    // If starting weight is not properly set, show a warning
    final bool needsStartingWeight = widget.userProfile.startingWeight == null;
    
    // ADDED: Calculate days tracking
    final daysTracking = widget.userProfile.startingWeightDate != null 
        ? DateTime.now().difference(widget.userProfile.startingWeightDate!).inDays 
        : (_weightHistory.isNotEmpty 
            ? DateTime.now().difference(_weightHistory.last.date).inDays 
            : 0);
    
    // ADDED: Calculate progress percentage
    final progressPercentage = targetWeight != 0 && actualStartingWeight != targetWeight
        ? ((actualStartingWeight - currentWeight) / (actualStartingWeight - targetWeight)).clamp(0.0, 1.0)
        : 0.0;
    
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              needsStartingWeight ? Colors.orange.shade50 : Colors.blue.shade50,
              needsStartingWeight ? Colors.red.shade50 : Colors.indigo.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show warning if starting weight not set
              if (needsStartingWeight) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Starting weight not set. Progress calculation may be inaccurate.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              Row(
                children: [
                  Icon(Icons.timeline, color: Colors.indigo, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Your Weight Journey',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Progress timeline
              Row(
                children: [
                  // Starting point
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Icon(Icons.flag, color: Colors.blue, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Started',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${actualStartingWeight.toStringAsFixed(1)} kg', // FIXED: Use actualStartingWeight
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.userProfile.startingWeightDate != null)
                          Text(
                            DateFormat('MMM dd').format(widget.userProfile.startingWeightDate!),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Progress line
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  colors: isLoss 
                                      ? [Colors.green.shade300, Colors.green.shade600]
                                      : [Colors.orange.shade300, Colors.orange.shade600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          isLoss ? Icons.trending_down : Icons.trending_up,
                          color: isLoss ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        Text(
                          '${isLoss ? '-' : '+'}${weightChange.abs().toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 14,
                            color: isLoss ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Current point
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.indigo, width: 2),
                          ),
                          child: Icon(Icons.person, color: Colors.indigo, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Journey stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildJourneyStatColumn(
                      'Days Tracking',
                      '$daysTracking',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    _buildJourneyStatColumn(
                      'Weekly Avg',
                      daysTracking > 0 
                          ? '${(weightChange / (daysTracking / 7)).toStringAsFixed(2)} kg'
                          : '0.0 kg',
                      Icons.show_chart,
                      isLoss ? Colors.green : Colors.orange,
                    ),
                    if (targetWeight > 0) ...[
                      _buildJourneyStatColumn(
                        'Progress',
                        '${(progressPercentage * 100).toStringAsFixed(1)}%',
                        Icons.track_changes,
                        Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Motivational message
              if (weightChange.abs() > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLoss ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLoss ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoss ? Icons.celebration : Icons.trending_up,
                        color: isLoss ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isLoss 
                              ? 'Great progress! You\'ve lost ${weightChange.toStringAsFixed(1)} kg since you started.'
                              : 'You\'ve gained ${weightChange.abs().toStringAsFixed(1)} kg since starting your journey.',
                          style: TextStyle(
                            color: isLoss ? Colors.green.shade700 : Colors.orange.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourneyStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressChart() {
    if (_weightHistory.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No weight data available'),
          ),
        ),
      );
    }

    // Show last 10 entries for the chart
    final chartData = _weightHistory.reversed.take(10).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weight Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: chartData.length,
                itemBuilder: (context, index) {
                  final entry = chartData[index];
                  final weight = entry.weight;
                  final date = entry.date;
                  
                  // Calculate height based on weight range
                  final minWeight = chartData.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
                  final maxWeight = chartData.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
                  final weightRange = maxWeight - minWeight;
                  final normalizedHeight = weightRange > 0 
                      ? ((weight - minWeight) / weightRange) * 120 + 20
                      : 70.0;

                  return Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${weight.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: normalizedHeight,
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgress() {
    if (targetWeight <= 0) return const SizedBox.shrink();

    final totalToLose = startingWeight - targetWeight;
    final currentProgress = startingWeight - currentWeight;
    final progressPercentage = totalToLose > 0 ? (currentProgress / totalToLose).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progressPercentage >= 1.0 ? Colors.green : Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressPercentage * 100).toStringAsFixed(1)}% Complete',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${currentProgress.toStringAsFixed(1)} kg of ${totalToLose.toStringAsFixed(1)} kg goal',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_weightHistory.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Weekly Change', '${weeklyChange >= 0 ? '+' : ''}${weeklyChange.toStringAsFixed(1)} kg', 
                    weeklyChange < 0 ? Colors.green : Colors.red),
                _buildStatColumn('Monthly Change', '${monthlyChange >= 0 ? '+' : ''}${monthlyChange.toStringAsFixed(1)} kg',
                    monthlyChange < 0 ? Colors.green : Colors.red),
                _buildStatColumn('BMI', _calculateBMI().toStringAsFixed(1), Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentEntries() {
    final recentEntries = _weightHistory.take(5).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Entries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_weightHistory.isNotEmpty)
                  TextButton(
                    onPressed: _showWeightHistory,
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentEntries.isEmpty) ...[
              // Show profile weight info when no entries exist
              if (widget.userProfile.weight != null && widget.userProfile.weight! > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile Weight: ${widget.userProfile.weight!.toStringAsFixed(1)} kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Start tracking to see your progress!',
                                  style: TextStyle(
                                    color: Colors.grey[600], 
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showAddWeightDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Log Your First Weight'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Original empty state for users with no profile weight
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'No weight entries yet.\nTap the + button to add your first entry!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Show actual weight entries
              ...recentEntries.map((entry) => _buildEntryTile(entry)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(WeightEntry entry) {
    final isToday = _isToday(entry.date);
    final isYesterday = _isYesterday(entry.date);
    
    String dateText;
    if (isToday) {
      dateText = 'Today, ${DateFormat('h:mm a').format(entry.date)}';
    } else if (isYesterday) {
      dateText = 'Yesterday, ${DateFormat('h:mm a').format(entry.date)}';
    } else {
      dateText = DateFormat('MMM dd, h:mm a').format(entry.date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.monitor_weight, color: Colors.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateText,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (entry.notes != null && entry.notes!.isNotEmpty)
                  Text(
                    entry.notes!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () => _editWeightEntry(entry),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDeleteEntry(entry),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  double _calculateBMI() {
    final heightInMeters = (widget.userProfile.height ?? 170) / 100;
    return currentWeight / (heightInMeters * heightInMeters);
  }

  void _showAddWeightDialog() {
    _weightController.clear();
    _notesController.clear();
    DateTime selectedDateTime = DateTime.now(); // Local variable for dialog
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Weight Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDateTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)), // 2 years ago
                        lastDate: DateTime.now(),
                      );
                      
                      if (date != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                
                // Time Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    subtitle: Text(DateFormat('h:mm a').format(selectedDateTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Quick time buttons
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickTimeButton('Now', DateTime.now(), selectedDateTime, setDialogState, (dt) => selectedDateTime = dt),
                    _buildQuickTimeButton('Morning', _getTodayAt(7, 0), selectedDateTime, setDialogState, (dt) => selectedDateTime = dt),
                    _buildQuickTimeButton('Afternoon', _getTodayAt(14, 0), selectedDateTime, setDialogState, (dt) => selectedDateTime = dt),
                    _buildQuickTimeButton('Evening', _getTodayAt(19, 0), selectedDateTime, setDialogState, (dt) => selectedDateTime = dt),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'e.g., After workout, before breakfast...',
                  ),
                  maxLines: 2,
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
              onPressed: () {
                if (_weightController.text.isNotEmpty) {
                  final weight = double.tryParse(_weightController.text);
                  if (weight != null && weight > 0) {
                    Navigator.pop(context);
                    _saveWeightEntry(weight, _notesController.text, selectedDateTime);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid weight'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your weight'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTimeButton(
    String label, 
    DateTime time, 
    DateTime selectedDateTime, 
    StateSetter setDialogState, 
    Function(DateTime) onTimeSelected
  ) {
    final isSelected = selectedDateTime.year == time.year &&
                      selectedDateTime.month == time.month &&
                      selectedDateTime.day == time.day &&
                      selectedDateTime.hour == time.hour &&
                      selectedDateTime.minute == time.minute;

    return ActionChip(
      label: Text(label),
      onPressed: () {
        setDialogState(() {
          onTimeSelected(time);
        });
      },
      backgroundColor: isSelected ? Colors.indigo : null,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
      ),
    );
  }

  DateTime _getTodayAt(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Add edit functionality
  void _editWeightEntry(WeightEntry entry) {
    _weightController.text = entry.weight.toString();
    _notesController.text = entry.notes ?? '';
    DateTime selectedDateTime = entry.date; // Local variable for edit dialog
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Weight Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(selectedDateTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                        lastDate: DateTime.now(),
                      );
                      
                      if (date != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            selectedDateTime.hour,
                            selectedDateTime.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                
                // Time Selection
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    subtitle: Text(DateFormat('h:mm a').format(selectedDateTime)),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            selectedDateTime.year,
                            selectedDateTime.month,
                            selectedDateTime.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
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
              onPressed: () async {
                if (_weightController.text.isNotEmpty) {
                  final weight = double.tryParse(_weightController.text);
                  if (weight != null && weight > 0) {
                    Navigator.pop(context);
                    
                    // Delete old entry and create new one
                    if (entry.id != null) {
                      await _dataManager.deleteWeightEntry(entry.id!);
                    }
                    
                    await _saveWeightEntry(weight, _notesController.text, selectedDateTime);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid weight'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEntry(WeightEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete the weight entry of ${entry.weight.toStringAsFixed(1)} kg from ${DateFormat('MMM dd, yyyy').format(entry.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteEntry(entry);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshUserProfile() async {
    try {
      print('🔄 Force refreshing user profile...');
      
      // Get the current user ID
      final userId = currentUserProfile.id;
      if (userId == null) {
        print('❌ No user ID found');
        return;
      }
      
      // Force reload from API (bypass cache)
      final updatedProfile = await _apiService.getUserProfileById(userId);
      if (updatedProfile != null) {
        setState(() {
          _currentUserProfile = updatedProfile;
        });
        print('✅ User profile refreshed: ${updatedProfile.weight} kg');
      } else {
        print('❌ No updated profile returned from API');
      }
    } catch (e) {
      print('❌ Error refreshing user profile: $e');
    }
  }

  void _navigateToProfile() async {
    // Navigate to profile page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userProfile: currentUserProfile),
      ),
    );
    
    // If profile was updated, refresh the data
    if (result != null) {
      await _refreshUserProfile();
      await _loadWeightHistory();
    }
  }

  Future<void> _deleteEntry(WeightEntry entry) async {
    try {
      if (entry.id != null) {
        await _dataManager.deleteWeightEntry(entry.id!);
      }
      
      // Reload the history
      await _loadWeightHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weight entry deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting weight entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showWeightHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeightHistoryPage(
         weightHistory: _weightHistory,
         onEntryDeleted: _loadWeightHistory,
       ),
     ),
   );
 }
}

// Separate page for viewing all weight history
class WeightHistoryPage extends StatelessWidget {
 final List<WeightEntry> weightHistory;
 final VoidCallback onEntryDeleted;

 const WeightHistoryPage({
   Key? key,
   required this.weightHistory,
   required this.onEntryDeleted,
 }) : super(key: key);

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Weight History'),
       backgroundColor: Colors.indigo,
       foregroundColor: Colors.white,
     ),
     body: weightHistory.isEmpty
         ? const Center(
             child: Text(
               'No weight entries yet.\nStart tracking your weight progress!',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.grey, fontSize: 16),
             ),
           )
         : ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: weightHistory.length,
             itemBuilder: (context, index) {
               final entry = weightHistory[index];
               return Card(
                 child: ListTile(
                   leading: CircleAvatar(
                     backgroundColor: Colors.indigo.withOpacity(0.1),
                     child: const Icon(Icons.monitor_weight, color: Colors.indigo),
                   ),
                   title: Text('${entry.weight.toStringAsFixed(1)} kg'),
                   subtitle: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(DateFormat('EEEE, MMM dd, yyyy').format(entry.date)),
                       Text(
                         DateFormat('h:mm a').format(entry.date),
                         style: TextStyle(
                           color: Colors.grey[600],
                           fontSize: 12,
                         ),
                       ),
                       if (entry.notes != null && entry.notes!.isNotEmpty)
                         Text(
                           entry.notes!,
                           style: const TextStyle(fontStyle: FontStyle.italic),
                         ),
                     ],
                   ),
                   trailing: PopupMenuButton<String>(
                     onSelected: (value) {
                       if (value == 'delete') {
                         _confirmDelete(context, entry);
                       }
                     },
                     itemBuilder: (context) => [
                       const PopupMenuItem(
                         value: 'delete',
                         child: Row(
                           children: [
                             Icon(Icons.delete_outline, color: Colors.red),
                             SizedBox(width: 8),
                             Text('Delete'),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
               );
             },
           ),
   );
 }

 void _confirmDelete(BuildContext context, WeightEntry entry) {
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: const Text('Delete Entry'),
       content: Text(
         'Are you sure you want to delete the weight entry of ${entry.weight.toStringAsFixed(1)} kg from ${DateFormat('MMM dd, yyyy').format(entry.date)}?'
       ),
       actions: [
         TextButton(
           onPressed: () => Navigator.pop(context),
           child: const Text('Cancel'),
         ),
         ElevatedButton(
           onPressed: () {
             Navigator.pop(context);
             _deleteEntry(context, entry);
           },
           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
           child: const Text('Delete'),
         ),
       ],
     ),
   );
 }

 Future<void> _deleteEntry(BuildContext context, WeightEntry entry) async {
   try {
     if (entry.id != null) {
       await DataManager().deleteWeightEntry(entry.id!);
     }
     
     onEntryDeleted();
     
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Weight entry deleted'),
           backgroundColor: Colors.green,
         ),
       );
     }
   } catch (e) {
     print('Error deleting weight entry: $e');
     if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Failed to delete entry: $e'),
           backgroundColor: Colors.red,
         ),
       );
     }
   }
 }
}