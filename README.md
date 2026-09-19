# Planly AI

Planly AI is a Flutter prototype for an AI-powered interior design workflow. It guides users from account sign-in through floor-plan upload, AI processing, room analysis, and final layout recommendations.

> This project is currently a front-end demo. The AI pipeline and backend are mocked with UI-driven flows and sample data rather than live AI services or persisted user data.

## Overview

The app is designed around a realistic interior-design journey:

1. A user lands on a polished welcome screen.
2. They sign in or create an account.
3. They upload a floor plan or blueprint.
4. The app simulates AI analysis and room detection.
5. They review suggested rooms and choose the best fit.
6. The app presents ranked layout options with style tags and scores.
7. Admins can review user accounts and approve or reject them.

## Features

- Welcome screen with product messaging and onboarding CTA
- Sign in / sign up flow with validation and password visibility toggle
- Dashboard with project overview, recent work, and navigation
- Floor-plan upload screen with drag-and-drop style UI
- AI processing screen with animated progress states
- Room detection and selection experience for detected spaces
- Layout recommendation gallery with ranking and style metadata
- Profile screen and admin account management tools
- Dark-themed modern UI built in Flutter

## App flow

The main user journey is implemented through a set of screen modules in the app entry file:

- `WelcomeScreen` – landing experience
- `AuthScreen` – sign in / sign up
- `DashboardScreen` – home dashboard
- `UploadScreen` – floor-plan upload
- `ProcessingScreen` – mock AI analysis state
- `RoomSelectionScreen` – detected room review
- `LayoutsScreen` – ranked design options
- `AdminAccountsScreen` – admin moderation
- `ProfileScreen` – user profile view

## Project structure

The application is organized as a single entry file with `part` files under `lib/`.

| File | Purpose |
| --- | --- |
| `lib/main.dart` | App entry point, theme, and part declarations |
| `lib/auth.dart` | Authentication screens |
| `lib/dashboard.dart` | Dashboard and navigation |
| `lib/upload.dart` | Floor-plan upload workflow |
| `lib/processing.dart` | Mock processing / analysis animation |
| `lib/room_selection.dart` | Room detection and selection UI |
| `lib/layouts.dart` | Layout recommendations |
| `lib/admin_accounts.dart` | Admin account controls |
| `lib/profile.dart` | User profile screen |
| `lib/welcome.dart` | Intro / welcome screen |

## Getting started

Requirements:

- Flutter SDK
- Dart SDK `^3.10.4`

Install dependencies and run the app:

```bash
flutter pub get
flutter run
```

To verify the project still passes analysis and tests:

```bash
flutter analyze
flutter test
```

## Supported platforms

This Flutter app is configured for cross-platform development, including:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

Run a specific target with:

```bash
flutter run -d <device>
```

## Notes

- The app is intended as a product prototype and UX mockup.
- No real AI backend, database, or authentication service is connected yet.
- Future work can include real image processing, backend APIs, persistent user data, and production-ready validation.
