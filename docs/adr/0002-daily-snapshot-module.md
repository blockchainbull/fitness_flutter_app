# 2. DailySnapshot — a deep module for a user's day

Date: 2026-09-06
Status: Accepted

## Context

"A user's data for a given day" had no module. It was re-derived in `today_report_screen`
(8 separate data doors), `dashboard_home`, and — separately, server-side — the chat
context. `MetricsService.getTodayMetrics` was a partial, today-only, scalar version.

F1 gives the concept one home. Scope clarification from grilling: `DailySnapshot` is a
**client-side read model** for the dashboard and the today report. The chat context is
backend-owned and builds from the *shared* subset of entries — it is **not** a consumer of
`DailySnapshot`. See [[0003-daily-snapshot-contract-request]] for the backend handoff.

## Decision

- **One rich model, callers project.** `DailySnapshot.forDay(userId, date)` returns one
  `DaySnapshot` with typed per-tracker sections. The dashboard projects down to its 5
  scalars; the report reads the full sections. Do not split into summary/detail methods.
- **Per-section load-state.** Each section is independently `ok | missing | error`. One
  failed tracker never blanks the day — this preserves today's resilience.
- **Status is a separate pure projection.** `DaySnapshot` carries *what the user logged*.
  Targets / `isComplete` are computed by a pure `dayStatus(snapshot, goals)` function — the
  client twin of the backend's emerging `health_insights` module. Testable without I/O.
- **Payload** reuses the existing entry models verbatim:
  - `meals`: `{ totals:{calories,protein_g,carbs_g,fat_g}, count, entries[] }` — carries
    both the list (report) and the rollup (dashboard).
  - `water`: `WaterEntry?` · `steps`: `StepEntry?` · `sleep`: `SleepEntry?` ·
    `weight`: `WeightEntry?`
  - `exercise`: `{ entries[], totalMinutes, totalCaloriesBurned }?`
  - `supplements`: `{ items:[{name,taken}], takenCount, totalCount }?`
  - Entries keep their `sharedWithChat` flag so the report's per-entry share/hide toggle
    keeps working. The model is the **owner's full day**, not the shared subset.
- **Parallel fan-out now.** Behind `forDay`, the per-tracker reads fan out in parallel
  (`Future.wait`, each caught independently → maps onto per-section load-state). The
  interface hides this so it can later collapse to one backend call
  ([[0003-daily-snapshot-contract-request]]) without touching callers.
- **Cache-first, today only.** The module owns a per-section cache for the *current* day:
  serve cached instantly, revalidate behind it, notify on update. Past dates read
  network-only. This serves the dashboard-load goal without an unbounded cache.
- **Invalidation via a notifier.** Writes stay on their normal `Api`/`Repository` path.
  After a successful write, the screen fires a lightweight `DayDataNotifier` signal
  (sibling of the existing `utils/profile_update_notifier.dart`) naming the changed
  (date, section); `DailySnapshot` listens and revalidates *just that section*.
  `DailySnapshot` stays a pure read model — writes do not route through it.
- **Accept data sources.** `DailySnapshot` takes its per-tracker sources (the `Api`s,
  `StepRepository`/`SleepRepository`, and the cache) via its constructor, so it is
  testable through fakes immediately and F3's injection work is a no-op for this module.

> **Correction (2026-09-06).** This ADR calls `dayStatus` "the client twin of the
> backend's emerging `health_insights` module". They are cousins, not twins. The backend
> module — now `health_trends` — answers *which way is the user moving?* over a window of
> entries and returns encoded strings (`'losing_1.5kg'`, `'no_data'`) that are on the wire
> and persisted. `dayStatus` answers *is the user at their goal today?* over a single day
> and returns structured `MetricStatus`. Same spirit (pure projection, testable without
> I/O), different question. See the backend's `docs/adr/0001-extract-health-trends.md`.

## Consequences

- Locality: day-assembly bugs concentrate in one module; leverage: one interface, two
  callers (dashboard, report). Deletion test passes — the concept was already re-derived
  three times.
- `MetricsService` is absorbed and retired; `today_report_screen`'s 8-door assembly and
  `dashboard_home`'s fetch both move behind `forDay`.
- Depends on nothing in F2, but pairs with it: after F2, steps/sleep are reached via their
  repositories and the rest via `Api` — `DailySnapshot` is exactly where that asymmetry
  becomes invisible to callers.
- Enables F3 (screens accept an injected `DailySnapshot`) and gives F4's weight-history a
  home to move into.
