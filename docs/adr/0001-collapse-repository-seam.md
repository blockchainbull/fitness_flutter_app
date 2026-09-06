# 1. Collapse the repository seam; delete the dead Postgres adapter

Date: 2026-09-06
Status: Accepted

## Context

The data layer carried two adapters behind a `Repository` seam: the HTTP `Api` clients
and a direct-Postgres `DatabaseService`. Investigation found:

- `DatabaseService.initialize()` is **never called anywhere**, so `isInitialized` is
  always `false` and every `if (DatabaseService.isInitialized)` fallback branch (8 sites)
  is unreachable on **all** platforms. The Postgres adapter is dead code, and it ships DB
  credentials in `.env` plus the `postgres`/`dotenv` dependencies.
- `user_repository.dart` (571 lines) has **zero importers**.
- A **`SharedPreferences`** local store, separate from the dead Postgres path, is alive
  and load-bearing in exactly two trackers: `step_repository` (the pedometer in
  `step_counter_service` accrues steps offline and syncs later — API-first read, local
  sync source) and `sleep_repository` (local-first save, then push).
- The other trackers (water, weight, period, supplement; meal/exercise never had a
  repository) have no working local store — their only live adapter is the `Api`.

"One adapter means a hypothetical seam; two means a real one." The repository seam is real
only for steps and sleep.

## Decision

1. **Delete the dead Postgres layer entirely**: `DatabaseService`, `user_repository.dart`,
   all `isInitialized` fallback branches, the `postgres` + `dotenv` dependencies, and the
   DB credentials from `.env` / `.env.example`.
2. **Collapse** the water, weight, period, and supplement repositories into their `Api`
   clients: the `Api` returns typed entries (not raw maps) and owns id-generation; the
   repository files are deleted and callers point at the `Api` directly. Thin transform
   logic moves *down* into the `Api`, never *up* into screens.
3. **Keep `StepRepository` and `SleepRepository` as deep modules** hiding the `Api`+local
   composition behind a small interface. Strip their dead `DatabaseService` branches;
   preserve each tracker's current offline policy as-is (steps API-first/local-sync,
   sleep local-first). Do **not** build a generic `LocalStore<T>` for two callers — that
   is a hypothetical seam at the abstraction level.
4. The read-surface asymmetry this leaves (steps/sleep via `Repository`, the rest via
   `Api`) is **not** resolved here. It disappears in the `DailySnapshot` module (F1),
   which gives every tracker one uniform read regardless of the adapter behind it.

## Consequences

- Removes a leaked-credentials liability and ~350+ lines of dead/commented code.
- The `Api` becomes the single deep adapter for the collapsed trackers; screens stop
  seeing raw maps.
- Steps' offline accrual→sync is the one genuinely stateful behavior that a careless edit
  could regress.
- **Verification** (F2 lands before F3, so no injectable test surface yet): `flutter
  analyze` clean + web **and** mobile builds succeed + manual smoke of the collapsed
  trackers and sleep; **plus one characterization test** around steps' offline accrual→
  sync before collapsing.
- Offline write remains supported only where a real offline *producer* exists (steps,
  sleep). Making other trackers offline-capable is explicitly out of scope (YAGNI) until a
  product goal demands it.
