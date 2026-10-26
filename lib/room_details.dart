import 'package:flutter/material.dart';

import 'app_components.dart';
import 'app_theme.dart';
import 'data/models.dart';

/// A size in metres to two places, as the web's `fmtMm`: 1850 -> "1.85m".
String fmtMm(double mm) => '${(mm / 1000).toStringAsFixed(2)}m';

/// The engine's placement note in plain words: "headboard:west_wall" ->
/// "Headboard · west wall". Null when it recorded none.
String? prettyStrategy(String? strategy) {
  final text = strategy?.trim() ?? '';
  if (text.isEmpty) return null;
  final spaced = text.replaceAll('_', ' ').split(':').join(' · ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// A facing in plain words: "south" -> "South".
String capitalised(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// What a layout is made of, as the web's side panel shows it: the score and
/// whether the layout is valid, the room's size, the pieces in it, and, for
/// the piece picked, what it is and why it stands where it does.
class RoomDetailsPanel extends StatelessWidget {
  const RoomDetailsPanel({
    super.key,
    required this.layout,
    required this.selectedId,
    required this.onSelect,
    required this.colorFor,
    this.compact = false,
  });

  final AnalysisLayout layout;

  /// Leave out the layout summary while a piece is picked, so a short panel
  /// (a phone's) shows the whole of the piece's details.
  final bool compact;

  /// The piece picked, if any.
  final String? selectedId;

  /// A piece was picked, or null to go back to the list.
  final ValueChanged<String?> onSelect;

  /// The colour a piece of this type is drawn in on the plan.
  final Color Function(String type) colorFor;

  @override
  Widget build(BuildContext context) {
    AnalysisFurniture? picked;
    for (final f in layout.furniture) {
      if (f.id == selectedId) picked = f;
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (!(compact && picked != null)) ...[
          _Summary(layout: layout),
          const SizedBox(height: AppSpacing.lg),
        ],
        picked == null
            ? _PieceList(
                pieces: layout.furniture,
                colorFor: colorFor,
                onSelect: onSelect,
              )
            : _PieceDetail(
                piece: picked,
                color: colorFor(picked.type),
                onBack: () => onSelect(null),
              ),
      ],
    );
  }
}

/// A small label above a value, as the web's fact grids.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall?.copyWith(color: c.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: text.titleSmall),
      ],
    );
  }
}

/// Facts in two even columns.
class _Facts extends StatelessWidget {
  const _Facts(this.facts);

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < facts.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Fact(facts[i].$1, facts[i].$2)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < facts.length
                      ? _Fact(facts[i + 1].$1, facts[i + 1].$2)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.layout});

  final AnalysisLayout layout;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Layout score',
                      style: text.labelSmall?.copyWith(color: c.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${layout.score.round()}', style: text.displayMedium),
                  ],
                ),
              ),
              AppStatusChip(
                label: layout.valid ? 'Valid layout' : 'Compromised',
                status: layout.valid ? AppStatus.success : AppStatus.warning,
                icon: layout.valid
                    ? Icons.check_rounded
                    : Icons.warning_amber_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: c.border),
          const SizedBox(height: AppSpacing.md),
          _Facts([
            (
              'Size',
              '${(layout.roomWidth / 1000).toStringAsFixed(2)} × '
                  '${(layout.roomLength / 1000).toStringAsFixed(2)} m',
            ),
            ('Area', '${_trimmed(layout.areaM2)} m²'),
            (
              'Ceiling',
              fmtMm(layout.roomHeight > 0 ? layout.roomHeight : 2800),
            ),
            ('Pieces', '${layout.furniture.length}'),
          ]),
        ],
      ),
    );
  }

  /// "13" / "13.5": no trailing zero, as the web prints the engine's number.
  static String _trimmed(double v) {
    final rounded = double.parse(v.toStringAsFixed(2));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
  }
}

class _PieceList extends StatelessWidget {
  const _PieceList({
    required this.pieces,
    required this.colorFor,
    required this.onSelect,
  });

  final List<AnalysisFurniture> pieces;
  final Color Function(String type) colorFor;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('In this room', style: text.titleMedium)),
            Text(
              'Pick one for details',
              style: text.labelSmall?.copyWith(color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final piece in pieces)
          InkWell(
            onTap: () => onSelect(piece.id),
            borderRadius: AppRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _Dot(colorFor(piece.type)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      piece.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${fmtMm(piece.width)} × ${fmtMm(piece.depth)}',
                    style: text.labelSmall?.copyWith(color: c.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: const SizedBox.square(dimension: 12),
  );
}

class _PieceDetail extends StatelessWidget {
  const _PieceDetail({
    required this.piece,
    required this.color,
    required this.onBack,
  });

  final AnalysisFurniture piece;
  final Color color;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('All pieces'),
          style: TextButton.styleFrom(
            foregroundColor: c.textMuted,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            minimumSize: const Size(0, 36),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _Dot(color),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(piece.displayName, style: text.titleLarge)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Facts([
          ('Size', '${fmtMm(piece.width)} × ${fmtMm(piece.depth)}'),
          ('Height', fmtMm(piece.height)),
          ('Facing', capitalised(piece.facing)),
          (
            'Placed by',
            prettyStrategy(piece.placementStrategy) ?? 'Not recorded',
          ),
        ]),
        if (piece.reasons.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Why it is here',
            style: text.labelSmall?.copyWith(color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final reason in piece.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(reason, style: text.bodyMedium),
            ),
        ],
      ],
    );
  }
}
