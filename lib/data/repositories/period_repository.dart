// lib/data/repositories/period_repository.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:user_onboarding/data/models/period_entry.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/data/services/database_service.dart';

class PeriodRepository {
  static final ApiService _apiService = ApiService();

  static Future<String> savePeriodEntry(PeriodEntry entry) async {
    try {
      if (kIsWeb) {
        return await _apiService.savePeriodEntry(entry);
      } else {
        if (DatabaseService.isInitialized) {
          final id = entry.id ?? DateTime.now().millisecondsSinceEpoch.toString();
          await DatabaseService.insertPeriod(r'''
            INSERT INTO period_tracking (id, user_id, start_date, end_date, flow_intensity, symptoms, mood, notes)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (id) DO UPDATE SET
              end_date = $4,
              flow_intensity = $5,
              symptoms = $6,
              mood = $7,
              notes = $8
          ''', [
            id,
            entry.userId,
            entry.startDate.toIso8601String(),
            entry.endDate?.toIso8601String(),
            entry.flowIntensity,
            entry.symptoms,
            entry.mood,
            entry.notes,
          ]);
          return id;
        } else {
          return await _apiService.savePeriodEntry(entry);
        }
      }
    } catch (e) {
      print('Error saving period entry: $e');
      rethrow;
    }
  }

  static Future<bool> deletePeriodEntry(String periodId) async {
    try {
      if (kIsWeb) {
        return await _apiService.deletePeriodEntry(periodId);
      } else {
        if (DatabaseService.isInitialized) {
          await DatabaseService.execute(
            'DELETE FROM period_tracking WHERE id = @id',
            {'id': periodId}
          );
          return true;
        } else {
          return await _apiService.deletePeriodEntry(periodId);
        }
      }
    } catch (e) {
      print('Error deleting period entry: $e');
      return false;
    }
  }

  static Future<List<PeriodEntry>> getPeriodHistory(String userId, {int limit = 12}) async {
    try {
      if (kIsWeb) {
        return await _apiService.getPeriodHistory(userId, limit: limit);
      } else {
        if (DatabaseService.isInitialized) {
          final results = await DatabaseService.queryPeriods(r'''
            SELECT * FROM period_tracking 
            WHERE user_id = $1 
            ORDER BY start_date DESC 
            LIMIT $2
          ''', [userId, limit]);
          
          return results.map((row) => PeriodEntry.fromMap(row)).toList();
        } else {
          return await _apiService.getPeriodHistory(userId, limit: limit);
        }
      }
    } catch (e) {
      print('Error fetching period history: $e');
      return [];
    }
  }

  static Future<PeriodEntry?> getCurrentPeriod(String userId) async {
    try {
      final history = await getPeriodHistory(userId, limit: 1);
      if (history.isNotEmpty && history.first.endDate == null) {
        return history.first;
      }
      return null;
    } catch (e) {
      print('Error fetching current period: $e');
      return null;
    }
  }
}