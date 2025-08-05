// lib/data/repositories/weight_repository.dart
import 'package:uuid/uuid.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/services/database_service.dart';

class WeightRepository {
  static final Uuid _uuid = Uuid();

  static Future<String> saveWeightEntry(WeightEntry weightEntry) async {
    try {
      final id = weightEntry.id ?? _uuid.v4();
      
      await DatabaseService.execute('''
        INSERT INTO weight_entries (
          id, user_id, date, weight, notes, created_at
        ) VALUES (
          @id, @userId, @date, @weight, @notes, @createdAt
        )
        ON CONFLICT (id) DO UPDATE SET
          weight = @weight,
          notes = @notes,
          created_at = @createdAt
      ''', {
        'id': id,
        'userId': weightEntry.userId,
        'date': weightEntry.date.toIso8601String(),
        'weight': weightEntry.weight,
        'notes': weightEntry.notes,
        'createdAt': weightEntry.createdAt.toIso8601String(),
      });

      return id;
    } catch (e) {
      print('[WeightRepository] Failed to save weight entry: $e');
      rethrow;
    }
  }

  static Future<List<WeightEntry>> getWeightHistory(String userId, {int limit = 50}) async {
    try {
      final result = await DatabaseService.query('''
        SELECT * FROM weight_entries 
        WHERE user_id = @userId 
        ORDER BY date DESC 
        LIMIT @limit
      ''', {
        'userId': userId,
        'limit': limit,
      });

      return result.map((row) => WeightEntry.fromMap(row)).toList();
    } catch (e) {
      print('[WeightRepository] Failed to get weight history: $e');
      return [];
    }
  }

  static Future<WeightEntry?> getLatestWeight(String userId) async {
    try {
      final result = await DatabaseService.query('''
        SELECT * FROM weight_entries 
        WHERE user_id = @userId 
        ORDER BY date DESC 
        LIMIT 1
      ''', {
        'userId': userId,
      });

      if (result.isNotEmpty) {
        return WeightEntry.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('[WeightRepository] Failed to get latest weight: $e');
      return null;
    }
  }

  static Future<bool> deleteWeightEntry(String id) async {
    try {
      await DatabaseService.execute('''
        DELETE FROM weight_entries WHERE id = @id
      ''', {
        'id': id,
      });
      return true;
    } catch (e) {
      print('[WeightRepository] Failed to delete weight entry: $e');
      return false;
    }
  }

  static Future<WeightEntry?> getWeightForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await DatabaseService.query('''
        SELECT * FROM weight_entries 
        WHERE user_id = @userId 
        AND date >= @startDate 
        AND date < @endDate
        ORDER BY date DESC 
        LIMIT 1
      ''', {
        'userId': userId,
        'startDate': startOfDay.toIso8601String(),
        'endDate': endOfDay.toIso8601String(),
      });

      if (result.isNotEmpty) {
        return WeightEntry.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('[WeightRepository] Failed to get weight for date: $e');
      return null;
    }
  }
}