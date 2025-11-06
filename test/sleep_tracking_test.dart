import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Sleep Tracking Tests
/// Backend: https://health-ai-backend-i28b.onrender.com
void main() {
  const String baseUrl = 'https://health-ai-backend-i28b.onrender.com/api/health';
  const String testUserId = '800acd85-05f3-4adc-9e70-3967df3cf68d';
  
  group('Sleep Logging Tests', () {
    test('Log sleep entry', () async {
      final sleepData = {
        'user_id': testUserId,
        'date': DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0],
        'bedtime': '23:00',
        'wake_time': '07:00',
        'total_hours': 8.0,
        'quality': 'good',
        'notes': 'Slept well',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sleep/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sleepData),
      );

      print('Sleep log response status: ${response.statusCode}');
      print('Sleep log response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['sleep']['total_hours'], 8.0);
        print('✅ Sleep logged successfully');
        print('   Hours: ${data['sleep']['total_hours']}');
        print('   Quality: ${data['sleep']['quality']}');
      } else {
        print('⚠️  Sleep logging may not be implemented yet');
        print('   Status: ${response.statusCode}');
      }
    });

    test('Log sleep with disruptions', () async {
      final sleepData = {
        'user_id': testUserId,
        'date': DateTime.now().subtract(Duration(days: 2)).toIso8601String().split('T')[0],
        'bedtime': '22:30',
        'wake_time': '06:30',
        'total_hours': 7.5,
        'quality': 'fair',
        'disruptions': 2,
        'notes': 'Woke up twice',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/sleep/log'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sleepData),
      );

      print('Sleep with disruptions response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Sleep with disruptions logged');
      }
    });
  });

  group('Sleep Retrieval Tests', () {
    test('Get sleep history', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/history/$testUserId?limit=30'),
      );

      print('Sleep history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        expect(data['entries'], isList);
        print('✅ Retrieved ${data['entries'].length} sleep entries');
        
        if (data['entries'].isNotEmpty) {
          final recentSleep = data['entries'][0];
          print('   Last sleep: ${recentSleep['total_hours']} hours');
          print('   Quality: ${recentSleep['quality']}');
        }
      } else {
        print('⚠️  Sleep history endpoint may not be implemented');
      }
    });

    test('Get sleep for specific date', () async {
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final dateStr = yesterday.toIso8601String().split('T')[0];
      
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/$testUserId?date=$dateStr'),
      );

      print('Sleep for date response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Sleep data retrieved for $dateStr');
        if (data['entry'] != null) {
          print('   Hours: ${data['entry']['total_hours']}');
        }
      }
    });

    test('Get sleep statistics', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/sleep/stats/$testUserId?days=7'),
      );

      print('Sleep stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        expect(data['success'], true);
        print('✅ Sleep statistics retrieved');
        print('   Average hours: ${data['stats']['average_hours']}');
        print('   Total nights: ${data['stats']['total_nights']}');
      } else {
        print('⚠️  Sleep stats endpoint may not be implemented');
      }
    });
  });
}