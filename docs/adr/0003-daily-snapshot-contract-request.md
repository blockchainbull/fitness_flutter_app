# 3. DaySnapshot contract-request (frontend → backend handoff)

Date: 2026-09-06
Status: Accepted (frontend); Proposed (backend — not yet built)

## Context

`DailySnapshot.forDay` ([[0002-daily-snapshot-module]]) ships now over the existing
per-tracker endpoints via parallel fan-out. Its interface is a shield: when the backend
can serve the whole day in one call, `forDay` swaps its internals with no change to
callers. This ADR **freezes the shape** the frontend wants, so the backend track designs
to it by construction rather than by luck.

**This is the authoritative source for that shape.** The backend repo carries a mirror
(`docs/contracts/daily-snapshot-endpoint.md`) that must not diverge from this file.

## The critical distinction

This endpoint returns the **owner's complete day** — every entry, regardless of its
`sharedWithChat` flag — because the owner sees and edits all their own data.

It is **not** the same read as the backend's `get_shared_activities_for_date`
(candidate #1), which returns only the *shared* subset for the AI coach. Two different
reads; they must not be conflated on the backend.

## Requested endpoint

```
GET /daily-snapshot/{user_id}/{date}      # date = YYYY-MM-DD in the user's timezone
```

Response (each section independently omittable; a missing section ⇒ the client marks it
`missing`, a 5xx/partial-failure marker per section ⇒ `error`):

```jsonc
{
  "user_id": "...",
  "date": "2026-09-06",
  "meals":       { "totals": { "calories": 0, "protein_g": 0, "carbs_g": 0, "fat_g": 0 },
                   "count": 0, "entries": [ /* meal rows */ ] },
  "water":       { /* daily_water row */ },
  "steps":       { /* daily_steps row */ },
  "sleep":       { /* sleep row */ },
  "exercise":    { "entries": [ /* exercise rows */ ],
                   "total_minutes": 0, "total_calories_burned": 0 },
  "weight":      { /* weight row */ },
  "supplements": { "items": [ { "name": "...", "taken": false } ],
                   "taken_count": 0, "total_count": 0 }
}
```

Row shapes are the existing per-tracker entry payloads unchanged (client already maps
them via `WaterEntry.fromMap`, `StepEntry.fromMap`, etc.), including each row's
`shared_with_chat` field.

## Backend acceptance (for when the backend track picks this up)

- One round-trip returns the full owner day for a date; per-section failures are isolated
  (a broken tracker read must not fail the whole response).
- Reuses the store reads that candidate #2's daily-metric store will expose; pairs with
  candidate #4's `log_daily_metric` use-case for the write side.
- Additive: does not change or replace the existing per-tracker endpoints while the client
  migrates.

## Consequences

- Frontend needs no backend change to ship F1; this is a later optimization behind the
  seam (6 dashboard calls → 1).
- The backend #1 (shared read) and this (full-owner read) share plumbing but are distinct
  interfaces — record both in the backend `CONTEXT.md`.
