import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/session_repository.dart';
import 'package:user_onboarding/providers/user_provider.dart';

/// UserProvider over an injected SessionRepository — no network.
///
/// The provider owns login, logout, onboarding and the profile for the whole
/// app and had no test surface before ADR-0005 gave it a seam. The fake is a
/// real SessionRepository with canned readers, so these exercise the production
/// path rather than a stand-in for it.
void main() {
  UserProfile profile({String id = 'u1'}) => UserProfile(
        id: id,
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

  SessionRepository session({LoginCaller? login, bool connected = true}) =>
      SessionRepository(
        login: login ?? (e, p) async => {'success': true, 'user': {'id': 'u1'}},
        fetchProfile: (id) async => profile(id: id),
        pushProfile: (p) async => p,
        submitOnboarding: (d) async => {'success': true, 'userId': 'u1'},
        isConnected: () async => connected,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('login populates the profile and leaves no error', () async {
    final provider = UserProvider(session: session());

    final ok = await provider.login('t@example.com', 'pw');

    expect(ok, true);
    expect(provider.userProfile?.id, 'u1');
    expect(provider.isLoggedIn, true);
    expect(provider.error, isNull);
    expect(provider.isLoading, false);
  });

  test('a failed login reports the reason and signs nobody in', () async {
    final provider = UserProvider(
      session: session(
        login: (e, p) async => {'success': false, 'message': 'Invalid password'},
      ),
    );

    final ok = await provider.login('t@example.com', 'wrong');

    expect(ok, false);
    expect(provider.userProfile, isNull);
    expect(provider.isLoggedIn, false);
    expect(provider.error, contains('Invalid password'));
    expect(provider.isLoading, false);
  });

  test('a blip on the profile read still signs the user in', () async {
    // The provider finishes what login could not: the session is real, so it
    // loads the profile rather than reporting a failed login.
    var attempt = 0;
    final provider = UserProvider(
      session: SessionRepository(
        login: (e, p) async => {'success': true, 'user': {'id': 'u1'}},
        fetchProfile: (id) async {
          if (attempt++ == 0) throw Exception('transient');
          return profile(id: id);
        },
        pushProfile: (p) async => p,
        submitOnboarding: (d) async => {'success': true, 'userId': 'u1'},
        isConnected: () async => true,
      ),
    );

    final ok = await provider.login('t@example.com', 'pw');

    expect(ok, true);
    expect(provider.error, isNull);
    expect(provider.userProfile?.id, 'u1');
  });

  test('logout clears the profile and the error', () async {
    final provider = UserProvider(session: session());
    await provider.login('t@example.com', 'pw');
    expect(provider.isLoggedIn, true);

    await provider.logout();

    expect(provider.userProfile, isNull);
    expect(provider.isLoggedIn, false);
    expect(provider.error, isNull);
  });

  test('initUser restores a signed-in user and skips a signed-out one', () async {
    final repo = session();
    await repo.startSession('u1', profile: profile());

    final restored = UserProvider(session: repo);
    await restored.initUser();
    expect(restored.userProfile?.id, 'u1');

    await repo.endSession();
    final fresh = UserProvider(session: repo);
    await fresh.initUser();
    expect(fresh.userProfile, isNull);
  });
}
