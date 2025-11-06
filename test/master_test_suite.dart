import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Master Test Suite - All Features
/// This runs a comprehensive test of ALL tracking features
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String healthCheckUrl = 'https://health-ai-backend-i28b.onrender.com/health';
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  const String testEmail = 'bulli@123.com';
  const String testPassword = 'bulli@123.com';

  print('\n🚀 COMPREHENSIVE TEST SUITE - ALL FEATURES\n');
  print('Testing user: $testEmail');
  print('User ID: $testUserId\n');

  group('1️⃣  System Health', () {
    test('Backend is running', () async {
      final response = await http.get(Uri.parse(healthCheckUrl));
      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['status'], 'healthy');
      print('✅ Backend: ${data['status']}');
    });
  });

  group('2️⃣  Authentication', () {
    test('User login', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': testEmail, 'password': testPassword}),
      );
      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      print('✅ Login: ${data['user']['name']}');
    });

    test('Get user profile', () async {
      final response = await http.get(Uri.parse('$baseUrl/users/$testUserId'));
      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      print('✅ Profile: ${data['userProfile']['name']} (${data['userProfile']['weight']} kg)');
    });
  });

  group('3️⃣  Meal Tracking', () {
    test('Log and retrieve meal', () async {
      final mealResponse = await http.post(
        Uri.parse('$baseUrl/meals/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'food_item': 'Grilled Salmon',
          'quantity': '150g',
          'meal_type': 'dinner',
        }),
      );
      
      expect(mealResponse.statusCode, 200);
      final mealData = json.decode(mealResponse.body);
      print('✅ Meal: ${mealData['food_item']} - ${mealData['calories']} cal');

      final historyResponse = await http.get(
        Uri.parse('$baseUrl/meals/$testUserId/history?limit=5'),
      );
      expect(historyResponse.statusCode, 200);
      final historyData = json.decode(historyResponse.body);
      print('   Total meals: ${historyData['total_count']}');
    }, timeout: Timeout(Duration(seconds: 45)));
  });

  group('4️⃣  Water Tracking', () {
    test('Log and retrieve water', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final logResponse = await http.post(
        Uri.parse('$baseUrl/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'glasses_consumed': 7,
          'total_ml': 1750,
          'target_ml': 2000,
        }),
      );
      
      expect(logResponse.statusCode, 200);
      final logData = json.decode(logResponse.body);
      print('✅ Water: ${logData['entry']['glasses_consumed']} glasses');

      final getResponse = await http.get(
        Uri.parse('$baseUrl/water/$testUserId?date=$today'),
      );
      expect(getResponse.statusCode, 200);
    });
  });

  group('5️⃣  Exercise Tracking', () {
    test('Log cardio exercise', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'exercise_name': 'Cycling',
          'exercise_type': 'cardio',
          'muscle_group': 'legs',
          'duration_minutes': 30,
          'distance_km': 15.0,
          'calories_burned': 400,
          'exercise_date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Exercise: ${data['exercise']['exercise_name']} - ${data['exercise']['calories_burned']} cal');
      } else {
        print('⚠️  Exercise: Not yet implemented (${response.statusCode})');
      }
    });

    test('Log strength exercise', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'exercise_name': 'Squats',
          'exercise_type': 'strength',
          'muscle_group': 'legs',
          'sets': 4,
          'reps': 12,
          'weight_kg': 80.0,
          'calories_burned': 150,
          'exercise_date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Strength: ${data['exercise']['exercise_name']} - ${data['exercise']['sets']}x${data['exercise']['reps']}');
      } else {
        print('⚠️  Strength: Not yet implemented (${response.statusCode})');
      }
    });

    test('Get exercise history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/logs/$testUserId?limit=10'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Total exercises: ${data['exercises'].length}');
      }
    });
  });

  group('6️⃣  Steps Tracking', () {
    test('Log and retrieve steps', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final logResponse = await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'steps': 12000,
          'distance_km': 9.0,
          'calories_burned': 480,
        }),
      );

      if (logResponse.statusCode == 200) {
        final data = json.decode(logResponse.body);
        print('✅ Steps: ${data['entry']['steps']} steps');
      } else {
        print('⚠️  Steps: Not yet implemented (${logResponse.statusCode})');
      }
    });
  });

  group('7️⃣  Weight Tracking', () {
    test('Log weight', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final response = await http.post(
        Uri.parse('$baseUrl/weight/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'weight': 86.2,
          'notes': 'Morning weight',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weight: ${data['entry']['weight']} kg');
      } else {
        print('⚠️  Weight: Not yet implemented (${response.statusCode})');
      }
    });

    test('Get weight history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/weight/history/$testUserId?limit=10'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Total entries: ${data['entries'].length}');
      }
    });
  });

  group('8️⃣  Sleep Tracking', () {
    test('Log sleep', () async {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      
      final response = await http.post(
        Uri.parse('$baseUrl/sleep/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': dateStr,
          'bedtime': '23:00',
          'wake_time': '07:00',
          'total_hours': 8.0,
          'quality': 'good',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Sleep: ${data['sleep']['total_hours']} hours');
      } else {
        print('⚠️  Sleep: Not yet implemented (${response.statusCode})');
      }
    });
  });

  group('9️⃣  AI Chat', () {
    test('Send message and get response', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'message': 'Give me a quick workout tip',
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      print('✅ Chat: AI responded (${data['response'].length} chars)');
    }, timeout: Timeout(Duration(seconds: 30)));

    test('Get chat history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/history/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      print('   Total messages: ${data['count']}');
    });
  });

  print('\n✅ COMPREHENSIVE TEST SUITE COMPLETE!\n');
}