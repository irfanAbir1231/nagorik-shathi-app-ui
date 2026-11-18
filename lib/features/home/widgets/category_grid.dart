import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../opportunities/presentation/category_visuals.dart';
import '../../opportunities/presentation/labels.dart';

/// Category tiles, four to a row. Shows the first seven and a "More" tile
/// until expanded.
///
/// Tiles sit in a Wrap rather than a fixed-ratio grid so that two-line Bangla
/// labels and large text sizes make a tile taller instead of overflowing.
class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  static const _collapsedCount = 7;
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canCollapse = opportunityCategories.length > _collapsedCount + 1;
    final shown = _expanded || !canCollapse
        ? opportunityCategories
        : opportunityCategories.take(_collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(builder: (context, constraints) {
        const spacing = 4.0;
        final tileWidth = (constraints.maxWidth - spacing * 3) / 4;
        return Wrap(spacing: spacing, runSpacing: 8, children: [
          for (final c in shown)
            SizedBox(
              width: tileWidth,
              child: _Tile(
                icon: categoryVisual(c).icon,
                color: categoryVisual(c).color,
                label: categoryLabel(l, c),
                onTap: () => widget.onPick(c),
              ),
            ),
          if (canCollapse)
            SizedBox(
              width: tileWidth,
              child: _Tile(
                icon: _expanded ? Icons.expand_less_rounded : Icons.apps_rounded,
                color: scheme.onSurfaceVariant,
                label: _expanded ? l.fewerCategories : l.moreCategories,
                onTap: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ]);
      }),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ]),
        ),
      );
}
