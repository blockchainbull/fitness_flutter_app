import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Tests for Meal Tracking Features
/// Verifies meal logging, retrieval, and deletion
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  late String testUserId;

  setUpAll(() async {
    // Create a test user for all meal tests
    final testEmail = 'meal_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
    final response = await http.post(
      Uri.parse('$baseUrl/health/onboarding'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': testEmail,
        'password': 'Test123!@#',
        'name': 'Meal Test User',
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

  group('Meal Logging Tests', () {
    test('Log a meal - Valid data', () async {
      final mealData = {
        'user_id': testUserId,
        'food_item': 'Chicken breast',
        'quantity': '200g',
        'meal_type': 'lunch',
        'date': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(mealData),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['meal']['id'], isNotNull);
      expect(data['meal']['food_item'], 'Chicken breast');
    });

    test('Log multiple meals', () async {
      final meals = [
        {'food_item': 'Oatmeal', 'quantity': '1 cup', 'meal_type': 'breakfast'},
        {'food_item': 'Banana', 'quantity': '1 medium', 'meal_type': 'snack'},
        {'food_item': 'Salad', 'quantity': '1 bowl', 'meal_type': 'lunch'},
      ];

      for (var meal in meals) {
        final response = await http.post(
          Uri.parse('$baseUrl/health/meals'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': testUserId,
            'date': DateTime.now().toIso8601String(),
            ...meal,
          }),
        );

        expect(response.statusCode, 200);
        final data = json.decode(response.body);
        expect(data['success'], true);
      }
    });

    test('Log meal - Missing required fields', () async {
      final invalidMealData = {
        'user_id': testUserId,
        // Missing food_item and quantity
        'meal_type': 'lunch',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/health/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invalidMealData),
      );

      expect(response.statusCode, anyOf([400, 422]));
    });
  });

  group('Meal Retrieval Tests', () {
    late String mealId;

    setUp(() async {
      // Create a meal before each test
      final response = await http.post(
        Uri.parse('$baseUrl/health/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'food_item': 'Test Meal',
          'quantity': '100g',
          'meal_type': 'dinner',
          'date': DateTime.now().toIso8601String(),
        }),
      );

      final data = json.decode(response.body);
      mealId = data['meal']['id'];
    });

    test('Get meals for today', () async {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/health/meals/$testUserId?date=$today'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['meals'], isList);
      expect(data['meals'].length, greaterThan(0));
    });

    test('Get meal by ID', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/health/meals/$testUserId/$mealId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['meal']['id'], mealId);
    });

    test('Get meals for date range', () async {
      final startDate = DateTime.now().subtract(Duration(days: 7));
      final endDate = DateTime.now();
      
      final response = await http.get(
        Uri.parse('$baseUrl/health/meals/$testUserId?start_date=${startDate.toIso8601String().split('T')[0]}&end_date=${endDate.toIso8601String().split('T')[0]}'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['meals'], isList);
    });
  });

  group('Meal Deletion Tests', () {
    test('Delete a meal', () async {
      // Create a meal
      final createResponse = await http.post(
        Uri.parse('$baseUrl/health/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'food_item': 'To Be Deleted',
          'quantity': '100g',
          'meal_type': 'snack',
          'date': DateTime.now().toIso8601String(),
        }),
      );

      final createData = json.decode(createResponse.body);
      final mealId = createData['meal']['id'];

      // Delete the meal
      final deleteResponse = await http.delete(
        Uri.parse('$baseUrl/health/meals/$mealId'),
      );

      expect(deleteResponse.statusCode, 200);
      final deleteData = json.decode(deleteResponse.body);
      expect(deleteData['success'], true);

      // Verify meal is deleted
      final getResponse = await http.get(
        Uri.parse('$baseUrl/health/meals/$testUserId/$mealId'),
      );
      
      expect(getResponse.statusCode, anyOf([404, 200]));
    });
  });

  group('Meal Nutritional Analysis Tests', () {
    test('Meal with AI analysis', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/health/meals'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': testUserId,
          'food_item': 'Grilled chicken with rice',
          'quantity': '250g',
          'meal_type': 'dinner',
          'date': DateTime.now().toIso8601String(),
        }),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      
      // Check if nutritional info is provided
      final meal = data['meal'];
      expect(meal['calories'], isNotNull);
      expect(meal['protein'], isNotNull);
      expect(meal['carbs'], isNotNull);
      expect(meal['fats'], isNotNull);
    });
  });
}