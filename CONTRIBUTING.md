# Contributing to LiviSpace

Thank you for your interest in improving LiviSpace. Contributions of all sizes
are welcome.

## Getting set up

1. Install the Flutter SDK (Dart `^3.10.4`).
2. Clone the repository and run `flutter pub get`.
3. Follow the [README](README.md) to configure Supabase and, if you need room
   detection or layouts, the backend services.

## Making a change

1. Create a branch from `main` with a short, descriptive name.
2. Keep each pull request focused on one change.
3. Add or update tests for the behavior you change.
4. Before opening a pull request, run:

   ```bash
   flutter analyze
   flutter test
   ```

5. For UI changes, check the screen at mobile, tablet and desktop widths and
   include screenshots in the pull request.

## Style

- Follow the existing structure and the lints in `analysis_options.yaml`.
- Reuse the design tokens and components in `lib/app_theme.dart` and
  `lib/app_components.dart` instead of hard-coding colors and spacing.
- Write clear commit messages that say what changed and why.

## Security

Never commit credentials, service-role keys or personal data. Report security
issues privately to the maintainer rather than in a public issue.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
