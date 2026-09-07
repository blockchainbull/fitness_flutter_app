import 'package:flutter_test/flutter_test.dart';
import 'package:user_onboarding/data/models/step_entry.dart';

/// StepEntry.fromMap against rows with absent or null numeric columns.
///
/// Three fields applied their default inside an `is int` guard but not in the
/// branch that produced the value:
///
///   steps: (map['steps'] ?? 0) is int ? map['steps'] : ...
///
/// An absent or null column tested as `0 is int` — true — and then assigned
/// `map['steps']`, which is null, to a non-nullable int. fromMap threw.
///
/// It was reachable from the live step read: the backend returns the raw
/// daily_steps row, so any nullable column that is actually null hit it.
/// StepRepository.getStepEntryByDate catches the throw and falls back to local
/// storage, which is why it degraded quietly instead of crashing. The
/// daily-snapshot migration routes the same rows through the same parser, so
/// it is pinned here rather than left to be rediscovered.
void main() {
  Map<String, dynamic> row(Map<String, dynamic> extra) => {
        'id': 's1',
        'user_id': 'u1',
        'date': '2026-09-06',
        ...extra,
      };

  test('an absent numeric column falls back to its default', () {
    final entry = StepEntry.fromMap(row({'steps': 8000}));

    expect(entry.steps, 8000);
    expect(entry.goal, 10000); // documented default
    expect(entry.activeMinutes, 0);
  });

  test('an explicitly null numeric column falls back too', () {
    final entry = StepEntry.fromMap(row({
      'steps': null,
      'goal': null,
      'active_minutes': null,
    }));

    expect(entry.steps, 0);
    expect(entry.goal, 10000);
    expect(entry.activeMinutes, 0);
  });

  test('numerics arriving as strings still parse', () {
    // PostgREST hands back some numeric columns as strings.
    final entry = StepEntry.fromMap(row({
      'steps': '8000',
      'goal': '12000',
      'active_minutes': '45',
    }));

    expect(entry.steps, 8000);
    expect(entry.goal, 12000);
    expect(entry.activeMinutes, 45);
  });

  test('an unparseable string falls back rather than throwing', () {
    final entry = StepEntry.fromMap(row({'steps': 'not-a-number'}));

    expect(entry.steps, 0);
  });

  test('the camelCase spellings are still accepted', () {
    final entry = StepEntry.fromMap(row({'steps': 500, 'activeMinutes': 12}));

    expect(entry.activeMinutes, 12);
  });
}
