import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'data/project_status.dart';

/// The colour a stage is shown in: grey until the plan is analysed, blue
/// while it is being worked through, green once a layout is chosen.
AppStatus statusOfStage(ProjectStage stage) => switch (stage) {
  ProjectStage.uploaded => AppStatus.neutral,
  ProjectStage.detected || ProjectStage.layoutReady => AppStatus.info,
  ProjectStage.layoutSelected => AppStatus.success,
};

/// Where a plan is in the design flow, as a chip: "Rooms detected".
class ProjectStageChip extends StatelessWidget {
  const ProjectStageChip({super.key, required this.stage});

  final ProjectStage stage;

  @override
  Widget build(BuildContext context) =>
      AppStatusChip(label: stage.label, status: statusOfStage(stage));
}

/// The three totals at the top of Home: plans uploaded, plans finished and
/// the score of the last layout chosen (a dash until there is one).
class ProjectStatsRow extends StatelessWidget {
  const ProjectStatsRow({super.key, required this.stats});

  final ProjectStats stats;

  @override
  Widget build(BuildContext context) {
    final lastScore = stats.lastScore;
    // equal-height tiles; the intrinsic height keeps this working inside a
    // scrolling column, which gives no height to stretch to
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Stat(
              value: '${stats.plans}',
              label: 'Floor plans uploaded',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _Stat(value: '${stats.finished}', label: 'Finished plans'),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _Stat(
              value: lastScore == null ? '–' : '$lastScore',
              suffix: lastScore == null ? null : '/100',
              label: 'Last layout score',
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.suffix});

  final String value;
  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: value,
              children: [
                if (suffix != null)
                  TextSpan(
                    text: suffix,
                    style: text.labelSmall?.copyWith(color: c.textMuted),
                  ),
              ],
            ),
            style: text.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
