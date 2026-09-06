import 'package:flutter_test/flutter_test.dart';
import 'package:user_onboarding/data/models/day_snapshot.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/services/daily_snapshot.dart';

/// Tests the DailySnapshot fan-out through injected fake readers — no network.
/// Verifies per-section error isolation, today-only caching, and surgical
/// section revalidation. See docs/adr/0002-daily-snapshot-module.dart.
void main() {
  final today = DateTime(2026, 9, 6);
  DateTime clock() => DateTime(2026, 9, 6, 12, 0);

  WaterEntry water(int glasses) =>
      WaterEntry(userId: 'u1', date: today, glassesConsumed: glasses, targetMl: 2000);
  StepEntry steps(int n) => StepEntry(userId: 'u1', date: today, steps: n, goal: 10000);

  DailySnapshot buildModule({
    Future<StepEntry?> Function(String, DateTime)? readSteps,
    Future<WaterEntry?> Function(String, DateTime)? readWater,
    Future<Map<String, bool>> Function(String, DateTime)? readSupplements,
  }) {
    return DailySnapshot(
      clock: clock,
      readMeals: (u, d) async => {
        'totals': {'calories': 1800.0, 'protein_g': 90.0, 'carbs_g': 200.0, 'fat_g': 60.0},
        'meals_count': 3,
      },
      readWater: readWater ?? (u, d) async => water(5),
      readSteps: readSteps ?? (u, d) async => steps(8000),
      readSleep: (u, d) async => null, // nothing logged -> missing
      readExercise: (u, d) async => [
        {'exercise_date': '2026-09-06', 'duration_minutes': 30, 'calories_burned': 250},
        {'exercise_date': '2026-09-05', 'duration_minutes': 99, 'calories_burned': 999}, // other day, filtered out
      ],
      readWeight: (u, d) async => null,
      readSupplements: readSupplements ?? (u, d) async => {'D3': true, 'Omega': false},
    );
  }

  test('forDay assembles sections from the readers', () async {
    final snap = await buildModule().forDay('u1', today);

    expect(snap.meals.value!.calories, 1800);
    expect(snap.meals.value!.count, 3);
    expect(snap.water.value!.glassesConsumed, 5);
    expect(snap.steps.value!.steps, 8000);
    expect(snap.sleep.status, SectionStatus.missing); // reader returned null
    expect(snap.exercise.value!.totalMinutes, 30); // other-day entry excluded
    expect(snap.supplements.value!.takenCount, 1);
    expect(snap.supplements.value!.totalCount, 2);
  });

  test('a failing reader degrades only its own section', () async {
    final module = buildModule(
      readSteps: (u, d) async => throw Exception('steps API down'),
    );
    final snap = await module.forDay('u1', today);

    expect(snap.steps.isError, isTrue); // isolated failure
    expect(snap.water.hasValue, isTrue); // neighbours unaffected
    expect(snap.meals.hasValue, isTrue);
  });

  test('today is cached; other days are not', () async {
    final module = buildModule();
    expect(module.cachedDay('u1', today), isNull); // nothing loaded yet

    await module.forDay('u1', today);
    expect(module.cachedDay('u1', today), isNotNull);

    final otherDay = DateTime(2026, 9, 1);
    await module.forDay('u1', otherDay);
    expect(module.cachedDay('u1', otherDay), isNull); // not today -> not cached
  });

  test('clearCache drops cached days', () async {
    final module = buildModule();
    await module.forDay('u1', today);
    module.clearCache();
    expect(module.cachedDay('u1', today), isNull);
  });
}
