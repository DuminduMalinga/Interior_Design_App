# LiviSpace

*Design spaces for better living.*

LiviSpace is a Flutter prototype for an AI-powered interior design workflow. It guides a user from a splash screen through sign-up, a floor-plan upload, mock AI processing, room selection, and ranked layout recommendations they can view in 3D.



## Context for picking this up

A few things worth knowing before you dig into the code:

- **Everything is one app, edited across feature branches.** The repo uses a branch per screen or feature (`Welcome_Screen`, `Dashboard`, `Login`, `Profile`, `Room_Viewer`, `Upload_Floor_Plan`, …), each merged into `main` via PR. Because of that, a branch that's been open a while can drift a long way behind `main` — merge it in (`git merge main`) before starting new work on an old branch, rather than after, to avoid large conflicts.
- **The UI runs on a small design system**, not per-screen styling: colors, type, spacing, radii and shadows are tokens in `lib/app_theme.dart`, shared widgets (buttons, cards, chips, inputs) live in `lib/app_components.dart`, and responsive breakpoints/layout helpers live in `lib/responsive.dart`. New screens should pull from these rather than hardcoding a `Color(0x...)` or a `fontSize`.
- **Every screen is responsive** at three breakpoints — mobile (<600px), tablet (600–1024px), desktop (>1024px) — and `test/screens_test.dart` renders each screen at all three to catch layout overflows.
- **The brand is "LiviSpace"**, recolored into the app's own blue/violet accent (`AppColors.dark.primary` / `.secondary`); the house-and-plant mark is `assets/images/logo_mark.png`. The OS launcher icon is a separate asset (dark green/cream) generated from the original brand art and hasn't been re-tinted to match.

## User journey

1. A splash screen shows the logo and a loading line, then hands off to the welcome screen.
2. The user reads the pitch and signs up or signs in (or resets a forgotten password).
3. They land on the dashboard: recent projects, a hero banner, and a tip card.
4. They upload a floor plan (or pick from the mock examples).
5. A mock AI processing screen "analyzes" it.
6. They review the rooms the AI claims to have detected and pick one.
7. They compare AI-generated layout options for that room, ranked by match score.
8. They can view a chosen layout as a rotatable, zoomable 3D room.
9. Admins can review pending sign-ups and approve or reject them from a dedicated screen.

## Features

- Splash screen with logo and loading indicator
- Welcome screen with product messaging and onboarding CTA
- Sign in / sign up with validation, password visibility toggles, and a forgot-password flow (locked username/email, new password + confirm)
- Dashboard with a project preview, hero banner, and navigation that adapts from a bottom nav (mobile) to a side rail (tablet/desktop)
- A full Projects screen with search over the mock project list
- Floor-plan upload screen with a dropzone and example plans
- Mock AI processing screen with animated progress
- Room detection and selection experience with per-room suitability scores
- Layout recommendation gallery — a swipeable deck on mobile, a grid on wider screens
- A 3D room viewer: drag to orbit, pinch or button to zoom
- Profile screen (stats, settings, sign out) and admin account moderation (search, filter, approve/reject)
- Dark, responsive UI built from a shared theme and component library

## App structure

The app is one library: `lib/main.dart` holds the entry point and pulls in every screen as a `part` file, so they all share one set of imports and can reference each other's (even private) classes directly.

| File | Purpose |
| --- | --- |
| `lib/main.dart` | Entry point, `MaterialApp`, and `part` declarations |
| `lib/app_theme.dart` | Design tokens — colors, type scale, spacing, radius, shadows |
| `lib/app_components.dart` | Shared widgets — buttons, cards, chips, inputs, logo mark |
| `lib/responsive.dart` | Breakpoints and responsive layout helpers |
| `lib/splash.dart` | Splash screen |
| `lib/welcome.dart` | Landing / onboarding screen |
| `lib/auth.dart` | Sign in / sign up |
| `lib/forgot_password.dart` | Password reset (locked identity fields) |
| `lib/dashboard.dart` | Home dashboard and navigation shell |
| `lib/projects.dart` | Full, searchable project list |
| `lib/upload.dart` | Floor-plan upload |
| `lib/processing.dart` | Mock AI processing animation |
| `lib/room_selection.dart` | Detected-room review and selection |
| `lib/layouts.dart` | Ranked layout recommendations |
| `lib/room_viewer.dart` | Interactive 3D room viewer |
| `lib/admin_accounts.dart` | Admin account moderation |
| `lib/profile.dart` | User profile and settings |

## Getting started

Requirements:

- Flutter SDK
- Dart SDK `^3.10.4`

Install dependencies and run the app:

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze
flutter test
```

`test/widget_test.dart` covers navigation (tab switching, "See all", forgot password). `test/screens_test.dart` renders every screen at mobile (360px), tablet (800px) and desktop (1440px) widths to catch responsive layout bugs.

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
