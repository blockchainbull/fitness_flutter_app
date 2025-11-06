import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Tests for Water Tracking Feature
/// Verifies water logging and retrieval functionality
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  late String testUserId;

  setUpAll(() async {
    // Create a test user
    final testEmail = 'water_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final response = await http.post(
      Uri.parse('$baseUrl/health/onboarding'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': testEmail,
        'password': 'Test123!@#',
        'name': 'Water Test User',
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

  group('Water Logging Tests', () {
    test('Log water intake - Initial entry', () async {
      final waterData = {
        'user_id': testUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'glasses_consumed': 3,
        'total_ml': 750,
        'target_ml': 2000,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(waterData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['entry']['glasses_consumed'], 3);
    });

    test('Update water intake - Same day', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // First entry
      await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'glasses_consumed': 2,
          'total_ml': 500,
          'target_ml': 2000,
        }),
      );

      // Update entry
      final updateResponse = await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'glasses_consumed': 5,
          'total_ml': 1250,
          'target_ml': 2000,
        }),
      );

      expect(updateResponse.statusCode, 200);
      final data = json.decode(updateResponse.body);
      expect(data['success'], true);
      expect(data['entry']['glasses_consumed'], 5);
    });

    test('Log water with notes', () async {
      final waterData = {
        'user_id': testUserId,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'glasses_consumed': 4,
        'total_ml': 1000,
        'target_ml': 2000,
        'notes': 'Drank extra after workout',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(waterData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['entry']['notes'], 'Drank extra after workout');
    });

    test('Log water - Missing required fields', () async {
      final invalidData = {
        'user_id': testUserId,
        // Missing glasses_consumed and total_ml
        'date': DateTime.now().toIso8601String().split('T')[0],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invalidData),
      );

      expect(response.statusCode, anyOf([400, 422]));
    });
  });

  group('Water Retrieval Tests', () {
    setUp(() async {
      // Log water for today
      await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'glasses_consumed': 6,
          'total_ml': 1500,
          'target_ml': 2000,
        }),
      );
    });

    test('Get water intake for today', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/health/water/$testUserId?date=$today'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['entry'], isNotNull);
      expect(data['entry']['glasses_consumed'], greaterThan(0));
    });

    test('Get water intake for date range', () async {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: 7));
      
      final response = await http.get(
        Uri.parse('$baseUrl/health/water/$testUserId?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['entries'], isList);
    });

    test('Get water intake - No data for date', () async {
      final futureDate = DateTime.now().add(Duration(days: 30)).toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/health/water/$testUserId?date=$futureDate'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      // Should return success but entry might be null
      expect(data['success'], true);
    });
  });

  group('Water Progress Tests', () {
    test('Calculate water intake percentage', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await http.post(
        Uri.parse('$baseUrl/health/water'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'date': today,
          'glasses_consumed': 8,
          'total_ml': 2000,
          'target_ml': 2000,
        }),
      );

      final response = await http.get(
        Uri.parse('$baseUrl/health/water/$testUserId?date=$today'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      
      final totalMl = data['entry']['total_ml'];
      final targetMl = data['entry']['target_ml'];
      final percentage = (totalMl / targetMl) * 100;
      
      expect(percentage, greaterThanOrEqualTo(100.0));
    });
  });
}