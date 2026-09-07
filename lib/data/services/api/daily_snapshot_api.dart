// lib/data/services/api/daily_snapshot_api.dart
//
// The owner's whole day in one request. Backs DailySnapshot.forDay, which
// previously fanned out across seven endpoints.
//
// Response shape is frozen in docs/adr/0003-daily-snapshot-contract-request.md
// and served by the backend's GET /daily-snapshot/{user_id}/{date}.

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:user_onboarding/data/services/api/api_client.dart';

class DailySnapshotApi {
  final ApiClient _client;

  DailySnapshotApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// The raw snapshot document for [userId] on [date].
  ///
  /// Returns the decoded body as-is; interpreting the sections (and the
  /// `_read_errors` map that separates "this tracker failed" from "nothing
  /// logged") is [DailySnapshot]'s job, not the transport's.
  ///
  /// Throws on any non-200 so the caller can mark the whole day as failed.
  /// A per-section failure is *not* an error here -- it arrives inside a 200.
  Future<Map<String, dynamic>> getDay(String userId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _client.get('/daily-snapshot/$userId/$dateStr');

    if (response.statusCode != 200) {
      throw Exception(
        'Daily snapshot failed for $dateStr: HTTP ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Daily snapshot returned ${decoded.runtimeType}');
    }
    return decoded;
  }
}
