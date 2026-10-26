import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'data/sign_up_checks.dart';

/// The line under the username field: whether the name is free. Says nothing
/// until there is something to say, and a screen reader hears each change.
class UsernameStatusLine extends StatelessWidget {
  const UsernameStatusLine({super.key, required this.status});

  final UsernameStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    final (IconData?, String, Color) shown = switch (status) {
      UsernameStatus.unknown => (null, '', c.textMuted),
      UsernameStatus.checking => (null, 'Checking…', c.textMuted),
      UsernameStatus.available => (
        Icons.check_circle_outline_rounded,
        'Username available',
        c.success,
      ),
      UsernameStatus.taken => (
        Icons.cancel_outlined,
        'Username already exists',
        c.error,
      ),
    };
    final (icon, label, color) = shown;
    if (label.isEmpty) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          children: [
            if (status == UsernameStatus.checking)
              const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: text.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// How strong the new password is, as a labelled bar under the password
/// field. Hidden until something is typed.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  /// Red for weak, amber for fair, blue for good, green for strong.
  static Color colorFor(PasswordStrength strength, AppColors c) =>
      switch (strength.label) {
        'Strong' => c.success,
        'Good' => c.primary,
        'Fair' => c.warning,
        _ => c.error,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final strength = PasswordStrength.of(password);
    if (password.isEmpty) return const SizedBox.shrink();
    final color = colorFor(strength, c);

    return Semantics(
      label: 'Password strength: ${strength.label}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Password strength',
                    style: text.labelSmall?.copyWith(color: c.textMuted),
                  ),
                ),
                Text(
                  strength.label,
                  style: text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: ColoredBox(
                color: c.border,
                child: SizedBox(
                  height: 8,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.centerLeft,
                    widthFactor: strength.fraction,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
