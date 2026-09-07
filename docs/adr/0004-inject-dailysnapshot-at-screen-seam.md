# 4. Inject DailySnapshot at the screen seam

Date: 2026-09-07
Status: Accepted

## Context

F1 gave the client a `DailySnapshot` read model, but the screens that use it still
construct it internally (`final _dailySnapshot = DailySnapshot()`), so there is no seam
to test them through — and the repo has no widget tests at all. F3 establishes that seam.

Two facts shaped the scope:

- **`today_report_screen`** is a clean `DailySnapshot` consumer: its `initState` is just
  `_loadTodayData()`, which fans out through `forDay`. Inject the read model and the whole
  screen is widget-testable.
- **`dashboard_home` is not a consumer.** Its `todayProgress`/`_loadTodayProgress` path was
  dead (write-only, rendered by nothing); it was removed as an F1 follow-up. The dashboard's
  visible day widgets (`DailyGoalsCard`, the compact trackers) each self-fetch and are out
  of F3's scope.

## Decision

- **Mechanism: constructor param with a default.** `TodayReportScreen` takes an optional
  `DailySnapshot? dailySnapshot`; the State uses `widget.dailySnapshot ?? DailySnapshot()`.
  Production call sites (`activity_drawer.dart`) are unchanged; tests pass a fake directly.
  Chosen over `provider` (already in the app) because the seam is then explicit in the
  widget's own interface, with no `BuildContext` lookup or app-wide wiring, and over a
  service locator (not present).
- **Per-screen instance.** No shared singleton — the default stays `?? DailySnapshot()`.
  Tests inject their own instance, so production sharing is irrelevant, and a singleton
  would add global state that hurts test isolation.
- **Scope: `today_report_screen` only, `DailySnapshot` only.** Not the ~36 scattered
  `XxxApi()` constructions, not the dashboard's outbound-effect services (FCM,
  notifications). Prove the seam and the widget-test pattern here; generalize when a third
  screen needs a test.
- **The fake is a real `DailySnapshot` with canned readers.** F1's injected-reader
  constructor already is the fake seam — no separate Fake class. A widget test builds
  `DailySnapshot(readWater: (u,d) async => ..., clock: ...)` and passes it in.

## Consequences

- `today_report_screen` gains a real end-to-end widget test: inject a snapshot with canned
  readers, pump, assert the tracker cards render the expected values. The repo's first
  widget test.
- The pattern is copy-paste for the next screen that earns a test; the broader `Api()`
  cleanup remains separate, later work.
- The dashboard is explicitly not part of this seam (see the F1 follow-up that removed its
  dead progress path).
