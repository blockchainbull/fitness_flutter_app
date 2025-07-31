// lib/features/chat/screens/chat_page.dart
import 'package:flutter/material.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/services/chat_service.dart';
import 'package:user_onboarding/features/chat/widgets/message_bubble.dart';
import 'package:user_onboarding/features/chat/widgets/chat_input.dart';

class ChatPage extends StatefulWidget {
  final UserProfile? userProfile;
  
  const ChatPage({Key? key, this.userProfile}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    print('=== CHAT DEBUG INFO ===');
    print('UserProfile: ${widget.userProfile}');
    print('UserProfile ID: ${widget.userProfile?.id}');
    print('UserProfile Email: ${widget.userProfile?.email}');
    print('========================');

    _loadChatHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final userId = widget.userProfile?.id ?? 'guest';
      print('🔍 DEBUG: Using userId for chat: $userId');
      print('🔍 DEBUG: UserProfile.id = ${widget.userProfile?.id}');
      print('🔍 DEBUG: UserProfile.email = ${widget.userProfile?.email}');
      final history = await ChatService.getChatHistory(userId);
      
      setState(() {
        _messages.clear();
        _messages.addAll(history.map((msg) => {
          'text': _stripHtml(msg['content'] ?? ''),
          'isUser': msg['role'] == 'user',
          'timestamp': DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
        }));
        _isLoading = false;
      });

      // Add welcome message if no history
      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        _isLoading = false;
      });
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final userName = widget.userProfile?.name.split(' ').first ?? 'there';
    final welcomeMessage = widget.userProfile != null 
        ? 'Hello $userName! I\'m your AI health coach. I have access to your profile and can provide personalized advice. How can I help you today?'
        : 'Hello! I\'m your AI health coach. How can I help you today?';
    
    _addMessage(welcomeMessage, false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'timestamp': DateTime.now(),
      });
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    
    _textController.clear();
    _addMessage(text, true);
    
    setState(() {
      _isTyping = true;
    });
    
    try {
      final userId = widget.userProfile?.id ?? 'guest';
      print('Sending message for user ID: $userId');
      final response = await ChatService.sendMessage(userId, text);
      
      setState(() {
        _isTyping = false;
      });
      
      // Strip HTML tags from response
      final cleanResponse = _stripHtml(response);
      _addMessage(cleanResponse, false);
      
    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      _addMessage(
        'I\'m having trouble connecting right now. Please try again in a moment.',
        false,
      );
    }
  }

  String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
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
          if (widget.userProfile != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                _showProfileInfo();
              },
              tooltip: 'Profile Info',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showCoachInfo();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile indicator if logged in
          if (widget.userProfile != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.purple.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Personalized for ${widget.userProfile!.name}',
                    style: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat messages area
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Container(
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
            enabled: !_isTyping,
          ),
        ],
      ),
    );
  }

  void _showProfileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${widget.userProfile!.name}'),
            Text('Primary Goal: ${widget.userProfile!.primaryGoal}'),
            Text('Activity Level: ${widget.userProfile!.activityLevel}'),
            const SizedBox(height: 12),
            const Text(
              'The AI coach has access to your complete profile and can provide personalized recommendations.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
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

  void _showCoachInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Your AI Coach'),
        content: const Text(
          'Your AI Health Coach uses advanced AI to provide personalized fitness and nutrition guidance. '
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
  }
}