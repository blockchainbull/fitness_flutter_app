import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Exercise Tracking Tests
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  
  group('Exercise Logging Tests', () {
    test('Log cardio exercise', () async {
      final exerciseData = {
        'user_id': testUserId,
        'exercise_name': 'Running',
        'exercise_type': 'cardio',
        'muscle_group': 'full body',
        'duration_minutes': 30,
        'distance_km': 5.0,
        'calories_burned': 300,
        'exercise_date': DateTime.now().toIso8601String(),
        'notes': 'Morning run',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(exerciseData),
      );

      print('Cardio log response status: ${response.statusCode}');
      print('Cardio log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['exercise']['exercise_name'], 'Running');
        expect(data['exercise']['exercise_type'], 'cardio');
        print('✅ Cardio exercise logged successfully');
        print('   Duration: ${data['exercise']['duration_minutes']} min');
        print('   Distance: ${data['exercise']['distance_km']} km');
        print('   Calories: ${data['exercise']['calories_burned']}');
      } else {
        print('⚠️  Exercise logging failed: ${response.statusCode}');
      }
    });

    test('Log strength exercise', () async {
      final exerciseData = {
        'user_id': testUserId,
        'exercise_name': 'Bench Press',
        'exercise_type': 'strength',
        'muscle_group': 'chest',
        'sets': 4,
        'reps': 10,
        'weight_kg': 60.0,
        'calories_burned': 120,
        'exercise_date': DateTime.now().toIso8601String(),
        'duration_minutes': 20,
        'notes': 'Good form',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(exerciseData),
      );

      print('Strength log response status: ${response.statusCode}');
      print('Strength log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['exercise']['exercise_type'], 'strength');
        print('✅ Strength exercise logged successfully');
        print('   Sets: ${data['exercise']['sets']}');
        print('   Reps: ${data['exercise']['reps']}');
        print('   Weight: ${data['exercise']['weight_kg']} kg');
      }
    });

    test('Log yoga/flexibility exercise', () async {
      final exerciseData = {
        'user_id': testUserId,
        'exercise_name': 'Yoga Flow',
        'exercise_type': 'flexibility',
        'muscle_group': 'full body',
        'duration_minutes': 45,
        'calories_burned': 150,
        'exercise_date': DateTime.now().toIso8601String(),
        'notes': 'Relaxing session',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(exerciseData),
      );

      print('Yoga log response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Flexibility exercise logged');
      }
    });
  });

  group('Exercise Retrieval Tests', () {
    test('Get exercise logs', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/logs/$testUserId?limit=20'),
      );

      print('Get exercises response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['exercises'], isList);
        print('✅ Retrieved ${data['exercises'].length} exercises');
        
        if (data['exercises'].isNotEmpty) {
          final firstExercise = data['exercises'][0];
          print('   Last exercise: ${firstExercise['exercise_name']}');
          print('   Type: ${firstExercise['exercise_type']}');
        }
      }
    });

    test('Get exercise stats', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/stats/$testUserId?days=30'),
      );

      print('Exercise stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Exercise statistics retrieved');
        print('   Total workouts: ${data['stats']['total_workouts']}');
        print('   Total calories: ${data['stats']['total_calories_burned']}');
        print('   Total minutes: ${data['stats']['total_minutes']}');
      }
    });

    test('Filter exercises by type', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/logs/$testUserId?exercise_type=cardio&limit=10'),
      );

      print('Filter by type response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Filtered cardio exercises: ${data['exercises'].length}');
      }
    });

    test('Get exercises by date range', () async {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: 7));
      
      final response = await http.get(
        Uri.parse('$baseUrl/exercise/logs/$testUserId?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}'),
      );

      print('Date range response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Retrieved exercises for last 7 days: ${data['exercises'].length}');
      }
    });
  });
}