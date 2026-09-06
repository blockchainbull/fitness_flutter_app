// lib/data/models/day_snapshot.dart
//
// The DaySnapshot read model: a user's full day across every tracker, assembled
// once and consumed by the dashboard and the today report. See
// docs/adr/0002-daily-snapshot-module.md for the design.
//
// Each tracker is a [Section] with an independent load-state, so one failed or
// missing tracker never blanks the whole day.

import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/models/sleep_entry.dart';
import 'package:user_onboarding/data/models/weight_entry.dart';

/// The load-state of one tracker section within a [DaySnapshot].
enum SectionStatus {
  /// Loaded successfully. [Section.value] may still be null when the user
  /// simply logged nothing for this tracker on this day.
  ok,

  /// The read completed but there was no entry for this day.
  missing,

  /// The read failed (network/parse). [Section.error] holds the cause.
  error,
}

/// One tracker's slice of a day, carrying its own load-state so callers can
/// render what loaded and degrade gracefully on the rest.
class Section<T> {
  final SectionStatus status;
  final T? value;
  final Object? error;

  const Section._(this.status, this.value, this.error);

  /// Loaded; [value] may be null when nothing was logged.
  const Section.ok(T? value) : this._(SectionStatus.ok, value, null);

  /// Read succeeded but there is no entry for this day.
  const Section.missing() : this._(SectionStatus.missing, null, null);

  /// Read failed.
  const Section.error(Object error) : this._(SectionStatus.error, null, error);

  bool get isOk => status == SectionStatus.ok;
  bool get isError => status == SectionStatus.error;

  /// True when the tracker has an actual logged value to show.
  bool get hasValue => status == SectionStatus.ok && value != null;
}

/// Meals rolled up for a day: totals for the dashboard, the entry list for the
/// report. Carries both so a single model serves both callers.
class MealsDay {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int count;
  final List<Map<String, dynamic>> entries;

  const MealsDay({
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.count = 0,
    this.entries = const [],
  });
}

/// Exercise rolled up for a day: the entry list plus totals.
class ExerciseDay {
  final List<Map<String, dynamic>> entries;
  final int totalMinutes;
  final double totalCaloriesBurned;

  const ExerciseDay({
    this.entries = const [],
    this.totalMinutes = 0,
    this.totalCaloriesBurned = 0,
  });
}

/// Supplements for a day: each configured supplement and whether it was taken.
class SupplementsDay {
  /// Supplement name -> taken today.
  final Map<String, bool> items;

  const SupplementsDay({this.items = const {}});

  int get totalCount => items.length;
  int get takenCount => items.values.where((taken) => taken).length;
}

/// A user's complete day across all trackers. This is the owner's full day (all
/// entries regardless of their `sharedWithChat` flag), not the shared subset the
/// AI coach sees.
class DaySnapshot {
  final String userId;
  final DateTime date;

  final Section<MealsDay> meals;
  final Section<WaterEntry> water;
  final Section<StepEntry> steps;
  final Section<SleepEntry> sleep;
  final Section<ExerciseDay> exercise;
  final Section<WeightEntry> weight;
  final Section<SupplementsDay> supplements;

  const DaySnapshot({
    required this.userId,
    required this.date,
    this.meals = const Section.missing(),
    this.water = const Section.missing(),
    this.steps = const Section.missing(),
    this.sleep = const Section.missing(),
    this.exercise = const Section.missing(),
    this.weight = const Section.missing(),
    this.supplements = const Section.missing(),
  });

  DaySnapshot copyWith({
    Section<MealsDay>? meals,
    Section<WaterEntry>? water,
    Section<StepEntry>? steps,
    Section<SleepEntry>? sleep,
    Section<ExerciseDay>? exercise,
    Section<WeightEntry>? weight,
    Section<SupplementsDay>? supplements,
  }) {
    return DaySnapshot(
      userId: userId,
      date: date,
      meals: meals ?? this.meals,
      water: water ?? this.water,
      steps: steps ?? this.steps,
      sleep: sleep ?? this.sleep,
      exercise: exercise ?? this.exercise,
      weight: weight ?? this.weight,
      supplements: supplements ?? this.supplements,
    );
  }
}
