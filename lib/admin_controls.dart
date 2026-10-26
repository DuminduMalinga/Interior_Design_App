import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'data/admin_users.dart';

/// "All (37)", "Admins (2)", "Customers (35)": filter the account list by
/// role, with how many each would show.
class RoleFilterChips extends StatelessWidget {
  const RoleFilterChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<RoleFilter, int> counts;
  final RoleFilter selected;
  final ValueChanged<RoleFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final filter in RoleFilter.values)
          ChoiceChip(
            label: Text('${filter.label} (${counts[filter] ?? 0})'),
            selected: filter == selected,
            onSelected: (_) => onSelect(filter),
            showCheckmark: false,
            backgroundColor: c.surface,
            selectedColor: c.primary.withValues(alpha: 0.16),
            side: BorderSide(color: filter == selected ? c.primary : c.border),
            shape: const StadiumBorder(),
            labelStyle: text.labelMedium?.copyWith(
              color: filter == selected ? c.primary : c.textSecondary,
              fontWeight: filter == selected ? FontWeight.w700 : null,
            ),
          ),
      ],
    );
  }
}

/// Picks what the account list is sorted by; picking the current field again
/// reverses it.
class UserSortMenu extends StatelessWidget {
  const UserSortMenu({
    super.key,
    required this.field,
    required this.ascending,
    required this.onPick,
  });

  final UserSort field;
  final bool ascending;
  final ValueChanged<UserSort> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final arrow = ascending
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return PopupMenuButton<UserSort>(
      tooltip: 'Sort accounts',
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final option in UserSort.values)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Expanded(child: Text(option.label)),
                if (option == field) Icon(arrow, size: 16, color: c.primary),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.fullAll,
          border: Border.all(color: c.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded, size: 18, color: c.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                field.label,
                style: text.labelMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(width: 2),
              Icon(arrow, size: 14, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
