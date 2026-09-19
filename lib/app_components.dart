import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_theme.dart';

// Reusable components, built once from the design tokens.

/// The app's gradient backdrop. Wrap a screen's body in it.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
      child: SizedBox.expand(child: child),
    );
  }
}

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
    this.loading = false,
    this.iconAfterLabel = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Place [icon] after the label instead of before it (e.g. an arrow).
  final bool iconAfterLabel;
  final AppButtonVariant variant;

  /// Shows a spinner in place of the label and disables the button.
  final bool loading;

  /// Fill the available width instead of hugging the label.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPrimary = variant == AppButtonVariant.primary;
    final onPressed = loading ? null : this.onPressed;
    final foreground = switch (variant) {
      AppButtonVariant.primary => c.onPrimary,
      AppButtonVariant.secondary => c.textPrimary,
      AppButtonVariant.ghost => c.primary,
    };

    final decoration = BoxDecoration(
      gradient: isPrimary ? c.brandGradient : null,
      color: switch (variant) {
        AppButtonVariant.secondary => c.surfaceElevated,
        _ => null,
      },
      borderRadius: AppRadius.mdAll,
      border: variant == AppButtonVariant.secondary
          ? Border.all(color: c.border)
          : null,
      boxShadow: isPrimary && onPressed != null
          ? AppShadows.glow(c.primary)
          : null,
    );

    return Opacity(
      opacity: this.onPressed == null && !loading ? 0.5 : 1,
      child: SizedBox(
        height: 52,
        width: expanded ? double.infinity : null,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: decoration,
            child: InkWell(
              onTap: onPressed,
              borderRadius: AppRadius.mdAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Center(
                  widthFactor: expanded ? null : 1,
                  child: loading
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: foreground,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null && !iconAfterLabel) ...[
                              Icon(icon, size: 18, color: foreground),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Text(
                              label,
                              style: context.text.labelLarge?.copyWith(
                                color: foreground,
                              ),
                            ),
                            if (icon != null && iconAfterLabel) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Icon(icon, size: 18, color: foreground),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lgAll,
    this.color,
    this.borderColor,
    this.gradient,
    this.glass = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;

  /// Translucent, blurred surface. Looks best over imagery or gradients.
  final bool glass;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      );
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: glass ? c.glassFill : (color ?? c.surface),
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(
          color: glass ? c.glassBorder : (borderColor ?? c.border),
        ),
        boxShadow: glass ? null : AppShadows.soft,
      ),
      child: content,
    );

    if (!glass) return card;
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: card,
      ),
    );
  }
}

enum AppStatus { success, warning, error, info, neutral }

extension AppStatusColor on AppStatus {
  Color colorIn(AppColors c) => switch (this) {
    AppStatus.success => c.success,
    AppStatus.warning => c.warning,
    AppStatus.error => c.error,
    AppStatus.info => c.primary,
    AppStatus.neutral => c.textMuted,
  };
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
    this.icon,
    this.color,
  });

  final String label;
  final AppStatus status;
  final IconData? icon;

  /// Overrides the colour implied by [status], for brand accents such as a
  /// plan badge that are not a state.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? status.colorIn(context.colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 1,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: AppSpacing.xs + 1),
            ],
            Text(label, style: context.text.labelMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Text field with its label above it. Borders, fill and error styling come
/// from the theme's [InputDecorationTheme].
class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController? controller;

  /// Starting text when there's no [controller] — e.g. a locked, read-only
  /// field that never needs its value read back out.
  final String? initialValue;
  final String? label;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final field = TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: c.textMuted, size: 18),
        suffixIcon: suffixIcon,
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: context.text.labelLarge?.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}

/// The LiviSpace house-and-interior glyph, cropped from brand art with a
/// transparent background. Reused wherever the app shows its own logo
/// (auth screen, welcome top bar, dashboard rail) instead of each screen
/// loading the asset itself.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 40});

  /// Rendered height; width follows the artwork's own aspect ratio.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_mark.png',
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Google's "G" mark for sign-in buttons.
class AppGoogleMark extends StatelessWidget {
  const AppGoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: SizedBox.square(
        dimension: AppIconSize.md,
        child: Center(
          child: Text(
            'G',
            style: context.text.labelMedium?.copyWith(
              color: AppBrand.google,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: context.text.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
