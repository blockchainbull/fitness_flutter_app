import 'package:flutter_test/flutter_test.dart';
import 'package:user_onboarding/data/models/day_snapshot.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/models/sleep_entry.dart';
import 'package:user_onboarding/data/services/day_status.dart';

/// Pure-projection tests for F1's DaySnapshot core. No I/O: DaySnapshot in,
/// DayStatus out. See docs/adr/0002-daily-snapshot-module.dart.
void main() {
  final date = DateTime(2026, 9, 6);

  DaySnapshot snapshotWith({
    Section<StepEntry>? steps,
    Section<WaterEntry>? water,
    Section<MealsDay>? meals,
    Section<SleepEntry>? sleep,
    Section<SupplementsDay>? supplements,
  }) {
    return DaySnapshot(
      userId: 'u1',
      date: date,
      steps: steps ?? const Section.missing(),
      water: water ?? const Section.missing(),
      meals: meals ?? const Section.missing(),
      sleep: sleep ?? const Section.missing(),
      supplements: supplements ?? const Section.missing(),
    );
  }

  group('Section load-state', () {
    test('ok with a value reports hasValue', () {
      const s = Section.ok(MealsDay(calories: 100));
      expect(s.isOk, isTrue);
      expect(s.hasValue, isTrue);
    });

    test('ok with null value is loaded but has no value', () {
      const s = Section<MealsDay>.ok(null);
      expect(s.isOk, isTrue);
      expect(s.hasValue, isFalse);
    });

    test('error carries the cause and is not ok', () {
      final s = Section<MealsDay>.error(Exception('boom'));
      expect(s.isError, isTrue);
      expect(s.hasValue, isFalse);
      expect(s.error, isNotNull);
    });
  });

  group('dayStatus projection', () {
    test('steps use explicit goal over the entry goal', () {
      final snap = snapshotWith(
        steps: Section.ok(StepEntry(userId: 'u1', date: date, steps: 8000, goal: 10000)),
      );
      final status = dayStatus(snap, const DayGoals(stepGoal: 12000));
      expect(status.steps.value, 8000);
      expect(status.steps.target, 12000);
      expect(status.steps.isComplete, isFalse);
      expect(status.steps.progress, closeTo(8000 / 12000, 1e-9));
    });

    test('steps fall back to the entry goal when no explicit goal', () {
      final snap = snapshotWith(
        steps: Section.ok(StepEntry(userId: 'u1', date: date, steps: 10500, goal: 10000)),
      );
      final status = dayStatus(snap, const DayGoals());
      expect(status.steps.target, 10000);
      expect(status.steps.isComplete, isTrue);
      expect(status.steps.progress, 1.0); // clamped
    });

    test('water derives a glasses target from targetMl when no goal given', () {
      final snap = snapshotWith(
        water: Section.ok(WaterEntry(
          userId: 'u1',
          date: date,
          glassesConsumed: 4,
          targetMl: 2000, // -> 8 glasses at 250ml
        )),
      );
      final status = dayStatus(snap, const DayGoals());
      expect(status.water.value, 4);
      expect(status.water.target, 8);
      expect(status.water.isComplete, isFalse);
    });

    test('missing sections project to zero value and no completeness', () {
      final status = dayStatus(snapshotWith(), const DayGoals());
      expect(status.steps.value, 0);
      expect(status.steps.target, isNull);
      expect(status.steps.isComplete, isFalse);
      expect(status.calories.value, 0);
      expect(status.supplements.target, isNull);
    });

    test('supplements complete when all configured are taken', () {
      final snap = snapshotWith(
        supplements: const Section.ok(SupplementsDay(items: {'D3': true, 'Omega': true})),
      );
      final status = dayStatus(snap, const DayGoals());
      expect(status.supplements.value, 2);
      expect(status.supplements.target, 2);
      expect(status.supplements.isComplete, isTrue);
    });

    test('calories measured against the calorie goal', () {
      final snap = snapshotWith(meals: const Section.ok(MealsDay(calories: 1800)));
      final status = dayStatus(snap, const DayGoals(calorieGoal: 2000));
      expect(status.calories.value, 1800);
      expect(status.calories.isComplete, isFalse);
    });
  });

  test('SupplementsDay derives counts', () {
    const s = SupplementsDay(items: {'a': true, 'b': false, 'c': true});
    expect(s.totalCount, 3);
    expect(s.takenCount, 2);
  });
}
