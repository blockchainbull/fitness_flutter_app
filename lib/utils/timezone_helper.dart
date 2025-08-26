// lib/utils/timezone_helper.dart
import 'package:intl/intl.dart';

class TimezoneHelper {
  /// Get the current timezone offset in minutes
  static int getTimezoneOffsetMinutes() {
    return DateTime.now().timeZoneOffset.inMinutes;
  }
  
  /// Get timezone offset as a string (e.g., "+05:00" or "-08:00")
  static String getTimezoneOffsetString() {
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
  
  /// Get a map with complete timezone info
  static Map<String, dynamic> getTimezoneInfo() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    
    return {
      'offset_minutes': offset.inMinutes,
      'offset_string': getTimezoneOffsetString(),
      'timezone_name': now.timeZoneName, // Like 'PKT' or 'EST'
    };
  }
  
  /// Convert a DateTime to a date string in local timezone (YYYY-MM-DD)
  static String toLocalDateString(DateTime date) {
    final local = date.toLocal();
    return DateFormat('yyyy-MM-dd').format(local);
  }
  
  /// Convert a DateTime to a full datetime string with timezone info
  static Map<String, dynamic> toApiDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return {
      'datetime': local.toIso8601String(),
      'date': toLocalDateString(local),
      'timezone_offset': getTimezoneOffsetMinutes(),
    };
  }
  
  /// Get "today" in local timezone at midnight
  static DateTime getTodayLocal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  
  /// Parse a date from the API (handles timezone conversion)
  static DateTime parseApiDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is Map) {
      // New format with timezone info
      if (dateValue.containsKey('date')) {
        return DateTime.parse(dateValue['date']);
      }
    }
    
    if (dateValue is String) {
      // Handle different date formats
      if (dateValue.contains('T')) {
        // It's a datetime string
        return DateTime.parse(dateValue).toLocal();
      } else {
        // It's just a date (YYYY-MM-DD)
        return DateTime.parse('${dateValue}T00:00:00');
      }
    }
    
    return DateTime.now();
  }
}