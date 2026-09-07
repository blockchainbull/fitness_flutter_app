import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/models/water_entry.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/services/daily_snapshot.dart';
import 'package:user_onboarding/features/reports/screens/today_report_screen.dart';

/// Widget test proving F3's seam: TodayReportScreen renders from an injected
/// DailySnapshot. The "fake" is a real DailySnapshot with canned readers (all
/// seven, so no real Api/network is touched). See docs/adr/0004-...md.
void main() {
  final today = DateTime(2026, 9, 7);

  UserProfile testProfile() => UserProfile(
        id: 'u1',
        name: 'Test',
        email: 't@example.com',
        gender: 'female',
        age: 30,
        height: 165,
        weight: 60,
        activityLevel: 'moderate',
        primaryGoal: 'maintain',
        weightGoal: 'maintain_weight',
        sleepHours: 8,
        bedtime: '22:00',
        wakeupTime: '06:00',
        dailyStepGoal: 10000,
        sleepIssues: const [],
        dietaryPreferences: const [],
        waterIntake: 2000,
        waterIntakeGlasses: 8,
        medicalConditions: const [],
        preferredWorkouts: const [],
        workoutFrequency: 3,
        workoutDuration: 30,
        workoutLocation: 'home',
        availableEquipment: const [],
        fitnessLevel: 'beginner',
        hasTrainer: false,
      );

  /// A DailySnapshot whose every reader is canned — no network in the test.
  DailySnapshot fakeSnapshot() => DailySnapshot(
        clock: () => today,
        readMeals: (u, d) async => {
          'totals': {'calories': 1800.0, 'protein_g': 90.0, 'carbs_g': 200.0, 'fat_g': 60.0},
          'meals_count': 3,
        },
        readWater: (u, d) async =>
            WaterEntry(userId: u, date: d, glassesConsumed: 5, targetMl: 2000),
        readSteps: (u, d) async =>
            StepEntry(userId: u, date: d, steps: 8000, goal: 10000),
        readSleep: (u, d) async => null,
        readExercise: (u, d) async => const [],
        readWeight: (u, d) async => null,
        readSupplements: (u, d) async => const {},
      );

  testWidgets('renders tracker cards from an injected DailySnapshot', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TodayReportScreen(
        userProfile: testProfile(),
        dailySnapshot: fakeSnapshot(),
      ),
    ));

    // Let initState -> _loadTodayData -> forDay resolve.
    await tester.pumpAndSettle();

    // Cards for each tracker rendered (the day loaded, not the spinner).
    expect(find.text('Meals'), findsWidgets);
    expect(find.text('Water'), findsWidgets);
    expect(find.text('Steps'), findsWidgets);

    // Injected values flowed through to the UI.
    expect(find.textContaining('8000'), findsWidgets); // steps
    expect(find.textContaining('5/8'), findsWidgets);   // water: 5 of 8 glasses
  });

  testWidgets('a failing reader degrades only its own card', (tester) async {
    // Water reader throws; everything else is fine. The screen should still
    // render (Steps present), water falling back to its empty state.
    final module = DailySnapshot(
      clock: () => today,
      readMeals: (u, d) async => {'totals': {'calories': 0.0}, 'meals_count': 0},
      readWater: (u, d) async => throw Exception('water API down'),
      readSteps: (u, d) async => StepEntry(userId: u, date: d, steps: 8000, goal: 10000),
      readSleep: (u, d) async => null,
      readExercise: (u, d) async => const [],
      readWeight: (u, d) async => null,
      readSupplements: (u, d) async => const {},
    );

    await tester.pumpWidget(MaterialApp(
      home: TodayReportScreen(userProfile: testProfile(), dailySnapshot: module),
    ));
    await tester.pumpAndSettle();

    // The screen rendered despite the water failure; neighbours are intact.
    expect(find.text('Steps'), findsWidgets);
    expect(find.textContaining('8000'), findsWidgets);
    expect(find.text('Water'), findsWidgets); // still shown, in its empty state
  });
}
