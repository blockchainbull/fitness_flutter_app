import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Tests for Authentication and User Management  
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String healthCheckUrl = 'https://health-ai-backend-i28b.onrender.com/health';
  
  group('Authentication Tests', () {
    test('Health check - Backend is running', () async {
      final response = await http.get(Uri.parse(healthCheckUrl));
      
      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['status'], 'healthy');
    });

    test('User registration - Valid data', () async {
      final testUser = {
        'email': 'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
        'password': 'Test123!@#',
        'name': 'Test User',
        'age': 25,
        'gender': 'male',
        'height': 175,
        'weight': 70,
        'activityLevel': 'moderate',
        'primaryGoal': 'maintain'
      };

      final response = await http.post(
        Uri.parse('$baseUrl/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(testUser),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['userId'], isNotNull);
    });

    test('User login - Valid credentials', () async {
      final testEmail = 'login_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'Test123!@#';
      
      await http.post(
        Uri.parse('$baseUrl/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
          'name': 'Login Test',
          'age': 25,
          'gender': 'male',
          'height': 175,
          'weight': 70,
          'activityLevel': 'moderate',
          'primaryGoal': 'maintain'
        }),
      );

      final loginResponse = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': testPassword,
        }),
      );

      expect(loginResponse.statusCode, 200);
      final data = json.decode(loginResponse.body);
      expect(data['success'], true);
      expect(data['userId'], isNotNull);
    });

    test('User login - Invalid credentials', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': 'nonexistent@example.com',
          'password': 'wrongpassword',
        }),
      );

      expect(response.statusCode, 401);
    });
  });

  group('User Profile Tests', () {
    late String testUserId;

    setUp(() async {
      final testEmail = 'profile_test_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final response = await http.post(
        Uri.parse('$baseUrl/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': testEmail,
          'password': 'Test123!@#',
          'name': 'Profile Test',
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

    test('Get user profile - Valid user ID', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$testUserId'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], true);
      expect(data['userProfile'], isNotNull);
      expect(data['userProfile']['id'], testUserId);
    });

    test('Get user profile - Invalid user ID', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/users/invalid-user-id'),
      );

      expect(response.statusCode, 200);
      final data = json.decode(response.body);
      expect(data['success'], false);
    });
  });
}