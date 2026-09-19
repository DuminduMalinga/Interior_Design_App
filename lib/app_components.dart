import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'app_theme.dart';

// Reusable components, built once from the design tokens.

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;

  /// Fill the available width instead of hugging the label.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isPrimary = variant == AppButtonVariant.primary;
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
      opacity: onPressed == null ? 0.5 : 1,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: foreground),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        style: context.text.labelLarge?.copyWith(
                          color: foreground,
                        ),
                      ),
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

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
    this.icon,
  });

  final String label;
  final AppStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (status) {
      AppStatus.success => c.success,
      AppStatus.warning => c.warning,
      AppStatus.error => c.error,
      AppStatus.info => c.primary,
      AppStatus.neutral => c.textMuted,
    };

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
