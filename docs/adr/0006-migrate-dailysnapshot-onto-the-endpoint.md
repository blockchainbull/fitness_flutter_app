# 6. Migrate `DailySnapshot.forDay` onto the daily-snapshot endpoint

Date: 2026-09-07
Status: Accepted

## Context

[ADR-0002](0002-daily-snapshot-module.md) built `DailySnapshot` as a deep module
over a seven-way parallel fan-out, and said its interface was a shield: when the
backend could serve a whole day in one call, `forDay` would swap its internals with
no change to callers. [ADR-0003](0003-daily-snapshot-contract-request.md) froze the
shape. The backend has now built it, and this is that swap — the interface held, so
`today_report_screen` is untouched.

Checking the ground before writing anything turned up three things.

**`forDay` has one caller, not two.** The dashboard was wired to it in F1 part 2a and
removed again in `e918b74`: `todayProgress` was a write-only map that no visible
widget rendered, so the dashboard had been feeding a dead path since before F1. The
dashboard's visible widgets each self-fetch and are a separate question. So this
migration serves `today_report_screen` alone.

**The endpoint is live.** Checked against the deployed backend's `openapi.json`
rather than assumed from a merged PR — `/api/health/daily-snapshot/{user_id}/{date}`
is present, and a request for a day with nothing logged returns the contract shape
exactly (roll-ups zeroed, single-row sections omitted, `_read_errors` empty).

**Steps were not just an Api call.** `StepRepository.getStepEntryByDate` tries the
network and falls back to on-device storage, because the pedometer accrues locally
and syncs later. Six of the seven readers were plain Api calls; that one carried
behaviour worth keeping.

## Decision

1. **One reader replaces seven.** `DailySnapshot` takes a `DayReader` — the whole
   day as one document — instead of seven per-tracker readers. `DailySnapshotApi`
   owns the request and nothing else; interpreting sections is the module's job.
2. **Map the contract's three states onto `SectionStatus` directly.** Present ⇒
   `ok`, absent ⇒ `missing`, absent and named in `_read_errors` ⇒ `error`. The
   backend chose that spelling to match this enum, and the addenda on ADR-0003
   record it.
3. **A failed day read marks every section `error`, never `missing`.** One request
   replacing seven means a total failure has to be distinguishable from a day with
   nothing logged; collapsing them would render an empty report as if it were real.
4. **Each section parses inside its own `try`.** The backend isolates its reads; the
   client isolates its parsing. A malformed row fails its own section and no other.
5. **Keep the on-device steps fallback, as an explicit seam.** When the day read
   cannot supply steps — the request failed, or the section is missing or errored —
   `DailySnapshot` asks local storage. It never overrides a value the backend did
   supply, and when there is nothing stored it leaves the section as it was, so
   "offline" cannot masquerade as "you walked nothing today". This is the one piece
   of behaviour the old fan-out had that a single call would otherwise have dropped.
6. **No fallback to the old fan-out.** Keeping it would double the read paths and
   hide failures behind a slow retry. If the network is down, all seven calls would
   have failed too; the case the fan-out genuinely handled better — one tracker
   broken — is exactly what `_read_errors` now covers.

## Consequences

- **Seven HTTP requests become one** on every today-report load and revalidation.
  One of the seven was `GET /weight/{u}?limit=50` — the user's *entire* weight
  history, scanned client-side for a matching day — so the saving is larger than the
  call count suggests.
- **`MealsDay.entries` is populated for the first time.** `_mealsSection` read
  `data['meals'] as List`, but `MealApi.getDailySummary` normalises its response to
  `{totals, meals_count}` and never emits a `meals` key, so the list was *always*
  empty regardless of what the backend returned. The snapshot carries the rows.
- **`WeightEntry.sharedWithChat` is correct for the first time.** `fromMap` defaults
  an absent flag to `true`, and the backend's weight projection used to drop the
  column, so every weight entry read as shared. The backend widened the projection;
  a test pins it here.
- **Fixed a live parser bug found by writing the tests.** `StepEntry.fromMap`
  applied its default inside an `is int` guard but not in the branch producing the
  value, for `steps`, `goal` and `active_minutes`: an absent or null column tested as
  `0 is int` — true — and then assigned `null` to a non-nullable `int`, throwing.
  It was reachable from the live step read, which returns the raw `daily_steps` row;
  `StepRepository` catches the throw and falls back to local storage, which is why it
  degraded quietly rather than crashing. Pinned by `test/step_entry_parsing_test.dart`,
  verified to fail against the old parser.
- The test suite goes from 85 tests to 103. The six pre-existing failures are
  unchanged and unrelated — network-dependent integration tests in `auth_test`,
  `existing_user_test` and `supplements_period_tracking_test`. Compared by name
  before and after rather than by count.
- `test/daily_snapshot_test.dart` now drives the module with a **document in the
  shape the endpoint actually returns**, so it doubles as a check on the contract.
- **Deliberately not done:** the dashboard's compact trackers still self-fetch, one
  call each. Pointing them at `DailySnapshot` is the larger remaining win and its own
  decision — it changes several widgets' data sources, which is not this swap.
