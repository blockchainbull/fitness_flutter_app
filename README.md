# Nufitionist

**Cross-platform AI health & fitness coach — one Flutter codebase, running on Web, Android, and iOS.**

[![Live Demo](https://img.shields.io/badge/demo-live-02569B?style=for-the-badge&logo=flutter)](https://fitness-flutter-app.vercel.app/)

[View Live Site (Web)](https://fitness-flutter-app.vercel.app/) · Backend repo: [nufi-ai-backend](https://github.com/ShoaibRana888/nufi-ai-backend)

| | |
|---|---|
| **Onboarding** (collage — sleep, workout, weight-goal steps) | ![Onboarding](./screenshots/onboarding.png) |
| **Dashboard** (collage) | ![Dashboard](./screenshots/dashboard.png) |
| **Weekly summary** | ![Weekly summary](./screenshots/weekly-summary.png) |
| **Smart meal logging — input** | ![Meal logging input](./screenshots/meal-input.png) |
| **Smart meal logging — AI analysis** | ![Meal logging analysis](./screenshots/meal-analysis.png) |
| **Period tracker** | ![Period tracker](./screenshots/period-tracker.png) |
| **AI coach chat** | ![AI coach chat](./screenshots/coach-chat.png) |

## Overview

Nufitionist is a health and fitness coaching app built with Flutter from a single codebase across Web, Android, and iOS. After a multi-step onboarding flow that collects goals, sleep patterns, dietary preferences, medical conditions, and workout preferences, users get an integrated ChatGPT-powered coach for personalized guidance. Native mobile builds are currently in testing ahead of an App Store / Google Play release.

## Features

- Multi-step onboarding covering goals, sleep, diet, medical conditions, and workout preferences
- ChatGPT-powered AI coach for personalized guidance
- Offline-first: data is cached locally and synced to the backend when online
- Connectivity monitoring with manual sync from the profile screen
- Customizable user profiles and fitness-tracking widgets

## Tech stack

- **Framework:** Flutter / Dart (single codebase → Web, Android, iOS, and desktop targets)
- **Backend:** [nufi-ai-backend](https://github.com/ShoaibRana888/nufi-ai-backend) — FastAPI + Supabase + OpenAI
- **Local storage:** SharedPreferences (offline support)

## Contact

**Shoaib Rana** — [shoaib.rana888@gmail.com](mailto:shoaib.rana888@gmail.com) · [Portfolio](https://portfolio-pied-two-34.vercel.app/) · [GitHub](https://github.com/ShoaibRana888)
