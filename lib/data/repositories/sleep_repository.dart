// lib/data/repositories/sleep_repository.dart
import 'package:user_onboarding/data/models/sleep_entry.dart';
import 'package:user_onboarding/data/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SleepRepository {
  final _uuid = const Uuid();
  static const String _sleepEntriesKey = 'sleep_entries';

  // Helper method to ensure database is ready
  Future<bool> _ensureDatabaseConnection() async {
    if (!DatabaseService.isAvailable) {
      print('🔄 Database not available, attempting to reconnect...');
      try {
        await DatabaseService.initialize();
        if (DatabaseService.isAvailable) {
          print('✅ Database reconnected successfully');
          return true;
        }
      } catch (e) {
        print('❌ Database reconnection failed: $e');
      }
      return false;
    }
    return true;
  }

  // Create sleep entry with better error handling
  Future<SleepEntry> createSleepEntry(SleepEntry entry) async {
    final id = _uuid.v4();
    final entryWithId = entry.copyWith(id: id);
    
    // Try to ensure database connection first
    final hasDatabase = await _ensureDatabaseConnection();
    
    if (hasDatabase) {
      try {
        await DatabaseService.execute('''
          INSERT INTO daily_sleep (
            id, user_id, date, bedtime, wake_time, 
            total_hours, quality_score, deep_sleep_hours, 
            sleep_issues, notes, created_at
          ) VALUES (
            @id, @userId, @date, @bedtime, @wakeTime,
            @totalHours, @qualityScore, @deepSleepHours,
            @sleepIssues, @notes, @createdAt
          )
        ''', {
          'id': id,
          'userId': entry.userId,
          'date': entry.date.toIso8601String(),
          'bedtime': entry.bedtime?.toIso8601String(),
          'wakeTime': entry.wakeTime?.toIso8601String(),
          'totalHours': entry.totalHours,
          'qualityScore': entry.qualityScore,
          'deepSleepHours': entry.deepSleepHours,
          'sleepIssues': entry.sleepIssues.join(','),
          'notes': entry.notes,
          'createdAt': entry.createdAt.toIso8601String(),
        });
        
        print('✅ Sleep entry saved to database');
        // Also save to local storage as backup
        await _saveToLocalStorage(entryWithId);
        return entryWithId;
      } catch (e) {
        print('⚠️ Database save failed, using local storage: $e');
      }
    } else {
      print('📱 Database unavailable, using local storage only');
    }
    
    // Fallback to local storage
    await _saveToLocalStorage(entryWithId);
    print('✅ Sleep entry saved to local storage');
    return entryWithId;
  }

  // Update sleep entry with better error handling
  Future<SleepEntry> updateSleepEntry(SleepEntry entry) async {
    final hasDatabase = await _ensureDatabaseConnection();
    
    if (hasDatabase) {
      try {
        final rowsAffected = await DatabaseService.execute('''
          UPDATE daily_sleep SET
            bedtime = @bedtime,
            wake_time = @wakeTime,
            total_hours = @totalHours,
            quality_score = @qualityScore,
            deep_sleep_hours = @deepSleepHours,
            sleep_issues = @sleepIssues,
            notes = @notes,
            created_at = @createdAt
          WHERE id = @id
        ''', {
          'id': entry.id,
          'bedtime': entry.bedtime?.toIso8601String(),
          'wakeTime': entry.wakeTime?.toIso8601String(),
          'totalHours': entry.totalHours,
          'qualityScore': entry.qualityScore,
          'deepSleepHours': entry.deepSleepHours,
          'sleepIssues': entry.sleepIssues.join(','),
          'notes': entry.notes,
          'createdAt': entry.createdAt.toIso8601String(),
        });
        
        if (rowsAffected > 0) {
          print('✅ Sleep entry updated in database');
          await _updateInLocalStorage(entry);
          return entry;
        }
      } catch (e) {
        print('⚠️ Database update failed, using local storage: $e');
      }
    }
    
    // Fallback to local storage
    await _updateInLocalStorage(entry);
    print('✅ Sleep entry updated in local storage');
    return entry;
  }

  // Get sleep entry by date with better error handling
  Future<SleepEntry?> getSleepEntryByDate(String userId, DateTime date) async {
    final hasDatabase = await _ensureDatabaseConnection();
    
    if (hasDatabase) {
      try {
        final results = await DatabaseService.query('''
          SELECT * FROM daily_sleep 
          WHERE user_id = @userId 
          AND DATE(date) = DATE(@date)
          ORDER BY created_at DESC
          LIMIT 1
        ''', {
          'userId': userId,
          'date': date.toIso8601String(),
        });

        if (results.isNotEmpty) {
          print('✅ Sleep entry found in database');
          return SleepEntry.fromMap(results.first);
        }
      } catch (e) {
        print('⚠️ Database query failed: $e');
      }
    }
    
    // Fallback to local storage
    final localEntry = await _getFromLocalStorageByDate(userId, date);
    if (localEntry != null) {
      print('✅ Sleep entry found in local storage');
    }
    return localEntry;
  }

  // Get sleep history with better error handling
  Future<List<SleepEntry>> getSleepHistory(String userId, {int limit = 30}) async {
    final hasDatabase = await _ensureDatabaseConnection();
    
    if (hasDatabase) {
      try {
        final results = await DatabaseService.query('''
          SELECT * FROM daily_sleep 
          WHERE user_id = @userId 
          ORDER BY date DESC
          LIMIT @limit
        ''', {
          'userId': userId,
          'limit': limit,
        });

        if (results.isNotEmpty) {
          print('✅ Sleep history loaded from database (${results.length} entries)');
          return results.map((row) => SleepEntry.fromMap(row)).toList();
        }
      } catch (e) {
        print('⚠️ Database history query failed: $e');
      }
    }
    
    // Fallback to local storage
    final localHistory = await _getHistoryFromLocalStorage(userId, limit: limit);
    print('✅ Sleep history loaded from local storage (${localHistory.length} entries)');
    return localHistory;
  }

  // Get sleep stats with better error handling
  Future<Map<String, dynamic>> getSleepStats(String userId, {int days = 30}) async {
    final hasDatabase = await _ensureDatabaseConnection();
    
    if (hasDatabase) {
      try {
        final results = await DatabaseService.query('''
          SELECT 
            AVG(total_hours) as avg_sleep,
            AVG(quality_score) as avg_quality,
            AVG(deep_sleep_hours) as avg_deep_sleep,
            COUNT(*) as entries_count,
            MIN(date) as first_entry,
            MAX(date) as last_entry
          FROM daily_sleep 
          WHERE user_id = @userId 
          AND date >= @since
        ''', {
          'userId': userId,
          'since': DateTime.now().subtract(Duration(days: days)).toIso8601String(),
        });

        if (results.isNotEmpty) {
          final row = results.first;
          print('✅ Sleep stats loaded from database');
          return {
            'avgSleep': (row['avg_sleep'] ?? 0.0).toDouble(),
            'avgQuality': (row['avg_quality'] ?? 0.0).toDouble(),
            'avgDeepSleep': (row['avg_deep_sleep'] ?? 0.0).toDouble(),
            'entriesCount': row['entries_count'] ?? 0,
            'firstEntry': row['first_entry'],
            'lastEntry': row['last_entry'],
          };
        }
      } catch (e) {
        print('⚠️ Database stats query failed: $e');
      }
    }
    
    // Fallback to local storage
    final localStats = await _getStatsFromLocalStorage(userId, days: days);
    print('✅ Sleep stats loaded from local storage');
    return localStats;
  }

  // Rest of the local storage methods remain the same...
  Future<void> _saveToLocalStorage(SleepEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _getLocalStorageEntries();
    
    // Remove existing entry for the same date/user if it exists
    entries.removeWhere((e) => 
      e['user_id'] == entry.userId && 
      e['date'].toString().substring(0, 10) == entry.date.toIso8601String().substring(0, 10)
    );
    
    entries.add(entry.toMap());
    await prefs.setString(_sleepEntriesKey, jsonEncode(entries));
  }

  Future<void> _updateInLocalStorage(SleepEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await _getLocalStorageEntries();
    final index = entries.indexWhere((e) => e['id'] == entry.id);
    if (index != -1) {
      entries[index] = entry.toMap();
    } else {
      entries.add(entry.toMap());
    }
    await prefs.setString(_sleepEntriesKey, jsonEncode(entries));
  }

  Future<SleepEntry?> _getFromLocalStorageByDate(String userId, DateTime date) async {
    final entries = await _getLocalStorageEntries();
    final dateString = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    for (final entryMap in entries) {
      if (entryMap['user_id'] == userId) {
        final entryDateString = entryMap['date'].toString().substring(0, 10);
        if (entryDateString == dateString) {
          return SleepEntry.fromMap(entryMap);
        }
      }
    }
    return null;
  }

  Future<List<SleepEntry>> _getHistoryFromLocalStorage(String userId, {int limit = 30}) async {
    final entries = await _getLocalStorageEntries();
    final userEntries = entries
        .where((e) => e['user_id'] == userId)
        .map((e) => SleepEntry.fromMap(e))
        .toList();
    
    userEntries.sort((a, b) => b.date.compareTo(a.date));
    return userEntries.take(limit).toList();
  }

  Future<Map<String, dynamic>> _getStatsFromLocalStorage(String userId, {int days = 30}) async {
    final entries = await _getLocalStorageEntries();
    final since = DateTime.now().subtract(Duration(days: days));
    
    final userEntries = entries
        .where((e) => e['user_id'] == userId)
        .map((e) => SleepEntry.fromMap(e))
        .where((e) => e.date.isAfter(since))
        .toList();
    
    if (userEntries.isEmpty) {
      return {
        'avgSleep': 0.0,
        'avgQuality': 0.0,
        'avgDeepSleep': 0.0,
        'entriesCount': 0,
        'firstEntry': null,
        'lastEntry': null,
      };
    }

    final avgSleep = userEntries.map((e) => e.totalHours).reduce((a, b) => a + b) / userEntries.length;
    final avgQuality = userEntries.map((e) => e.qualityScore).reduce((a, b) => a + b) / userEntries.length;
    final avgDeepSleep = userEntries.map((e) => e.deepSleepHours).reduce((a, b) => a + b) / userEntries.length;
    
    userEntries.sort((a, b) => a.date.compareTo(b.date));
    
    return {
      'avgSleep': avgSleep,
      'avgQuality': avgQuality,
      'avgDeepSleep': avgDeepSleep,
      'entriesCount': userEntries.length,
      'firstEntry': userEntries.first.date.toIso8601String(),
      'lastEntry': userEntries.last.date.toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> _getLocalStorageEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_sleepEntriesKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error decoding sleep entries: $e');
      return [];
    }
  }
}