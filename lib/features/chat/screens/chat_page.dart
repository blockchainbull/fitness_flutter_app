import 'package:flutter/material.dart';
import 'package:user_onboarding/features/chat/widgets/message_bubble.dart';
import 'package:user_onboarding/features/chat/widgets/chat_input.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message from AI
    _addMessage('Hello! I\'m your AI health coach. How can I help you today?', false);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    });
    
    // Scroll to bottom after adding message
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    _textController.clear();
    _addMessage(text, true);
    
    // Simulate AI typing
    setState(() {
      _isTyping = true;
    });
    
    // TODO: Replace with actual API call to ChatGPT
    Future.delayed(const Duration(seconds: 1), () {
      _simulateAIResponse(text);
    });
  }

  // This is a temporary function to simulate AI responses
  // Will be replaced with actual ChatGPT API calls
  void _simulateAIResponse(String userMessage) {
    String response = '';
    
    // Simple keyword matching for demo purposes
    final lowerCaseMessage = userMessage.toLowerCase();
    
    if (lowerCaseMessage.contains('workout') || lowerCaseMessage.contains('exercise')) {
      response = 'Based on your goals and fitness level, I recommend focusing on a mix of strength training and cardio. Would you like me to suggest a specific workout for today?';
    } else if (lowerCaseMessage.contains('diet') || lowerCaseMessage.contains('food') || lowerCaseMessage.contains('eat')) {
      response = 'A balanced diet is essential for your fitness goals. Your current meal plan is designed to provide adequate protein and nutrients. Is there something specific about your diet you\'d like to discuss?';
    } else if (lowerCaseMessage.contains('weight') || lowerCaseMessage.contains('progress')) {
      response = 'You\'re making good progress! Remember that healthy weight change is gradual. Would you like to see your progress charts or discuss adjustments to your plan?';
    } else if (lowerCaseMessage.contains('sleep')) {
      response = 'Quality sleep is crucial for recovery and overall health. Your records show you\'ve been averaging 7.2 hours per night this week. Would you like some tips to improve sleep quality?';
    } else if (lowerCaseMessage.contains('motivate') || lowerCaseMessage.contains('difficult') || lowerCaseMessage.contains('hard')) {
      response = 'It\'s normal to face challenges on your fitness journey. Remember why you started and focus on small, consistent improvements. What specific challenge are you facing right now?';
    } else {
      response = 'Thank you for your message. Is there a specific aspect of your health and fitness journey you\'d like guidance on today?';
    }
    
    setState(() {
      _isTyping = false;
    });
    
    _addMessage(response, false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Coach'),
        centerTitle: true,
        backgroundColor: Colors.purple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show info about AI coach
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Your AI Coach'),
                  content: const Text(
                    'Your AI Health Coach uses advanced machine learning to provide personalized fitness and nutrition guidance. '
                    'The coach learns from your data and adapts recommendations to help you reach your goals more effectively.\n\n'
                    'All conversations are private and used only to improve your experience.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return MessageBubble(
                    text: message['text'],
                    isUser: message['isUser'],
                    timestamp: message['timestamp'],
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
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is typing...',
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
          ),
        ],
      ),
    );
  }
}