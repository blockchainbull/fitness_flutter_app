# Context — nufi_app (Flutter client)

The domain glossary for the nufi health-tracking app. When code, an issue title, a
refactor, or a test names a domain concept, use the term as defined here — don't drift
to a synonym. If a concept you need isn't here, that's a signal: either you're inventing
language the project doesn't use, or there's a real gap worth adding.

The client is a thin front-end over a FastAPI backend (a separate repo). It owns
presentation, local caching, and notifications; the backend owns persistence and the AI.

## Core nouns

- **User** — an onboarded person. Identified by a `userId`; their `UserProfile` holds
  age, goals, and per-domain preferences captured during **onboarding**.
- **Tracker** — one health domain the user logs against. The eight trackers are:
  **meal, water, steps, sleep, exercise, supplement, period, weight**. Each has its own
  logging screen, history screen, and (mostly) a dashboard card.
- **Entry** — a single logged record for one tracker on one date (e.g. `WaterEntry`,
  `SleepEntry`). Most trackers are one-entry-per-day (upsert by date); meals and
  exercises can have several per day. "Log" (verb) = create or update an entry.
- **Daily Snapshot** *(emerging term)* — a user's assembled data across all trackers for
  a single date. It has no module yet: `MetricsService.getTodayMetrics` builds a partial
  one, and `today_report_screen`, `dashboard_home`, and the chat context each re-assemble
  it independently. The architecture work (candidate #1) gives this concept one home:
  `DailySnapshot.forDay(userId, date)`. Prefer **Daily Snapshot** over "metrics",
  "today's data", or "summary" for this concept going forward.
- **Coach** — the AI chat assistant (user-facing name is "coach"; code says `chat` /
  `ChatApi`). The coach answers using **chat context** built from the user's shared data.
- **Chat context** — the digest of a user's recent tracker data (daily and weekly) that
  is fed to the coach. Assembled backend-side; the client reads and displays it.
- **Shared with chat** — a per-entry privacy flag (`sharedWithChat`). An entry hidden
  from the coach is excluded from chat context. User-facing labels: "Share with coach" /
  "Hide from coach".
- **Report** — a read-only rollup for a period: the **today report**
  (`today_report_screen`) and the **weekly summary** (`weekly_summary_screen`).

## Data access vocabulary (the architecture work touches this)

- **Api** — a per-tracker HTTP client under `lib/data/services/api/` (`MealApi`, …).
  This is the live seam to the backend, and the one adapter that actually runs.
- **Repository** — a `lib/data/repositories/` type (water, sleep, step, period,
  supplement, weight, user). Historically shaped for two adapters — the `Api` and a
  direct-Postgres `DatabaseService`. The Postgres adapter is dead (unusable on web,
  commented out), so most repositories are now shallow pass-throughs to their `Api`.
  Candidate #2 collapses this seam. Not every tracker has a repository — meal, exercise,
  chat, and auth call their `Api` directly.
- **DataManager** — a legacy singleton mixing profile save/load, onboarding, weight
  history, connectivity, and a local prefs cache. Candidate #4 splits it.

## Conventions

- **Emerging vs. established terms.** Terms marked *(emerging term)* name a concept the
  code re-derives in several places but hasn't yet given a module. Once the architecture
  work lands the module, drop the marker.
- Architecture vocabulary (module, interface, seam, adapter, depth, leverage, locality)
  lives in the design skill, not here. This file names the *domain*; that file names the
  *shapes*.
