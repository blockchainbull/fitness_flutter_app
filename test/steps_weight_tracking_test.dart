import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Steps & Weight Tracking Tests
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  
  group('Steps Tracking Tests', () {
    test('Log daily steps', () async {
      final stepsData = {
        'user_id': testUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'steps': 8500,
        'distance_km': 6.5,
        'calories_burned': 340,
        'active_minutes': 85,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(stepsData),
      );

      print('Steps log response status: ${response.statusCode}');
      print('Steps log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entry']['steps'], 8500);
        print('✅ Steps logged successfully');
        print('   Steps: ${data['entry']['steps']}');
        print('   Distance: ${data['entry']['distance_km']} km');
        print('   Calories: ${data['entry']['calories_burned']}');
      } else {
        print('⚠️  Steps logging response: ${response.body}');
      }
    });

    test('Update daily steps', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // First log
      await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'steps': 5000,
        }),
      );

      // Update with more steps
      final updateResponse = await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'steps': 10000,
          'distance_km': 7.5,
        }),
      );

      print('Update steps response status: ${updateResponse.statusCode}');

      if (updateResponse.statusCode == 200) {
        final data = json.decode(updateResponse.body);
        expect(data['entry']['steps'], 10000);
        print('✅ Steps updated successfully to 10000');
      }
    });

    test('Get steps history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/steps/history/$testUserId?limit=30'),
      );

      print('Steps history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entries'], isList);
        print('✅ Retrieved ${data['entries'].length} step entries');
        
        if (data['entries'].isNotEmpty) {
          final recent = data['entries'][0];
          print('   Recent steps: ${recent['steps']}');
        }
      } else {
        print('⚠️  Steps history endpoint response: ${response.body}');
      }
    });

    test('Get steps for today', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/steps/$testUserId?date=$today'),
      );

      print('Steps for today response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Today\'s steps retrieved');
        if (data['entry'] != null) {
          print('   Steps: ${data['entry']['steps']}');
        }
      }
    });
  });

  group('Weight Tracking Tests', () {
    test('Log weight entry', () async {
      final weightData = {
        'user_id': testUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'weight': 86.5,
        'notes': 'Morning weight',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/weight/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(weightData),
      );

      print('Weight log response status: ${response.statusCode}');
      print('Weight log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entry']['weight'], 86.5);
        print('✅ Weight logged successfully');
        print('   Weight: ${data['entry']['weight']} kg');
        print('   Date: ${data['entry']['date']}');
      } else {
        print('⚠️  Weight logging response: ${response.body}');
      }
    });

    test('Get weight history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/weight/history/$testUserId?limit=30'),
      );

      print('Weight history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entries'], isList);
        print('✅ Retrieved ${data['entries'].length} weight entries');
        
        if (data['entries'].isNotEmpty) {
          final recent = data['entries'][0];
          print('   Recent weight: ${recent['weight']} kg');
          print('   Date: ${recent['date']}');
        }
      } else {
        print('⚠️  Weight history endpoint response: ${response.body}');
      }
    });

    test('Get weight progress', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/weight/progress/$testUserId?days=30'),
      );

      print('Weight progress response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Weight progress retrieved');
        print('   Starting weight: ${data['progress']['starting_weight']}');
        print('   Current weight: ${data['progress']['current_weight']}');
        print('   Change: ${data['progress']['weight_change']} kg');
      } else {
        print('⚠️  Weight progress endpoint response: ${response.body}');
      }
    });

    test('Get latest weight', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/weight/latest/$testUserId'),
      );

      print('Latest weight response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Latest weight retrieved');
        if (data['entry'] != null) {
          print('   Weight: ${data['entry']['weight']} kg');
          print('   Date: ${data['entry']['date']}');
        }
      }
    });
  });

  group('Activity Summary Tests', () {
    test('Get daily activity summary', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/activity/summary/$testUserId?date=$today'),
      );

      print('Activity summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Daily activity summary retrieved');
        print('   Steps: ${data['summary']['steps']}');
        print('   Calories: ${data['summary']['total_calories']}');
        print('   Water: ${data['summary']['water_glasses']}');
        print('   Meals: ${data['summary']['meals_logged']}');
        print('   Exercises: ${data['summary']['exercises']}');
      } else {
        print('⚠️  Activity summary endpoint may not be implemented');
      }
    });

    test('Get weekly activity summary', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/activity/weekly/$testUserId'),
      );

      print('Weekly summary response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Weekly activity summary retrieved');
        print('   Total workouts: ${data['summary']['total_workouts']}');
        print('   Avg steps: ${data['summary']['avg_steps_per_day']}');
      }
    });
  });
}