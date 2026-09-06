// lib/utils/day_data_notifier.dart
//
// Lightweight signal fired by a tracking screen after it successfully writes an
// entry, so read models (DailySnapshot) can revalidate just the affected
// section for the affected day. Mirrors ProfileUpdateNotifier's pattern.
// See docs/adr/0002-daily-snapshot-module.dart.

import 'dart:async';

/// The trackers a day is composed of. Also used to scope a change signal.
enum Tracker { meals, water, steps, sleep, exercise, weight, supplements }

/// A write happened for one tracker on one day.
class DayDataChange {
  final String userId;
  final DateTime date;
  final Tracker tracker;

  const DayDataChange(this.userId, this.date, this.tracker);
}

class DayDataNotifier {
  static final DayDataNotifier _instance = DayDataNotifier._internal();
  factory DayDataNotifier() => _instance;
  DayDataNotifier._internal();

  final _controller = StreamController<DayDataChange>.broadcast();

  /// Fires whenever a tracker entry is written.
  Stream<DayDataChange> get changes => _controller.stream;

  /// Called by a tracking screen after a successful write.
  void markChanged(String userId, DateTime date, Tracker tracker) {
    if (!_controller.isClosed) {
      _controller.add(DayDataChange(userId, date, tracker));
    }
  }

  void dispose() {
    _controller.close();
  }
}
