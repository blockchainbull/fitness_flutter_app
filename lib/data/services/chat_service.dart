// lib/data/services/chat_service.dart
import 'package:user_onboarding/data/services/api_service.dart';

class ChatService {
  static final ApiService _apiService = ApiService();

  static Future<String> sendMessage(String userId, String message) async {
    try {
      final response = await _apiService.sendChatMessage(userId, message);
      
      if (response['success'] == true) {
        return response['response'] ?? 'Sorry, I couldn\'t process your message.';
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('[ChatService] Error sending message: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getChatHistory(String userId) async {
    try {
      return await _apiService.getChatHistory(userId);
    } catch (e) {
      print('[ChatService] Error getting chat history: $e');
      return [];
    }
  }
}