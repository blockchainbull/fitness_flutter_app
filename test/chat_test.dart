import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Tests for AI Chat/Coach Feature
/// Verifies chat functionality, message history, and AI responses
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  late String testUserId;

  setUpAll(() async {
    // Create a test user
    final testEmail = 'chat_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final response = await http.post(
      Uri.parse('$baseUrl/health/onboarding'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': testEmail,
        'password': 'Test123!@#',
        'name': 'Chat Test User',
        'age': 25,
        'gender': 'male',
        'height': 175,
        'weight': 70,
        'activityLevel': 'moderate',
        'primaryGoal': 'maintain'
      }),
    );

    final data = json.decode(response.body);
    testUserId = data['userId'];
  });

  group('Chat Message Tests', () {
    test('Send chat message - Health question', () async {
      final chatData = {
        'user_id': testUserId,
        'message': 'What should I eat for breakfast?',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(chatData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['response'], isNotNull);
      expect(data['response'].length, greaterThan(0));
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Send chat message - Fitness advice', () async {
      final chatData = {
        'user_id': testUserId,
        'message': 'How can I improve my cardio fitness?',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(chatData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['response'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Send chat message - Empty message', () async {
      final chatData = {
        'user_id': testUserId,
        'message': '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(chatData),
      );

      expect(response.statusCode, anyOf([400, 422]));
    });

    test('Send multiple messages in conversation', () async {
      final messages = [
        'Hello',
        'I want to lose weight',
        'What exercises do you recommend?',
      ];

      for (var message in messages) {
        final response = await http.post(
          Uri.parse('$baseUrl/health/chat'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': testUserId,
            'message': message,
          }),
        );

        expect(response.statusCode, 200);
        final data = json.decode(response.body);
        expect(data['success'], true);
        
        // Small delay between messages
        await Future.delayed(Duration(seconds: 2));
      }
    }, timeout: Timeout(Duration(minutes: 2)));
  });

  group('Chat History Tests', () {
    setUp(() async {
      // Send a test message
      await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'message': 'Test message for history',
        }),
      );
    });

    test('Get chat history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/health/chat/history/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['messages'], isList);
      expect(data['count'], greaterThan(0));
    });

    test('Get chat messages with limit', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/health/chat/messages/$testUserId?limit=5'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['messages'], isList);
      expect(data['messages'].length, lessThanOrEqualTo(5));
    });

    test('Chat history contains user and assistant messages', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/health/chat/history/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      final messages = data['messages'] as List;
      
      // Check if messages have role field
      if (messages.isNotEmpty) {
        expect(messages.first['role'], isIn(['user', 'assistant']));
        expect(messages.first['content'], isNotNull);
      }
    });
  });

  group('Chat Session Tests', () {
    test('Get user chat sessions', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/health/chat/sessions/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['sessions'], isList);
    });

    test('Get messages for specific session', () async {
      // Get sessions first
      final sessionsResponse = await http.get(
        Uri.parse('$baseUrl/health/chat/sessions/$testUserId'),
      );
      final sessionsData = json.decode(sessionsResponse.body);
      
      if (sessionsData['sessions'].isNotEmpty) {
        final sessionId = sessionsData['sessions'][0]['id'];
        
        final messagesResponse = await http.get(
          Uri.parse('$baseUrl/health/chat/messages/$testUserId/$sessionId'),
        );

        expect(messagesResponse.statusCode, 200);
        final messagesData = json.decode(messagesResponse.body);
        expect(messagesData['success'], true);
        expect(messagesData['messages'], isList);
      }
    });
  });

  group('Chat Deletion Tests', () {
    test('Clear chat history', () async {
      // Send a message first
      await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'message': 'Message to be cleared',
        }),
      );

      // Clear history
      final deleteResponse = await http.delete(
        Uri.parse('$baseUrl/health/chat/history/$testUserId'),
      );

      expect(deleteResponse.statusCode, 200);
      final deleteData = json.decode(deleteResponse.body);
      expect(deleteData['success'], true);

      // Verify history is empty
      final getResponse = await http.get(
        Uri.parse('$baseUrl/health/chat/history/$testUserId'),
      );

      final getData = json.decode(getResponse.body);
      expect(getData['count'], 0);
    });

    test('Clear chat messages', () async {
      final response = await http.delete(
        Uri.parse('$baseUrl/health/chat/messages/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
    });
  });

  group('Context-Aware Chat Tests', () {
    test('Chat considers user profile', () async {
      final chatData = {
        'user_id': testUserId,
        'message': 'What is my daily calorie target?',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(chatData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      
      // Response should mention calories or TDEE
      final responseText = data['response'].toString().toLowerCase();
      expect(
        responseText.contains('calorie') || 
        responseText.contains('tdee') || 
        responseText.contains('energy'),
        true
      );
    }, timeout: Timeout(Duration(seconds: 30)));
  });
}