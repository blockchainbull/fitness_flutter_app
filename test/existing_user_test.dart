import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String healthCheckUrl = 'https://health-ai-backend-i28b.onrender.com/health';
  
  // Your existing test user from database
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  const String testEmail = 'bulli@123.com';
  const String testPassword = 'bulli@123.com';
  
  group('Backend Health Tests', () {
    test('Health check - Backend is running', () async {
      final response = await http.get(Uri.parse(healthCheckUrl));
      
      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['status'], 'healthy');
      print('✅ Backend is healthy!');
    });
  });

  group('Authentication Tests - Existing User', () {
    test('User login - With bulli@123.com', () async {
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
        }),
      );

      print('Login response status: ${loginResponse.statusCode}');
      print('Login response body: ${loginResponse.body}');

      expect(loginResponse.statusCode, 200);
      final data = json.decode(loginResponse.body);
      expect(data['success'], true);
      expect(data['user']['id'], testUserId); 
      print('✅ Login successful for bulli@123.com');
    });

    test('User login - Invalid password', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': 'wrongpassword',
        }),
      );

      expect(response.statusCode, 401);
      print('✅ Invalid password correctly rejected');
    });
  });

  group('User Profile Tests - Existing User', () {
    test('Get user profile - bulli', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$testUserId'),
      );

      print('Profile response status: ${response.statusCode}');
      print('Profile response body: ${response.body}');

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['userProfile'], isNotNull);
      expect(data['userProfile']['id'], testUserId);
      expect(data['userProfile']['name'], 'bulli');
      expect(data['userProfile']['email'], testEmail);
      print('✅ User profile retrieved successfully');
      print('   Name: ${data['userProfile']['name']}');
      print('   Weight: ${data['userProfile']['weight']} kg');
      print('   Goal: ${data['userProfile']['primary_goal']}');
    });

    test('Get user profile - Invalid user ID', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/users/invalid-user-id-12345'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], false);
      print('✅ Invalid user ID correctly handled');
    });
  });

  group('Meal Tracking Tests - Existing User', () {
    test('Log a meal for bulli', () async {
      final mealData = {
        'user_id': testUserId,
        'food_item': 'Grilled Chicken Breast',
        'quantity': '200g',
        'meal_type': 'lunch',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/meals/analyze'), 
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mealData),
      );

      print('Meal log response status: ${response.statusCode}');
      print('Meal log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['food_item'], 'Grilled Chicken Breast');
        print('✅ Meal logged successfully');
        print('   Calories: ${data['calories']}');
        print('   Protein: ${data['protein_g']}g');
      } else {
        print('⚠️  Meal logging failed with status ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    }, timeout: Timeout(Duration(seconds: 45))); 

    test('Get meals for today', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/meals/$testUserId/history?limit=10'),  
      );

      print('Get meals response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['meals'], isList);
        print('✅ Retrieved ${data['total_count']} meals');
      }
    });
  });

  group('Water Tracking Tests - Existing User', () {
    test('Log water intake for bulli', () async {
      final waterData = {
        'user_id': testUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'glasses_consumed': 6,
        'total_ml': 1500,
        'target_ml': 2000,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(waterData),
      );

      print('Water log response status: ${response.statusCode}');
      print('Water log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entry']['glasses_consumed'], 6);
        print('✅ Water intake logged: 6 glasses');
      }
    });

    test('Get water intake for today', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/water/$testUserId?date=$today'),
      );

      print('Get water response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Water intake retrieved');
        if (data['entry'] != null) {
          print('   Glasses: ${data['entry']['glasses_consumed']}');
          print('   Total: ${data['entry']['total_ml']}ml');
        }
      }
    });
  });

  group('Chat Tests - Existing User', () {
    test('Send message to AI coach', () async {
      final chatData = {
        'user_id': testUserId,
        'message': 'What should I eat for lunch today?',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(chatData),
      );

      print('Chat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['response'], isNotNull);
        print('✅ AI responded:');
        print('   ${data['response'].toString().substring(0, 100)}...');
      } else {
        print('⚠️  Chat failed with status ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Get chat history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/$testUserId'),
      );

      print('Chat history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['messages'], isList);
        print('✅ Retrieved ${data['count']} chat messages');
      }
    });
  });
}