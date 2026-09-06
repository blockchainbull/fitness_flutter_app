// lib/data/services/daily_snapshot.dart
//
// DailySnapshot: the deep read module for "a user's day". One interface —
// forDay(userId, date) — hides a parallel fan-out across every tracker, with
// per-section error isolation and a cache-first read for today. Absorbs the old
// MetricsService. See docs/adr/0002-daily-snapshot-module.dart.
//
// Data sources are injected as normalized readers so the module is testable
// through fakes and independent of each Api's exact method shape.

import 'package:intl/intl.dart';
import 'package:user_onboarding/data/models/day_snapshot.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/models/sleep_entry.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';
import 'package:user_onboarding/data/repositories/sleep_repository.dart';
import 'package:user_onboarding/data/services/api/meal_api.dart';
import 'package:user_onboarding/data/services/api/water_api.dart';
import 'package:user_onboarding/data/services/api/exercise_api.dart';
import 'package:user_onboarding/data/services/api/weight_api.dart';
import 'package:user_onboarding/data/services/api/supplement_api.dart';
import 'package:user_onboarding/utils/day_data_notifier.dart';

/// Reads one tracker for (userId, date). Normalized so every source has the
/// same injectable shape regardless of its underlying Api signature.
typedef MealsReader = Future<Map<String, dynamic>> Function(String userId, DateTime date);
typedef WaterReader = Future<WaterEntry?> Function(String userId, DateTime date);
typedef StepsReader = Future<StepEntry?> Function(String userId, DateTime date);
typedef SleepReader = Future<SleepEntry?> Function(String userId, DateTime date);
typedef ExerciseReader = Future<List<Map<String, dynamic>>> Function(String userId, DateTime date);
typedef WeightReader = Future<WeightEntry?> Function(String userId, DateTime date);
typedef SupplementsReader = Future<Map<String, bool>> Function(String userId, DateTime date);

String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class DailySnapshot {
  final MealsReader _readMeals;
  final WaterReader _readWater;
  final StepsReader _readSteps;
  final SleepReader _readSleep;
  final ExerciseReader _readExercise;
  final WeightReader _readWeight;
  final SupplementsReader _readSupplements;
  final DateTime Function() _clock;

  /// In-memory cache for the current day only, keyed by userId.
  final Map<String, DaySnapshot> _todayCache = {};

  DailySnapshot({
    MealsReader? readMeals,
    WaterReader? readWater,
    StepsReader? readSteps,
    SleepReader? readSleep,
    ExerciseReader? readExercise,
    WeightReader? readWeight,
    SupplementsReader? readSupplements,
    DateTime Function()? clock,
  })  : _readMeals = readMeals ?? _defaultMeals,
        _readWater = readWater ?? _defaultWater,
        _readSteps = readSteps ?? StepRepository.getStepEntryByDate,
        _readSleep = readSleep ?? _defaultSleep,
        _readExercise = readExercise ?? _defaultExercise,
        _readWeight = readWeight ?? _defaultWeight,
        _readSupplements = readSupplements ?? _defaultSupplements,
        _clock = clock ?? DateTime.now;

  // --- Default readers, adapting the real Apis to the normalized shape. ---

  static Future<Map<String, dynamic>> _defaultMeals(String u, DateTime d) =>
      MealApi().getDailySummary(u, date: _fmt(d));

  static Future<WaterEntry?> _defaultWater(String u, DateTime d) =>
      WaterApi().getWaterEntryByDate(u, d);

  static final SleepRepository _sleepRepo = SleepRepository();
  static Future<SleepEntry?> _defaultSleep(String u, DateTime d) =>
      _sleepRepo.getSleepEntryByDate(u, d);

  static Future<List<Map<String, dynamic>>> _defaultExercise(String u, DateTime d) =>
      ExerciseApi().getExerciseLogs(u, startDate: _fmt(d), endDate: _fmt(d));

  static Future<WeightEntry?> _defaultWeight(String u, DateTime d) async {
    final history = await WeightApi().getWeightHistory(u);
    for (final entry in history) {
      if (_sameDay(entry.date, d)) return entry;
    }
    return null;
  }

  static Future<Map<String, bool>> _defaultSupplements(String u, DateTime d) =>
      SupplementApi().getSupplementStatusByDate(u, _fmt(d));

  // --- Public interface ---

  /// The cached snapshot for [date] if it is today and has been loaded, else
  /// null. Lets a caller paint instantly before [forDay] resolves.
  DaySnapshot? cachedDay(String userId, DateTime date) {
    final cached = _todayCache[userId];
    if (cached != null && _sameDay(cached.date, date)) return cached;
    return null;
  }

  /// Assemble the full day for [userId] on [date]. Fans out to every tracker in
  /// parallel; a failed or missing tracker degrades that section only. Today's
  /// result is cached.
  Future<DaySnapshot> forDay(String userId, DateTime date) async {
    final results = await Future.wait([
      _mealsSection(userId, date),
      _entrySection<WaterEntry>(() => _readWater(userId, date)),
      _entrySection<StepEntry>(() => _readSteps(userId, date)),
      _entrySection<SleepEntry>(() => _readSleep(userId, date)),
      _exerciseSection(userId, date),
      _entrySection<WeightEntry>(() => _readWeight(userId, date)),
      _supplementsSection(userId, date),
    ]);

    final snapshot = DaySnapshot(
      userId: userId,
      date: date,
      meals: results[0] as Section<MealsDay>,
      water: results[1] as Section<WaterEntry>,
      steps: results[2] as Section<StepEntry>,
      sleep: results[3] as Section<SleepEntry>,
      exercise: results[4] as Section<ExerciseDay>,
      weight: results[5] as Section<WeightEntry>,
      supplements: results[6] as Section<SupplementsDay>,
    );

    if (_sameDay(date, _clock())) {
      _todayCache[userId] = snapshot;
    }
    return snapshot;
  }

  /// Re-fetch a single [tracker] for [date] and, when it is today, patch the
  /// cached snapshot. Returns the updated (or freshly built) snapshot. Used to
  /// respond to a DayDataNotifier signal without re-reading the whole day.
  Future<DaySnapshot> revalidateSection(
      String userId, DateTime date, Tracker tracker) async {
    var base = cachedDay(userId, date) ??
        DaySnapshot(userId: userId, date: date);

    switch (tracker) {
      case Tracker.meals:
        base = base.copyWith(meals: await _mealsSection(userId, date));
        break;
      case Tracker.water:
        base = base.copyWith(
            water: await _entrySection<WaterEntry>(() => _readWater(userId, date)));
        break;
      case Tracker.steps:
        base = base.copyWith(
            steps: await _entrySection<StepEntry>(() => _readSteps(userId, date)));
        break;
      case Tracker.sleep:
        base = base.copyWith(
            sleep: await _entrySection<SleepEntry>(() => _readSleep(userId, date)));
        break;
      case Tracker.exercise:
        base = base.copyWith(exercise: await _exerciseSection(userId, date));
        break;
      case Tracker.weight:
        base = base.copyWith(
            weight: await _entrySection<WeightEntry>(() => _readWeight(userId, date)));
        break;
      case Tracker.supplements:
        base = base.copyWith(supplements: await _supplementsSection(userId, date));
        break;
    }

    if (_sameDay(date, _clock())) {
      _todayCache[userId] = base;
    }
    return base;
  }

  /// Clear cached state (e.g. on logout).
  void clearCache() => _todayCache.clear();

  // --- Section builders (each isolates its own failure). ---

  /// A single-entry section: null -> missing, value -> ok, throw -> error.
  Future<Section<T>> _entrySection<T>(Future<T?> Function() read) async {
    try {
      final value = await read();
      return value == null ? Section<T>.missing() : Section<T>.ok(value);
    } catch (e) {
      return Section<T>.error(e);
    }
  }

  Future<Section<MealsDay>> _mealsSection(String userId, DateTime date) async {
    try {
      final data = await _readMeals(userId, date);
      final totals = (data['totals'] as Map?) ?? const {};
      double asDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
      return Section.ok(MealsDay(
        calories: asDouble(totals['calories']),
        proteinG: asDouble(totals['protein_g']),
        carbsG: asDouble(totals['carbs_g']),
        fatG: asDouble(totals['fat_g']),
        count: (data['meals_count'] as num?)?.toInt() ?? 0,
        entries: (data['meals'] is List)
            ? List<Map<String, dynamic>>.from(data['meals'])
            : const [],
      ));
    } catch (e) {
      return Section<MealsDay>.error(e);
    }
  }

  Future<Section<ExerciseDay>> _exerciseSection(String userId, DateTime date) async {
    try {
      final logs = await _readExercise(userId, date);
      final dateStr = _fmt(date);
      // Keep only entries actually dated to this day (mirrors the report screen).
      final dayLogs = logs.where((ex) {
        final exDate = (ex['exercise_date'] ?? ex['created_at'])?.toString();
        return exDate == null || exDate.startsWith(dateStr);
      }).toList();

      var minutes = 0;
      var calories = 0.0;
      for (final ex in dayLogs) {
        minutes += (ex['duration_minutes'] as num?)?.toInt() ?? 0;
        calories += (ex['calories_burned'] as num?)?.toDouble() ?? 0.0;
      }
      return Section.ok(ExerciseDay(
        entries: dayLogs,
        totalMinutes: minutes,
        totalCaloriesBurned: calories,
      ));
    } catch (e) {
      return Section<ExerciseDay>.error(e);
    }
  }

  Future<Section<SupplementsDay>> _supplementsSection(String userId, DateTime date) async {
    try {
      final status = await _readSupplements(userId, date);
      return Section.ok(SupplementsDay(items: Map<String, bool>.from(status)));
    } catch (e) {
      return Section<SupplementsDay>.error(e);
    }
  }
}
