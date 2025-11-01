// lib/data/repositories/water_repository.dart
import 'package:flutter/foundation.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/services/api_service.dart';
import 'package:user_onboarding/data/services/database_service.dart';
import 'dart:math';
import 'package:intl/intl.dart';

class WaterRepository {
  static final Random _random = Random();
  static final ApiService _apiService = ApiService();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(9999).toString().padLeft(4, '0');
  }

  // static Future<String> saveWaterEntry(WaterEntry waterEntry) async {
  //   try {
  //     final id = waterEntry.id ?? _generateId();
      
  //     if (kIsWeb) {
  //       // Use API service for web
  //       final entryId = await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
  //       print('✅ Water entry saved via API with ID: $entryId');
  //       return entryId;
  //     } else {
  //       // Use direct database connection for mobile with new method
  //       if (DatabaseService.isInitialized) {
  //         // Try the complex ON CONFLICT approach first
  //         await DatabaseService.executeWater(r'''
  //           INSERT INTO daily_water 
  //           (id, user_id, date, glasses_consumed, total_ml, target_ml, notes, created_at, updated_at)
  //           VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  //           ON CONFLICT (user_id, (date::date)) 
  //           DO UPDATE SET 
  //             glasses_consumed = EXCLUDED.glasses_consumed,
  //             total_ml = EXCLUDED.total_ml,
  //             target_ml = EXCLUDED.target_ml,
  //             notes = EXCLUDED.notes,
  //             updated_at = CURRENT_TIMESTAMP
  //         ''', [
  //           id,
  //           waterEntry.userId,
  //           waterEntry.date.toIso8601String(),
  //           waterEntry.glassesConsumed,
  //           waterEntry.totalMl,
  //           waterEntry.targetMl,
  //           waterEntry.notes,
  //         ]);
  //         print('✅ Water entry saved to local database with ID: $id');
  //         return id;
  //       } else {
  //         // Fallback to API if database not available
  //         final entryId = await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
  //         print('✅ Water entry saved via API fallback with ID: $entryId');
  //         return entryId;
  //       }
  //     }
  //   } catch (e) {
  //     print('❌ Error saving water entry with ON CONFLICT: $e');
  //     // Try a simpler approach without ON CONFLICT
  //     return await _saveWaterEntrySimple(waterEntry);
  //   }
  // }

  // Fallback method with simpler SQL (check-then-insert/update pattern)
  // static Future<String> _saveWaterEntrySimple(WaterEntry waterEntry) async {
  //   final id = waterEntry.id ?? _generateId();
  //   try {
  //     if (kIsWeb) {
  //       return await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
  //     }
      
  //     if (DatabaseService.isInitialized) {
  //       // Check if entry exists for today
  //       final today = DateTime.now();
  //       final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
  //       final existing = await DatabaseService.queryWater(r'''
  //         SELECT id FROM daily_water 
  //         WHERE user_id = $1 AND date::date = $2::date
  //         LIMIT 1
  //       ''', [waterEntry.userId, todayStr]);
        
  //       if (existing.isNotEmpty) {
  //         // Update existing entry
  //         await DatabaseService.executeWater(r'''
  //           UPDATE daily_water 
  //           SET glasses_consumed = $1, total_ml = $2, target_ml = $3, 
  //               notes = $4, updated_at = CURRENT_TIMESTAMP
  //           WHERE user_id = $5 AND date::date = $6::date
  //         ''', [
  //           waterEntry.glassesConsumed,
  //           waterEntry.totalMl,
  //           waterEntry.targetMl,
  //           waterEntry.notes,
  //           waterEntry.userId,
  //           todayStr,
  //         ]);
  //         print('✅ Water entry updated in local database');
  //         return existing.first['id'].toString();
  //       } else {
  //         // Insert new entry
  //         await DatabaseService.executeWater(r'''
  //           INSERT INTO daily_water 
  //           (id, user_id, date, glasses_consumed, total_ml, target_ml, notes, created_at, updated_at)
  //           VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  //         ''', [
  //           id,
  //           waterEntry.userId,
  //           waterEntry.date.toIso8601String(),
  //           waterEntry.glassesConsumed,
  //           waterEntry.totalMl,
  //           waterEntry.targetMl,
  //           waterEntry.notes,
  //         ]);
  //         print('✅ Water entry inserted into local database with ID: $id');
  //         return id;
  //       }
  //     } else {
  //       // Use API as fallback
  //       return await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
  //     }
  //   } catch (e) {
  //     print('❌ Error in simple save method: $e');
  //     // Last resort - try API even on mobile
  //     try {
  //       final entryId = await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
  //       print('✅ Water entry saved via API as last resort with ID: $entryId');
  //       return entryId;
  //     } catch (apiError) {
  //       print('❌ Final fallback to API also failed: $apiError');
  //       rethrow;
  //     }
  //   }
  // }

  static Future<String> saveWaterEntry(WaterEntry waterEntry) async {
    try {
      final id = waterEntry.id ?? _generateId();
      
      if (kIsWeb) {
        final entryId = await _apiService.saveWaterEntry(waterEntry.copyWith(id: id));
        print('✅ Water entry saved via API with ID: $entryId');
        return entryId;
      } else {
        if (DatabaseService.isInitialized) {
          await DatabaseService.executeWater(r'''
            INSERT INTO daily_water 
            (id, user_id, date, glasses_consumed, total_ml, target_ml, notes, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            ON CONFLICT (user_id, (date::date)) 
            DO UPDATE SET 
              glasses_consumed = EXCLUDED.glasses_consumed,
              total_ml = EXCLUDED.total_ml,
              target_ml = EXCLUDED.target_ml,
              notes = EXCLUDED.notes,
              updated_at = CURRENT_TIMESTAMP
          ''', [
            id,
            waterEntry.userId,
            waterEntry.date.toIso8601String(),
            waterEntry.glassesConsumed,
            waterEntry.totalMl,
            waterEntry.targetMl,
            waterEntry.notes,
          ]);
          print('✅ Water entry saved to local database with ID: $id');
          return id;
        }
      }
    } catch (e) {
      print('❌ Error saving water entry: $e');
      rethrow;
    }
    return '';
  }

  

  static Future<List<WaterEntry>> getWaterHistory(String userId, {int limit = 30}) async {
    try {
      if (kIsWeb) {
        return await _apiService.getWaterHistory(userId, limit: limit);
      } else {
        if (DatabaseService.isInitialized) {
          final results = await DatabaseService.queryWater(r'''
            SELECT * FROM daily_water 
            WHERE user_id = $1 
            ORDER BY date DESC 
            LIMIT $2
          ''', [userId, limit]);
    
          return results.map((row) => WaterEntry.fromMap(row)).toList();
        }
        return [];
      }
    } catch (e) {
      print('Error getting water history: $e');
      return [];
    }
  }

  static Future<WaterEntry?> getWaterEntryByDate(String userId, DateTime date) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      if (kIsWeb) {
        // Use API service for web
        final waterData = await _apiService.getWaterByDate(userId, dateStr);
        
        if (waterData['success'] == true && waterData['entry'] != null) {
          return WaterEntry.fromMap(waterData['entry']);
        }
        return null;
      } else {
        // Use direct database for mobile
        if (DatabaseService.isInitialized) {
          final results = await DatabaseService.queryWater(r'''
            SELECT * FROM daily_water 
            WHERE user_id = $1 AND date::date = $2::date
            LIMIT 1
          ''', [userId, dateStr]);
          
          if (results.isNotEmpty) {
            return WaterEntry.fromMap(results.first);
          }
        }
        return null;
      }
    } catch (e) {
      print('Error getting water entry by date: $e');
      return null;
    }
  }

  static Future<WaterEntry?> getTodayWaterEntry(String userId) async {
    return getWaterEntryByDate(userId, DateTime.now());
  }
}