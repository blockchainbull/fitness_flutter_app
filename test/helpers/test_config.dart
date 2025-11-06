/// Test Configuration Helper
/// Place this file in test/helpers/test_config.dart
/// 
/// This file centralizes test configuration and helper functions
/// to make testing easier and more maintainable.

class TestConfig {
  // ⚠️ IMPORTANT: Update this with your actual backend URL
  static const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  static const String healthCheckUrl = 'https://health-ai-backend-i28b.onrender.com/health';
  static const String usersUrl = 'https://health-ai-backend-i28b.onrender.com/api/users';
  
  // Test user credentials
  static const String testPassword = 'Test123!@#';
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration chatTimeout = Duration(minutes: 1);
  
  // Test data
  static Map<String, dynamic> getTestUser({String? email}) {
    return {
      'email': email ?? 'test_${DateTime.now().millisecondsSinceEpoch}@example.com',
      'password': testPassword,
      'name': 'Test User',
      'age': 25,
      'gender': 'male',
      'height': 175,
      'weight': 70,
      'activityLevel': 'moderate',
      'primaryGoal': 'maintain'
    };
  }
  
  static Map<String, dynamic> getTestMeal({
    required String userId,
    String? foodItem,
    String? quantity,
    String? mealType,
  }) {
    return {
      'user_id': userId,
      'food_item': foodItem ?? 'Test Meal',
      'quantity': quantity ?? '100g',
      'meal_type': mealType ?? 'lunch',
      'date': DateTime.now().toIso8601String(),
    };
  }
  
  static Map<String, dynamic> getTestWaterEntry({
    required String userId,
    int? glasses,
    int? totalMl,
    int? targetMl,
  }) {
    return {
      'user_id': userId,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'glasses_consumed': glasses ?? 4,
      'total_ml': totalMl ?? 1000,
      'target_ml': targetMl ?? 2000,
    };
  }
  
  static Map<String, dynamic> getTestChatMessage({
    required String userId,
    String? message,
  }) {
    return {
      'user_id': userId,
      'message': message ?? 'Test message',
    };
  }
}

/// Helper function to generate unique test emails
String generateTestEmail([String prefix = 'test']) {
  return '${prefix}_${DateTime.now().millisecondsSinceEpoch}@example.com';
}

/// Helper function to get today's date string
String getTodayDateString() {
  return DateTime.now().toIso8601String().split('T')[0];
}

/// Helper function to get date range
List<String> getDateRange(int daysBack) {
  final endDate = DateTime.now();
  final startDate = endDate.subtract(Duration(days: daysBack));
  return [
    startDate.toIso8601String().split('T')[0],
    endDate.toIso8601String().split('T')[0],
  ];
}

/// Helper to create delay between API calls
Future<void> testDelay([int seconds = 1]) async {
  await Future.delayed(Duration(seconds: seconds));
}

/// Response validation helpers
class ResponseValidator {
  static bool isSuccessful(Map<String, dynamic> response) {
    return response['success'] == true;
  }
  
  static bool hasField(Map<String, dynamic> response, String field) {
    return response.containsKey(field) && response[field] != null;
  }
  
  static bool hasNonEmptyList(Map<String, dynamic> response, String field) {
    return hasField(response, field) && 
           response[field] is List && 
           (response[field] as List).isNotEmpty;
  }
}

/// Common test expectations
class TestExpectations {
  // Standard success response structure
  static void expectSuccessResponse(Map<String, dynamic> response) {
    assert(response['success'] == true, 'Response should be successful');
    assert(response.containsKey('message') || response.containsKey('data'), 
           'Response should contain message or data');
  }
  
  // Standard error response structure
  static void expectErrorResponse(Map<String, dynamic> response) {
    assert(response['success'] == false, 'Response should be unsuccessful');
    assert(response.containsKey('error') || response.containsKey('message'), 
           'Response should contain error or message');
  }
  
  // User profile structure
  static void expectValidUserProfile(Map<String, dynamic> profile) {
    final requiredFields = ['id', 'email', 'name', 'age', 'gender', 
                           'height', 'weight', 'activity_level', 'primary_goal'];
    
    for (var field in requiredFields) {
      assert(profile.containsKey(field), 'Profile missing field: $field');
      assert(profile[field] != null, 'Profile field is null: $field');
    }
  }
  
  // Meal structure
  static void expectValidMeal(Map<String, dynamic> meal) {
    final requiredFields = ['id', 'user_id', 'food_item', 'quantity', 
                           'meal_type', 'created_at'];
    
    for (var field in requiredFields) {
      assert(meal.containsKey(field), 'Meal missing field: $field');
      assert(meal[field] != null, 'Meal field is null: $field');
    }
  }
  
  // Water entry structure
  static void expectValidWaterEntry(Map<String, dynamic> entry) {
    final requiredFields = ['id', 'user_id', 'date', 'glasses_consumed', 
                           'total_ml', 'target_ml'];
    
    for (var field in requiredFields) {
      assert(entry.containsKey(field), 'Water entry missing field: $field');
      assert(entry[field] != null, 'Water entry field is null: $field');
    }
  }
  
  // Chat message structure
  static void expectValidChatMessage(Map<String, dynamic> message) {
    final requiredFields = ['role', 'content'];
    
    for (var field in requiredFields) {
      assert(message.containsKey(field), 'Message missing field: $field');
      assert(message[field] != null, 'Message field is null: $field');
    }
    
    assert(['user', 'assistant'].contains(message['role']), 
           'Invalid message role: ${message['role']}');
  }
}

/// Test data cleanup helper
class TestDataCleanup {
  static List<String> createdUserIds = [];
  static List<String> createdMealIds = [];
  static List<String> createdWaterEntryIds = [];
  
  static void trackUser(String userId) {
    createdUserIds.add(userId);
  }
  
  static void trackMeal(String mealId) {
    createdMealIds.add(mealId);
  }
  
  static void trackWaterEntry(String entryId) {
    createdWaterEntryIds.add(entryId);
  }
  
  static void reset() {
    createdUserIds.clear();
    createdMealIds.clear();
    createdWaterEntryIds.clear();
  }
}

/// Network simulation helpers for testing offline scenarios
class NetworkSimulator {
  static bool _isOnline = true;
  
  static bool get isOnline => _isOnline;
  
  static void goOffline() {
    _isOnline = false;
    print('🔴 Network: OFFLINE');
  }
  
  static void goOnline() {
    _isOnline = true;
    print('🟢 Network: ONLINE');
  }
  
  static Future<void> simulateSlowNetwork() async {
    print('🐌 Simulating slow network...');
    await Future.delayed(Duration(seconds: 3));
  }
  
  static Future<void> simulateNetworkError() async {
    print('❌ Simulating network error...');
    throw Exception('Network error simulated');
  }
}

/// Performance measurement helper
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  
  static void startMeasurement(String operation) {
    _startTimes[operation] = DateTime.now();
    print('⏱️  Started: $operation');
  }
  
  static Duration endMeasurement(String operation) {
    if (!_startTimes.containsKey(operation)) {
      throw Exception('No start time recorded for: $operation');
    }
    
    final duration = DateTime.now().difference(_startTimes[operation]!);
    print('✅ Completed: $operation in ${duration.inMilliseconds}ms');
    _startTimes.remove(operation);
    
    return duration;
  }
  
  static void reset() {
    _startTimes.clear();
  }
}

/// Example usage in tests:
/// 
/// test('Create user with helper', () async {
///   final userData = TestConfig.getTestUser();
///   
///   PerformanceMonitor.startMeasurement('user_creation');
///   final response = await http.post(...);
///   final duration = PerformanceMonitor.endMeasurement('user_creation');
///   
///   expect(duration.inSeconds, lessThan(3));
///   TestExpectations.expectSuccessResponse(jsonDecode(response.body));
/// });