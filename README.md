# LiviSpace

> **Design spaces for better living.**

LiviSpace is a cross-platform Flutter app that turns floor plans into personalized,
AI-assisted interior designs. Upload a plan, review detected rooms, explore
layout recommendations, and save your favorite spaces in an interactive 3D
viewer.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-6C63FF)](#supported-platforms)

## Contents

- [Highlights](#highlights)
- [How it works](#how-it-works)
- [Feature overview](#feature-overview)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Testing](#testing)
- [Supported platforms](#supported-platforms)

## Highlights

- AI-assisted floor-plan analysis
- Room-specific layout recommendations
- Interactive room visualization with 3D-style rendering
- Responsive UI for mobile, tablet, and desktop
- Supabase authentication, storage, and synchronized designs
- Light and dark themes with persistent preferences
- Cross-platform export and sharing

## How it works

```text
Create an account
      |
Upload a floor plan
      |
AI detects rooms, walls, doors, and windows
      |
Choose a room and compare recommended layouts
      |
Confirm a design
      |
Explore, export, share, and revisit it in 3D
```

## Feature overview

### Discover and manage projects

- Welcome and onboarding experience with live site statistics.
- Dashboard with recent projects, design tips, and responsive navigation.
- Searchable Projects screen for all uploaded floor plans.
- Pull-to-refresh and clear loading, empty, retry, and failure states.

### AI-assisted design workflow

- Upload JPG, JPEG, or PNG floor plans up to 10 MB.
- Processing state with backend polling, progress feedback, timeout, and
  failure handling.
- Room detection with room type, estimated dimensions, area, and suitability
  score.
- Support for living rooms, bedrooms, master bedrooms, kitchens, bathrooms,
  and dining areas.
- Ranked layout recommendations with match scores, tags, and a recommended
  option.
- Confirmed layouts are saved as reusable designs.

### Explore and share designs

- Designs tab for saved rooms created in the app or on the connected web app.
- Interactive room viewer with drag-to-orbit and pinch/button zoom controls.
- Export a rendered room view as a PNG.
- Share a design through the platform share sheet.
- Delete saved designs without deleting the original floor plan or layouts.

### Accounts and personalization

- Sign up and sign in with email or username support.
- Strong password validation and password visibility controls.
- Forgot-password and reset-password flows.
- Editable profile photo with image validation and resizing.
- Profile statistics for projects and rooms.
- Email notification and product news preferences.
- Light and dark appearance modes, persisted on the device.
- Help and About screens.

### Administration

- Admin account management with search and activity filtering.
- Customer account deletion with protected administrator accounts.
- Audit log for administrative activity.
- Product news composer with test-send support.

## Architecture

The app uses a shared Flutter library. [`lib/main.dart`](lib/main.dart) owns
the application entry point and assembles the feature screens with Dart
`part` files.

| Area | Location | Responsibility |
| --- | --- | --- |
| App entry point | [`lib/main.dart`](lib/main.dart) | Flutter bootstrap, Supabase initialization, theme and navigation |
| Design system | [`lib/app_theme.dart`](lib/app_theme.dart) | Colors, typography, spacing, radii, shadows, and themes |
| Shared components | [`lib/app_components.dart`](lib/app_components.dart) | Buttons, cards, inputs, logos, and reusable UI |
| Responsive layout | [`lib/responsive.dart`](lib/responsive.dart) | Mobile, tablet, and desktop breakpoints |
| Feature screens | [`lib/`](lib/) | Authentication, dashboard, projects, upload, layouts, profile, and admin flows |
| Data layer | [`lib/data/`](lib/data/) | Models, repositories, layout services, exports, and Supabase access |
| Backend schema | [`supabase/migrations/`](supabase/migrations/) | Database tables, functions, and policies |
| Edge functions | [`supabase/functions/`](supabase/functions/) | Notifications, account deletion, and username login |
| Wall detector | [`wall_detector/`](wall_detector/) | Python service for detecting rooms and floor-plan features |

### Web app interoperability

LiviSpace shares floor-plan analysis and saved-design data with the companion
[Interior-Design-Web](https://github.com/DuminduMalinga/Interior-Design-Web)
application. Analysis and layout documents are stored on the floor-plan
analysis record, allowing a project started on one platform to be continued
on the other.

## Getting started

### Prerequisites

- Flutter SDK with Dart SDK `^3.10.4`
- A configured Supabase project
- Android Studio, Xcode, or a desktop toolchain for the target platform

### Install and run

```bash
git clone https://github.com/DuminduMalinga/Interior_Design_App.git
cd Interior_Design_App
flutter pub get
flutter run
```

List available devices with:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

## Configuration

The app reads deployment-specific values through Flutter compile-time
environment variables. Do not commit credentials or service-role keys.

### Supabase

Configure the Supabase URL and publishable/anonymous key in the app's
environment setup used by [`lib/env.dart`](lib/env.dart). Apply the migrations
in [`supabase/migrations/`](supabase/migrations/) to the target project.

### AI services

The floor-plan detector and room layout services can be configured at runtime:

```bash
flutter run \
  --dart-define=DETECTOR_URL=http://10.0.2.2:8000 \
  --dart-define=LAYOUT_SERVICE_BASE=https://<service-host>
```

Individual layout endpoints can also be supplied with
`LIVING_ROOM_LAYOUT_URL`, `BEDROOM_LAYOUT_URL`, `MASTER_BEDROOM_LAYOUT_URL`,
`KITCHEN_LAYOUT_URL`, `BATHROOM_LAYOUT_URL`, and `DINING_LAYOUT_URL`.

### Wall detector service

The optional Python service in [`wall_detector/`](wall_detector/) uses the
provided YOLO weights to detect rooms, walls, doors, and windows:

```bash
cd wall_detector
pip install -r requirements.txt
uvicorn server:app --port 8000
```

For local processing of uploaded plans, configure the required Supabase service
key in the environment used by the worker. Never expose that key to the app or
commit it to source control.

## Testing

Run static analysis and the full Flutter test suite:

```bash
flutter analyze
flutter test
```

The test suite includes authentication and validation tests, model and service
tests, navigation tests, export tests, theme tests, and responsive screen
coverage. [`test/screens_test.dart`](test/screens_test.dart) renders screens at
mobile, tablet, and desktop widths to catch layout overflows.

Run the wall detector tests separately:

```bash
cd wall_detector
python -m unittest test_labels
```

## Supported platforms

The Flutter project includes targets for:

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Project status

LiviSpace is an actively developed product prototype. The core experience,
authentication, data persistence, AI service integration, saved designs, and
responsive UI are implemented; service URLs and Supabase deployment settings
must be configured for a production environment.

## License

No license has been declared for this repository yet.
