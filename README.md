# Interior Design App

A Flutter app that turns a floor plan into AI-suggested interior layouts. Users sign in, upload a floor plan, pick a detected room, and browse generated layout options. Admins can review and approve user accounts.

> The AI steps (room detection, layout generation) are currently simulated with mock data and processing animations; there is no backend yet.

## Features

- **Sign in / Sign up** – auth screen with validated form fields and a Google sign-in button.
- **Dashboard** – hero banner, project grid, tips and bottom navigation.
- **Upload** – dropzone for floor plans, with example plans.
- **Processing** – animated "analysing your plan" screen.
- **Room selection** – detected rooms drawn on a floor-plan diagram, each with a suitability badge.
- **Layouts** – ranked layout options with match score, style tags and a rendered preview.
- **Admin accounts** – search, filter (pending / approved / rejected), and approve or reject user accounts.

## Project structure

All screens live in `lib/` as `part` files of [lib/main.dart](lib/main.dart), which holds the app entry point and `MyApp`.

| File | Contents |
| --- | --- |
| `main.dart` | Entry point, app theme, part directives |
| `auth.dart` | Sign-in / sign-up screen |
| `dashboard.dart` | Home dashboard |
| `upload.dart` | Floor-plan upload |
| `processing.dart` | Processing screen |
| `room_selection.dart` | Room detection results |
| `layouts.dart` | Layout suggestions |
| `admin_accounts.dart` | Admin account management |

## Getting started

Requirements: Flutter with Dart SDK `^3.10.4`.

```bash
flutter pub get
flutter run
```

Run the analyzer and tests with:

```bash
flutter analyze
flutter test
```

## Platforms

Android, iOS, web, Windows, macOS and Linux targets are supported by Flutter; run `flutter run -d <device>` to choose one.
