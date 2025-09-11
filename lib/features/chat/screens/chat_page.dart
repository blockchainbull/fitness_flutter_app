// lib/features/chat/screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/data/services/chat_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final UserProfile userProfile;

  const ChatPage({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userContext;
  Map<String, dynamic>? _userFramework;
  bool _isLoadingContext = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load user context first
    await _loadUserContext();
    
    // Then show welcome message with context awareness
    _showContextAwareWelcome();
  }
  
  Future<void> _loadUserContext() async {
    setState(() {
      _isLoadingContext = true;
    });
    
    try {
      final context = await ChatService.getUserContext(widget.userProfile.id);
      
      setState(() {
        _userContext = context;
        _isLoadingContext = false;
      });
      
      print('[ChatPage] Context loaded: ${context.keys}');
      
      // Log what data we have
      final todayProgress = context['today_progress'] ?? {};
      print('[ChatPage] Today\'s data:');
      print('  - Meals: ${todayProgress['meals_logged']}');
      print('  - Calories: ${todayProgress['total_calories']}');
      print('  - Water: ${todayProgress['water_glasses']} glasses');
      print('  - Steps: ${todayProgress['steps']}');
      print('  - Exercise: ${todayProgress['exercise_minutes']} min');
      print('  - Weight: ${todayProgress['weight_logged']}');
      
    } catch (e) {
      print('[ChatPage] Error loading context: $e');
      setState(() {
        _isLoadingContext = false;
      });
    }
  }
  
  void _showContextAwareWelcome() {
    final userName = widget.userProfile.name.isNotEmpty 
        ? widget.userProfile.name : 'there';
    
    String welcomeMessage = 'Hi $userName! 👋\n\n';
    
    if (_userContext != null) {
      final todayProgress = _userContext!['today_progress'] ?? {};
      final weeklySum = _userContext!['weekly_summary'] ?? {};
      
      // Add context-aware greeting based on actual data
      welcomeMessage += 'I can see your activity data for today:\n';
      
      if (todayProgress['meals_logged'] != null && todayProgress['meals_logged'] > 0) {
        welcomeMessage += '• ${todayProgress['meals_logged']} meals logged (${todayProgress['total_calories']} calories)\n';
      }
      
      if (todayProgress['water_glasses'] != null && todayProgress['water_glasses'] > 0) {
        welcomeMessage += '• ${todayProgress['water_glasses']} glasses of water\n';
      }
      
      if (todayProgress['steps'] != null && todayProgress['steps'] > 0) {
        welcomeMessage += '• ${todayProgress['steps']} steps taken\n';
      }
      
      if (todayProgress['exercise_minutes'] != null && todayProgress['exercise_minutes'] > 0) {
        welcomeMessage += '• ${todayProgress['exercise_minutes']} minutes of exercise\n';
      }
      
      welcomeMessage += '\nWhat would you like to work on today?';
    } else {
      welcomeMessage += 'I\'m here to help with your health goals. What would you like to discuss?';
    }
    
    setState(() {
      _messages.add({
        'text': welcomeMessage,
        'isUser': false,
        'timestamp': DateTime.now(),
        'type': 'welcome',
        'hasContext': _userContext != null,
      });
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = {
      'text': text,
      'isUser': true,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _textController.clear();
    _scrollToBottom();

    // Refresh context for data-specific queries
    if (_shouldRefreshContext(text)) {
      await _loadUserContext();
    }

    try {
      String response;
      
      try {
        // Use the simplified sendMessage with context
        response = await ChatService.sendMessage(
          widget.userProfile.id!, 
          text,
          context: _userContext,  // Pass context if we have it
        );
      } catch (e) {
        print('API failed, using fallback: $e');
        response = _generateFallbackResponse(text);
      }
      
      final aiMessage = {
        'text': response,
        'isUser': false,
        'timestamp': DateTime.now(),
      };

      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
    } catch (e) {
      print('Error sending message: $e');
      
      final errorMessage = {
        'text': _generateFallbackResponse(text),
        'isUser': false,
        'timestamp': DateTime.now(),
        'type': 'fallback'
      };

      setState(() {
        _messages.add(errorMessage);
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _clearChatHistory() async {
    try {
      await _apiService.clearChatHistory(widget.userProfile.id!);
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat history cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear chat history')),
      );
    }
  }

  void _addWelcomeMessage() {
    final userName = widget.userProfile.name.isNotEmpty ? widget.userProfile.name : 'there';
    final goal = widget.userProfile.primaryGoal.isNotEmpty ? widget.userProfile.primaryGoal : 'your health goals';
    
    setState(() {
      _messages.add({
        'text': 'Hi $userName! 👋\n\nI\'m your AI health coach and I have access to all your health data, activity logs, and progress. I can help you with $goal and provide personalized recommendations based on your actual data.\n\nWhat would you like to talk about today?',
        'isUser': false,
        'timestamp': DateTime.now(),
        'type': 'welcome'
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _generateFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    final userName = widget.userProfile.name.isNotEmpty ? widget.userProfile.name : 'there';
    
    if (message.contains('dinner') || message.contains('food') || message.contains('eat')) {
      return 'Hi $userName! For dinner with your ${widget.userProfile.weightGoal.replaceAll('_', ' ')} goals, I recommend a balanced meal with lean protein like chicken or fish, plenty of vegetables, and complex carbs. Keep portions moderate and stay hydrated!';
    } else if (message.contains('exercise') || message.contains('workout')) {
      return 'Based on your ${widget.userProfile.fitnessLevel} fitness level, try mixing cardio with strength training. Start with 30 minutes of activity you enjoy - could be walking, cycling, or bodyweight exercises at home.';
    } else if (message.contains('progress') || message.contains('how am i doing')) {
      return 'You\'re doing great by staying engaged with your health journey! Keep logging your activities and meals. Consistency is key to reaching your goals.';
    } else if (message.contains('weight')) {
      final current = widget.userProfile.weight;
      final target = widget.userProfile.targetWeight;
      return 'Your current weight is ${current}kg and you\'re working toward ${target}kg. Focus on sustainable habits rather than quick fixes - you\'ve got this!';
    } else {
      return 'Hi $userName! I\'m here to help with your health journey. You can ask me about meal ideas, workout suggestions, progress tracking, or motivation. What would you like to know?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              child: Icon(Icons.smart_toy, color: Colors.purple[700]),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Health Coach',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Knows your data • Always available',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showContextInfo,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'framework',
                child: ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('My Framework'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'progress',
                child: ListTile(
                  leading: Icon(Icons.trending_up),
                  title: Text('Progress Summary'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'tips',
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('Quick Tips'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Chat'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Add loading indicator for context
          if (_isLoadingContext)
            LinearProgressIndicator(
              backgroundColor: Colors.purple[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          
          // Quick actions bar
          _buildQuickActions(),
          
          // Messages with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUserContext,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final showDateDivider = _shouldShowDateDivider(index);
                        return Column(
                          children: [
                            if (showDateDivider)
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        height: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        _formatDateDivider(message['timestamp']),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Colors.grey[300],
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            MessageBubble(
                              text: message['text'],
                              isUser: message['isUser'],
                              timestamp: message['timestamp'],
                              type: message['type'],
                              userProfile: widget.userProfile,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
          
          // "AI is typing" indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple[400]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is analyzing your data...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          
          // Input area
          ChatInput(
            controller: _textController,
            onSubmitted: _handleSubmitted,
            enabled: !_isTyping,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionChip('My Progress', Icons.trending_up, () {
                    _handleSubmitted('Show me my progress summary');
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionChip('Today\'s Plan', Icons.today, () {
                    _handleSubmitted('What should I focus on today?');
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionChip('Meal Ideas', Icons.restaurant, () {
                    _handleSubmitted('Suggest healthy meals based on my goals');
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionChip('Workout Tips', Icons.fitness_center, () {
                    _handleSubmitted('What exercises should I do today?');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () async {
        // For quick actions, use the context
        final message = _getQuickActionMessage(label);
        _handleSubmitted(message);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.purple[700]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChatHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showContextInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Coach Knowledge'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your AI coach has access to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildContextItem(Icons.person, 'Complete profile & goals'),
              _buildContextItem(Icons.restaurant, 'All meal logs & nutrition'),
              _buildContextItem(Icons.fitness_center, 'Exercise history & progress'),
              _buildContextItem(Icons.bedtime, 'Sleep patterns & quality'),
              _buildContextItem(Icons.monitor_weight, 'Weight tracking & trends'),
              _buildContextItem(Icons.medication, 'Supplement adherence'),
              _buildContextItem(Icons.water_drop, 'Hydration patterns'),
              const SizedBox(height: 12),
              Text(
                'Framework: ${_userFramework?['framework_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Loading...'}',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildContextItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'framework':
        _showFrameworkDetails();
        break;
      case 'progress':
        _handleSubmitted('Give me a detailed progress summary');
        break;
      case 'tips':
        _handleSubmitted('Give me 3 quick tips for today');
        break;
      case 'clear':
        _clearChat();
        break;
    }
  }

  bool _shouldShowDateDivider(int index) {
    if (index == 0) return true; // Always show for first message
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    final currentDate = currentMessage['timestamp'] as DateTime;
    final previousDate = previousMessage['timestamp'] as DateTime;
    
    // Show divider if messages are from different days
    return currentDate.day != previousDate.day ||
          currentDate.month != previousDate.month ||
          currentDate.year != previousDate.year;
  }

  // Add this method to format the date for the divider
  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // Full date
    }
  }

  String _getQuickActionMessage(String label) {
    switch (label) {
      case 'My Progress':
        return 'Show me my progress summary with specific numbers';
      case 'Today\'s Plan':
        return 'What should I focus on today based on my current progress?';
      case 'Meal Ideas':
        return 'Suggest healthy meals based on my goals and dietary preferences';
      case 'Workout Tips':
        return 'What exercises should I do today based on my fitness level?';
      default:
        return label;
    }
  }

  bool _shouldRefreshContext(String message) {
    final keywords = [
      'today', 'current', 'now', 'progress', 
      'calories', 'steps', 'water', 'weight',
      'meals', 'exercise', 'sleep', 'logged',
      'how many', 'how much', 'did i', 'have i'
    ];
    
    final lowerMessage = message.toLowerCase();
    return keywords.any((keyword) => lowerMessage.contains(keyword));
  }

  void _showFrameworkDetails() {
    if (_userFramework == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Framework data is loading...')),
      );
      return;
    }

    // Safe access to framework data
    final frameworkType = _userFramework!['framework_type']?.toString() ?? 'custom';
    final nutrition = _userFramework!['nutrition'] as Map<String, dynamic>? ?? {};
    final exercise = _userFramework!['exercise'] as Map<String, dynamic>? ?? {};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${frameworkType.replaceAll('_', ' ').toUpperCase()} Framework'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (nutrition['daily_calories'] != null)
                _buildFrameworkSection('Daily Calories', '${nutrition['daily_calories']} cal'),
              if (nutrition['macros']?['protein_grams'] != null)
                _buildFrameworkSection('Protein', '${nutrition['macros']['protein_grams']}g'),
              if (exercise['strength_sessions_week'] != null && exercise['cardio_minutes_week'] != null)
                _buildFrameworkSection('Exercise/Week', '${exercise['strength_sessions_week']} strength + ${exercise['cardio_minutes_week']} min cardio'),
              const SizedBox(height: 12),
              const Text('Ask me anything about your personalized plan!', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubmitted('Explain my personalized framework in detail');
            },
            child: const Text('Ask AI'),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameworkSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.purple[700])),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh context when app comes back to foreground
      _loadUserContext();
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? type;
  final UserProfile? userProfile; // Add this parameter

  const MessageBubble({
    Key? key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type,
    this.userProfile, // Add this parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWelcome = type == 'welcome';
    final isError = type == 'error';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isError ? Colors.red[100] : (isWelcome ? Colors.purple[100] : Colors.grey[200]),
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy,
                size: 16,
                color: isError ? Colors.red[700] : (isWelcome ? Colors.purple[700] : Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Colors.purple[500] 
                    : (isError ? Colors.red[50] : (isWelcome ? Colors.purple[50] : Colors.white)),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
                border: !isUser ? Border.all(color: Colors.grey[200]!) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.purple[100],
              child: Text(
                userProfile?.name.isNotEmpty == true 
                    ? userProfile!.name[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.purple[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final bool enabled;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSubmitted,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              decoration: InputDecoration(
                hintText: enabled ? 'Ask about your health data...' : 'AI is thinking...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.purple[400]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  onPressed: enabled ? () => onSubmitted(controller.text) : null,
                  icon: Icon(
                    Icons.send,
                    color: enabled ? Colors.purple[500] : Colors.grey[400],
                  ),
                ),
              ),
              onSubmitted: enabled ? onSubmitted : null,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}