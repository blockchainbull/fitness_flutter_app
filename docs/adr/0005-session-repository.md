# ADR-0005: Give the session one home; retire DataManager

- **Status:** Accepted
- **Date:** 2026-09-07
- **Supersedes in part:** [ADR-0001](0001-collapse-repository-seam.md) (extends its offline rule to weight and onboarding)
- **Builds on:** [ADR-0002](0002-daily-snapshot-module.md), [ADR-0004](0004-inject-dailysnapshot-at-screen-seam.md), [ADR-0006](0006-migrate-dailysnapshot-onto-the-endpoint.md)

## Context

`lib/data/services/data_manager.dart` was an 844-line eager singleton holding profile
save/load, onboarding, login/logout, a SharedPreferences cache, weight writes, connectivity
checks and exercise storage. It was the last of the four frontend deepening candidates.

Measuring it before designing anything changed what the work is:

**Only 9 of its 22 public methods had callers.** The 13 dead ones — `initialize`,
`saveUserProfile`, `getUserProfileById`, `setStartingWeight`, `getLatestWeight`,
`isOnboardingCompleted`, `synchronizeData`, `saveExercises`, `loadExercises`, `addExercise`,
`clearData`, `clearWeightData`, `hasValidLogin` — were ~285 lines, a third of the file.
`getUserProfileById` and `saveUserProfile` were pure passthroughs; the internal calls that
look like theirs all target `_apiService.*`.

**The 9 live methods formed two clusters with no overlap in callers.** A session/profile
cluster (`loadUserProfile`, `updateUserProfile`, `completeOnboarding`, `login`, `logout`)
used only by `UserProvider`; and a weight cluster (`getWeightHistory`, `saveWeightEntry`,
`updateUserWeight`, `deleteWeightEntry`) used only by three weight UI files.

**The weight cluster was a duplicate path.** `WeightApi` already exposes the same methods
under the same names. `DataManager` wrapped it with connectivity checks, `kIsWeb` branches
whose two arms were byte-identical, and a local fallback.

ADR-0006 has since moved `DailySnapshot` onto the single daily-snapshot endpoint, so it no
longer reads `WeightApi` at all — which leaves `data_manager.dart` as that class's only
importer. That does not change the decision: the weight screens need history *across* days,
which a single-day endpoint does not serve, so `WeightApi` remains the right transport and
`DataManager`'s wrapper remains the redundant layer. After this change `WeightApi`'s
importers are the three weight UI files.

**The session concern had three overlapping owners of the same four keys.** `UserManager`
declared `user_id`, `user_profile`, `is_logged_in`, `onboarding_completed`; `DataManager`
redeclared the same key strings and wrote them directly; `UserProvider` called both, with
the invariant "a cached profile implies `is_logged_in`" upheld only by every call site
remembering to pair two calls.

So this is not "split a god object". It is a deletion, a collapse, and one new deep module.

## Decision

### 1. Delete the dead surface

The 13 unused methods go, along with `ExerciseDataService` (237 lines), which was reachable
only through three of them. The live exercise path is `ExerciseApi`, used by `DailySnapshot`
and the exercise screens; `ExerciseDataService` was a second, fully dead local store —
nothing live wrote its keys and nothing live read them. `UserManager.hasCompletedOnboarding`
had zero callers and goes with its class.

### 2. Collapse the weight half into `WeightApi`

The three weight call sites take `WeightApi` directly, constructor-injected per ADR-0004.
`DataManager`'s weight methods and its local weight cache are deleted.

`updateUserWeight` is the one method that genuinely straddled both clusters: it wrote the
new weight into the cached `UserProfile` *and* called `WeightApi`, swallowing every error so
neither half could report failure. It is split at its single call site into two explicit
steps — write the weight, then refresh the cached profile.

### 3. `SessionRepository` becomes the one owner of the session

A new `lib/data/repositories/session_repository.dart` absorbs both `DataManager`'s session
half and all of `UserManager`. Both are deleted, and `lib/data/managers/` with them.

It is the third deep module of the shape ADR-0001 blessed for `StepRepository` and
`SleepRepository`: one class hiding an Api plus SharedPreferences, in the same directory.
Following ADR-0002's style, collaborators are injected as normalized function typedefs with
optional named parameters defaulting to the real calls — not as `Api` objects. Consistent
with ADR-0001's finding that `setMockInitialValues` is sufficient, SharedPreferences is
**not** abstracted behind an interface; adding a seam there would be depth for its own sake.

The class is stateless and freely constructible, so it is neither static nor a singleton.

Its write contract makes the key invariant structural rather than remembered:

| Operation | Writes |
|---|---|
| `startSession(profile)` | `user_id`, `user_profile`, `is_logged_in` |
| `cacheProfile(profile)` | `user_id`, `user_profile` |
| `endSession()` | removes the three session keys, touches nothing else |

`login` returns a `UserProfile` and throws on failure, replacing a `Map<String, dynamic>`
that reported failure two ways: the method caught its own `throw` and returned
`{'success': false, ...}`, so callers had to check the flag *and* guard the call. One way to
fail is enough, and `UserProvider` funnels everything into a single `String? _error` anyway.
The 60-second timeout and its cold-start wording are carried over deliberately: the backend
spins down when idle, so a first request after a quiet period can take 30–50s.

`UserProvider` takes an optional `SessionRepository` constructor parameter per ADR-0004.

## Behaviour changes

Three, all deliberate. Each removes a half-built capability that silently corrupted data
rather than failing.

**1. Weight no longer falls back to local storage.** The old path saved offline weight
entries to SharedPreferences under a fabricated ID that nothing ever uploaded —
`synchronizeData`, the only candidate syncer, was dead and only ever handled the profile.
Reads returned the local list *instead of* the remote one on API failure rather than merging,
so a recovered API made the offline entry vanish permanently; offline deletes logged
`'Offline delete not implemented yet'` and did nothing. ADR-0001 already ruled that offline
write is supported only where a real offline *producer* exists (steps, sleep). Weight has
none — a human types it. API failures now surface instead of showing a stale local list.

**2. Logout no longer wipes unrelated local state.** `DataManager.logout()` was
`prefs.clear()`. Since `UserProvider.logout()` called it, that was the app's real logout, and
it destroyed `theme_mode` (the dark-mode setting reset on every logout), `last_known_steps`
(the step-accrual baseline ADR-0001 went out of its way to protect), `exercise_data`, the
chat cache, notification state and supplement preferences. The dead `clearData()` had been
written to preserve supplement prefs — the careful version existed and was never wired up
while the destructive one stayed live. `endSession()` now clears the three session keys only.

This applies to **logout**. Account deletion in `settings_page.dart` keeps its explicit
`prefs.clear()`: there, wiping all local state is correct, because the account is gone.

**3. Onboarding requires connectivity.** The offline branch of `completeOnboarding`
fabricated a timestamp as the user ID and built a profile from a stub map that mapped only
`id`, `name` and `email` — the source carried a literal `// ... map other fields from
onboardingData` — discarding every other onboarding answer, then marked the user logged in
and onboarded. The result was a local-only ID matching no backend row, so every later API
call carried a phantom ID, and `synchronizeData` (dead) held the only code that would have
created the remote row. Onboarding now refuses offline and says so, exactly as `login`
already did twenty lines away. Refusing is strictly better than handing someone an
unrecoverable account.

`onboarding_completed` is no longer written. Its only three readers were all in the dead set,
so nothing live read it.

## Consequences

- `DataManager`, `UserManager` and `ExerciseDataService` are deleted; ~1,300 lines go.
- "Who is logged in" has one home, with the profile/session-flag invariant enforced by the
  store rather than by convention at each call site.
- `UserProvider` — which owns login, logout, onboarding and profile for the whole app — gets
  its first tests, as does the session logic itself.
- Weight has one path, matching what `DailySnapshot` already did.
- Real offline support for weight ([#7](https://github.com/ShoaibRana888/nufi_app/issues/7))
  and for onboarding replay
  ([#8](https://github.com/ShoaibRana888/nufi_app/issues/8)) is explicitly out of scope.
  Both are features with genuine design work (replay, conflict handling, partial payloads),
  not refactors, and if built they should share one replay mechanism rather than two.
- Not addressed here: the repo's `print`-based logging and its `avoid_print` lints.
  Introducing a logging framework is a separate decision and should not hide inside this one.
