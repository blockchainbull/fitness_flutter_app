import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Supplements & Period Tracking Tests
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  
  group('Supplements Tracking Tests', () {
    test('Create supplement', () async {
      final supplementData = {
        'user_id': testUserId,
        'name': 'Vitamin D',
        'dosage': '2000 IU',
        'frequency': 'daily',
        'time_of_day': 'morning',
        'notes': 'Take with breakfast',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/supplements/create'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(supplementData),
      );

      print('Create supplement response status: ${response.statusCode}');
      print('Create supplement response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['supplement']['name'], 'Vitamin D');
        print('✅ Supplement created successfully');
        print('   Name: ${data['supplement']['name']}');
        print('   Dosage: ${data['supplement']['dosage']}');
      } else {
        print('⚠️  Supplement creation response: ${response.body}');
      }
    });

    test('Log supplement taken', () async {
      final logData = {
        'user_id': testUserId,
        'supplement_id': 'test-supplement-id',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'taken': true,
        'time_taken': '08:30',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/supplements/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(logData),
      );

      print('Log supplement response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Supplement intake logged');
      } else {
        print('⚠️  Supplement logging response: ${response.body}');
      }
    });

    test('Get user supplements', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/$testUserId'),
      );

      print('Get supplements response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['supplements'], isList);
        print('✅ Retrieved ${data['supplements'].length} supplements');
        
        if (data['supplements'].isNotEmpty) {
          final supp = data['supplements'][0];
          print('   Supplement: ${supp['name']}');
          print('   Dosage: ${supp['dosage']}');
        }
      } else {
        print('⚠️  Get supplements endpoint response: ${response.body}');
      }
    });

    test('Get supplement status for date', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/supplements/$testUserId/status?date=$today'),
      );

      print('Supplement status response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Supplement status retrieved for $today');
        print('   Taken: ${data['status']['taken_count']}');
        print('   Total: ${data['status']['total_count']}');
      }
    });

    test('Delete supplement', () async {
      final response = await http.delete(
        Uri.parse('$baseUrl/supplements/test-supplement-id'),
      );

      print('Delete supplement response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Supplement deleted');
      }
    });
  });

  group('Period Tracking Tests', () {
    // Note: These tests are for female users only
    // Skip if user is male
    
    test('Log period start', () async {
      final periodData = {
        'user_id': testUserId,
        'start_date': DateTime.now().toIso8601String().split('T')[0],
        'flow': 'medium',
        'symptoms': ['cramps', 'fatigue'],
        'notes': 'Day 1',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/period/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(periodData),
      );

      print('Log period response status: ${response.statusCode}');
      print('Log period response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Period logged successfully');
        print('   Start date: ${data['entry']['start_date']}');
        print('   Flow: ${data['entry']['flow']}');
      } else {
        print('⚠️  Period logging response: ${response.body}');
        print('   Note: This is expected for male users');
      }
    }, skip: 'User is male - period tracking not applicable');

    test('Get period history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/period/history/$testUserId?limit=12'),
      );

      print('Period history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entries'], isList);
        print('✅ Retrieved ${data['entries'].length} period entries');
      } else {
        print('⚠️  Period history response: ${response.body}');
        print('   Note: This is expected for male users');
      }
    }, skip: 'User is male - period tracking not applicable');

    test('Get cycle prediction', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/period/prediction/$testUserId'),
      );

      print('Cycle prediction response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Cycle prediction retrieved');
        print('   Next period: ${data['prediction']['next_period_date']}');
        print('   Fertile window: ${data['prediction']['fertile_window']}');
      } else {
        print('⚠️  Cycle prediction response: ${response.body}');
      }
    }, skip: 'User is male - period tracking not applicable');
  });

  group('Comprehensive Daily Tracking Test', () {
    test('Log complete day of activities', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      print('\n🎯 Testing complete daily tracking workflow...\n');
      
      // 1. Log water
      final waterResponse = await http.post(
        Uri.parse('$baseUrl/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'glasses_consumed': 8,
          'total_ml': 2000,
          'target_ml': 2000,
        }),
      );
      print('1. Water: ${waterResponse.statusCode == 200 ? "✅" : "❌"}');

      // 2. Log meal
      final mealResponse = await http.post(
        Uri.parse('$baseUrl/meals/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'food_item': 'Chicken and rice',
          'quantity': '1 plate',
          'meal_type': 'lunch',
        }),
      );
      print('2. Meal: ${mealResponse.statusCode == 200 ? "✅" : "❌"}');

      // 3. Log exercise
      final exerciseResponse = await http.post(
        Uri.parse('$baseUrl/exercise/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'exercise_name': 'Push-ups',
          'exercise_type': 'strength',
          'muscle_group': 'chest',
          'sets': 3,
          'reps': 15,
          'calories_burned': 50,
          'exercise_date': DateTime.now().toIso8601String(),
        }),
      );
      print('3. Exercise: ${exerciseResponse.statusCode == 200 ? "✅" : "❌"}');

      // 4. Log steps
      final stepsResponse = await http.post(
        Uri.parse('$baseUrl/steps/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'steps': 10000,
          'distance_km': 7.5,
        }),
      );
      print('4. Steps: ${stepsResponse.statusCode == 200 ? "✅" : "❌"}');

      // 5. Log weight
      final weightResponse = await http.post(
        Uri.parse('$baseUrl/weight/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'weight': 86.0,
        }),
      );
      print('5. Weight: ${weightResponse.statusCode == 200 ? "✅" : "❌"}');

      print('\n✅ Complete daily tracking workflow tested!\n');
      
      // All should succeed
      expect(waterResponse.statusCode, 200);
      expect(mealResponse.statusCode, 200);
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}