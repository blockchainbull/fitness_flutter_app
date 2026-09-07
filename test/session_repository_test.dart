import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_onboarding/data/models/user_profile.dart';
import 'package:user_onboarding/data/repositories/session_repository.dart';

/// SessionRepository over injected readers and a mocked SharedPreferences —
/// no network. See docs/adr/0005-session-repository.md.
///
/// The behaviour these pin down is the reason the class exists: the session's
/// three keys have one writer, so "a cached profile implies is_logged_in" holds
/// structurally, and ending a session cannot take unrelated local state with it.
void main() {
  UserProfile profile({String id = 'u1', double weight = 60}) => UserProfile(
        id: id,
        name: 'Test',
        email: 't@example.com',
        gender: 'female',
        age: 30,
        height: 165,
        weight: weight,
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

  SessionRepository build({
    LoginCaller? login,
    ProfileFetcher? fetchProfile,
    ProfileUpdater? pushProfile,
    OnboardingSubmitter? submitOnboarding,
    bool connected = true,
  }) =>
      SessionRepository(
        login: login ?? (e, p) async => {'success': true, 'user': {'id': 'u1'}},
        fetchProfile: fetchProfile ?? (id) async => profile(id: id),
        pushProfile: pushProfile ?? (p) async => p,
        submitOnboarding: submitOnboarding ??
            (d) async => {'success': true, 'userId': 'u1'},
        isConnected: () async => connected,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('starting a session', () {
    test('login writes all three session keys together', () async {
      final result = await build().login('t@example.com', 'pw');
      final prefs = await SharedPreferences.getInstance();

      expect(result.id, 'u1');
      expect(prefs.getString(SessionRepository.userIdKey), 'u1');
      expect(prefs.getBool(SessionRepository.isLoggedInKey), true);
      expect(prefs.getString(SessionRepository.userProfileKey), isNotNull);
    });

    test('login offline throws without claiming a session', () async {
      final repo = build(connected: false);

      await expectLater(
        repo.login('t@example.com', 'pw'),
        throwsA(isA<SessionException>()),
      );
      expect(await repo.isLoggedIn(), false);
    });

    test('bad credentials throw the server message', () async {
      final repo = build(
        login: (e, p) async => {'success': false, 'message': 'Invalid password'},
      );

      await expectLater(
        repo.login('t@example.com', 'pw'),
        throwsA(isA<SessionException>().having(
          (e) => e.message,
          'message',
          'Invalid password',
        )),
      );
    });

    test('onboarding offline refuses rather than inventing an account', () async {
      final repo = build(connected: false);

      await expectLater(
        repo.completeOnboarding({'basicInfo': {'name': 'Test'}}),
        throwsA(isA<SessionException>()),
      );
      // No phantom id, no half-written session.
      expect(await repo.currentUserId(), isNull);
      expect(await repo.isLoggedIn(), false);
    });
  });

  group('reading the profile', () {
    test('loadProfile prefers the server and refreshes the cache', () async {
      final repo = build(fetchProfile: (id) async => profile(weight: 71));
      await repo.startSession(profile(weight: 60));

      final loaded = await repo.loadProfile();

      expect(loaded!.weight, 71);
      final prefs = await SharedPreferences.getInstance();
      final cached =
          jsonDecode(prefs.getString(SessionRepository.userProfileKey)!);
      expect(cached['weight'], 71);
    });

    test('loadProfile falls back to the cache when the fetch fails', () async {
      final repo = build(
        fetchProfile: (id) async => throw Exception('backend cold-starting'),
      );
      await repo.startSession(profile(weight: 60));

      final loaded = await repo.loadProfile();

      // A read cache: it returns what the server last said, never invents.
      expect(loaded, isNotNull);
      expect(loaded!.weight, 60);
    });

    test('currentProfile is null once the session ends', () async {
      final repo = build();
      await repo.startSession(profile());
      expect(await repo.currentProfile(), isNotNull);

      await repo.endSession();
      expect(await repo.currentProfile(), isNull);
    });
  });

  group('ending a session', () {
    test('endSession clears the session and leaves everything else', () async {
      final seed = await SharedPreferences.getInstance();
      await seed.setString('theme_mode', 'dark');
      await seed.setInt('last_known_steps', 4213);
      await seed.setBool('supplement_vitamin_d', true);

      final repo = build();
      await repo.startSession(profile());

      await repo.endSession();

      final prefs = await SharedPreferences.getInstance();
      // The session is gone...
      expect(prefs.getString(SessionRepository.userIdKey), isNull);
      expect(prefs.getString(SessionRepository.userProfileKey), isNull);
      expect(prefs.getBool(SessionRepository.isLoggedInKey), false);
      // ...and nothing else went with it. The predecessor was prefs.clear(),
      // which reset the theme and the step-accrual baseline on every logout.
      expect(prefs.getString('theme_mode'), 'dark');
      expect(prefs.getInt('last_known_steps'), 4213);
      expect(prefs.getBool('supplement_vitamin_d'), true);
    });
  });

  group('the write contract', () {
    test('cacheProfile refreshes the profile without asserting sign-in', () async {
      final repo = build();

      await repo.cacheProfile(profile(weight: 65));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionRepository.userProfileKey), isNotNull);
      // Updating a profile is not a claim that someone signed in.
      expect(prefs.getBool(SessionRepository.isLoggedInKey), isNull);
    });

    test('updateProfile keeps the local edit when the push fails', () async {
      final repo = build(
        pushProfile: (p) async => throw Exception('offline-ish failure'),
      );

      final updated = await repo.updateProfile(profile(weight: 68));

      expect(updated.weight, 68);
      final prefs = await SharedPreferences.getInstance();
      final cached =
          jsonDecode(prefs.getString(SessionRepository.userProfileKey)!);
      expect(cached['weight'], 68);
    });
  });
}
