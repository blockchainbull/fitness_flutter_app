import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/step_entry.dart';
import 'package:user_onboarding/data/repositories/step_repository.dart';

/// Characterization test for the one genuinely stateful behavior the F2 repository
/// collapse must preserve: steps accrue to local storage even when the network is
/// unavailable, so the pedometer's offline count is not lost before it syncs.
///
/// StepRepository.saveStepEntry attempts the API (fire-and-forget, errors caught)
/// and then always writes to SharedPreferences. This test drives that path with no
/// backend and asserts the local write, reading prefs directly so it does not depend
/// on network timing. Full network isolation (an injected StepApi) arrives with F3.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'offline-user';
  final date = DateTime(2026, 9, 6);
  // Mirror StepRepository's private key scheme so we assert the persisted contract.
  final dateKey = '${date.year}-${date.month}-${date.day}';
  final prefsKey = 'step_entries_${userId}_$dateKey';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveStepEntry persists the entry locally when offline', () async {
    final entry = StepEntry(
      userId: userId,
      date: date,
      steps: 4200,
      goal: 10000,
      activeMinutes: 33,
      caloriesBurned: 180,
      distanceKm: 3.1,
      sourceType: 'pedometer',
    );

    // Never throws: the API attempt inside is caught, the local write always runs.
    await StepRepository.saveStepEntry(entry);

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(prefsKey);
    expect(stored, isNotNull, reason: 'offline step accrual must persist locally');

    final decoded = StepEntry.fromMap(jsonDecode(stored!));
    expect(decoded.steps, 4200);
    expect(decoded.userId, userId);
    expect(decoded.sourceType, 'pedometer');
  });

  test('getStepEntriesInRange returns locally accrued entries as a fallback', () async {
    final entry = StepEntry(
      userId: userId,
      date: date,
      steps: 4200,
      goal: 10000,
    );
    await StepRepository.saveStepEntry(entry);

    // API returns nothing offline, so the range read falls back to local storage.
    final entries = await StepRepository.getStepEntriesInRange(userId, date, date);
    expect(entries.length, 1);
    expect(entries.first.steps, 4200);
  });
}
