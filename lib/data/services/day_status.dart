// lib/data/services/day_status.dart
//
// Pure projection over a DaySnapshot: given the logged data and the user's
// goals, derive per-tracker status (value, target, completeness). No I/O, no
// dependency on the profile existing — the client twin of the backend's
// health-insights. See docs/adr/0002-daily-snapshot-module.dart.

import 'package:user_onboarding/data/models/day_snapshot.dart';

/// The goals a day's progress is measured against. Callers build this from the
/// user profile / preferences; the projection itself stays pure.
class DayGoals {
  final int? stepGoal;
  final int? waterGlassesGoal;
  final double? calorieGoal;
  final double? sleepHoursGoal;

  const DayGoals({
    this.stepGoal,
    this.waterGlassesGoal,
    this.calorieGoal,
    this.sleepHoursGoal,
  });
}

/// One tracker's derived status: where it stands, its target if any, and
/// whether the target has been met.
class MetricStatus {
  final double value;
  final double? target;

  const MetricStatus({required this.value, this.target});

  /// Complete when a target exists and the value has reached it.
  bool get isComplete => target != null && target! > 0 && value >= target!;

  /// Progress in [0, 1] against the target, or null when there is no target.
  double? get progress {
    final t = target;
    if (t == null || t <= 0) return null;
    final p = value / t;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }
}

/// The full day's derived status. Sections with no logged value report a value
/// of 0 against whatever target the goals supply.
class DayStatus {
  final MetricStatus steps;
  final MetricStatus water;
  final MetricStatus calories;
  final MetricStatus sleep;
  final MetricStatus exercise;
  final MetricStatus supplements;

  const DayStatus({
    required this.steps,
    required this.water,
    required this.calories,
    required this.sleep,
    required this.exercise,
    required this.supplements,
  });
}

/// Derive [DayStatus] from a [DaySnapshot] and the user's [DayGoals]. Pure.
DayStatus dayStatus(DaySnapshot snapshot, DayGoals goals) {
  // Steps: prefer the explicit goal, else the goal stored on the entry.
  final stepEntry = snapshot.steps.value;
  final steps = MetricStatus(
    value: (stepEntry?.steps ?? 0).toDouble(),
    target: (goals.stepGoal ?? stepEntry?.goal)?.toDouble(),
  );

  // Water: glasses consumed vs a glasses goal (fall back to targetMl/250ml).
  final waterEntry = snapshot.water.value;
  final derivedGlassGoal = waterEntry != null && waterEntry.targetMl > 0
      ? (waterEntry.targetMl / 250).round()
      : null;
  final water = MetricStatus(
    value: (waterEntry?.glassesConsumed ?? 0).toDouble(),
    target: (goals.waterGlassesGoal ?? derivedGlassGoal)?.toDouble(),
  );

  final calories = MetricStatus(
    value: snapshot.meals.value?.calories ?? 0,
    target: goals.calorieGoal,
  );

  final sleep = MetricStatus(
    value: snapshot.sleep.value?.totalHours ?? 0,
    target: goals.sleepHoursGoal,
  );

  // Exercise has no completeness target here — surface the minutes logged.
  final exercise = MetricStatus(
    value: (snapshot.exercise.value?.totalMinutes ?? 0).toDouble(),
  );

  // Supplements: taken vs total configured (complete when all taken).
  final supp = snapshot.supplements.value;
  final supplements = MetricStatus(
    value: (supp?.takenCount ?? 0).toDouble(),
    target: (supp?.totalCount ?? 0) > 0 ? supp!.totalCount.toDouble() : null,
  );

  return DayStatus(
    steps: steps,
    water: water,
    calories: calories,
    sleep: sleep,
    exercise: exercise,
    supplements: supplements,
  );
}
