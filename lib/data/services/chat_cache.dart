// lib/data/services/chat_cache.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local, per-user cache of the chat transcript so the Chat screen can paint
/// instantly on open instead of waiting on the (sometimes cold-starting)
/// backend. The network fetch still runs and reconciles — this cache only
/// removes the blank-screen wait and keeps the last-known transcript visible
/// when a refresh fails or times out.
///
/// Messages are stored in the same UI shape the ChatPage uses
/// ({text, isUser, timestamp, type}); `timestamp` is serialized as an ISO-8601
/// string and parsed back on read.
class ChatCache {
  static const int _maxMessages = 50;
  static String _key(String userId) => 'chat_history_cache_$userId';

  /// Returns the cached transcript for [userId], newest last. Empty on a cold
  /// cache or any parse error (never throws).
  static Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'text': m['text'] ?? '',
          'isUser': m['isUser'] ?? false,
          'timestamp': DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
          'type': m['type'] ?? 'history',
        };
      }).toList();
    } catch (e) {
      print('[ChatCache] read error (non-fatal): $e');
      return [];
    }
  }

  /// Persists [messages] (UI shape) for [userId], capped to the most recent
  /// [_maxMessages]. Transient message types (e.g. the synthetic welcome) are
  /// dropped so we never cache a stale greeting. Silently no-ops on error.
  static Future<void> saveMessages(
    String userId,
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final persistable = messages
          .where((m) => m['type'] != 'welcome')
          .toList();
      final trimmed = persistable.length > _maxMessages
          ? persistable.sublist(persistable.length - _maxMessages)
          : persistable;

      final encoded = jsonEncode(trimmed.map((m) {
        final ts = m['timestamp'];
        return {
          'text': m['text'] ?? '',
          'isUser': m['isUser'] ?? false,
          'timestamp': ts is DateTime
              ? ts.toIso8601String()
              : (ts?.toString() ?? DateTime.now().toIso8601String()),
          'type': m['type'] ?? 'history',
        };
      }).toList());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId), encoded);
    } catch (e) {
      print('[ChatCache] write error (non-fatal): $e');
    }
  }

  /// Clears the cached transcript for [userId] (used by "Clear Chat").
  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
    } catch (e) {
      print('[ChatCache] clear error (non-fatal): $e');
    }
  }
}
