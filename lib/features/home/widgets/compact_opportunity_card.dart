import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../opportunities/presentation/category_visuals.dart';
import '../../opportunities/presentation/labels.dart';
import '../../opportunities/presentation/opportunity_card.dart' show OutcomeChip;
import '../application/home_providers.dart';
import '../../../core/ui/ui.dart';

/// A short card for horizontal strips: category, title, amount, verdict.
/// The full summary is on the detail page.
class CompactOpportunityCard extends StatelessWidget {
  const CompactOpportunityCard({super.key, required this.item, required this.onTap, this.showDaysLeft = false});
  final OpportunitySummary item;
  final VoidCallback onTap;

  /// Show a "N days left" badge instead of the deadline date.
  final bool showDaysLeft;

  static const width = 248.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final visual = categoryVisual(item.category);
    final money = benefitText(l, locale, item.benefitAmount, item.benefitPeriod);
    final deadline = item.deadline;

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x4D808080), width: kHairline),
        ),
        child: Tap(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [visual.color.withValues(alpha: 0.22), visual.color.withValues(alpha: 0.06)],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  right: -14,
                  top: -14,
                  child: ExcludeSemantics(
                    child: Icon(visual.icon, size: 84, color: visual.color.withValues(alpha: 0.13)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: theme.colorScheme.surface, shape: BoxShape.circle),
                      child: Icon(visual.icon, size: 20, color: visual.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        categoryLabel(l, item.category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (showDaysLeft && deadline != null) _DaysLeftBadge(days: daysUntil(deadline)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item.title.of(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (money != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    money,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (!showDaysLeft && deadline != null) ...[
                  const SizedBox(height: 4),
                  Text(l.deadlineOn(formatDate(locale, deadline)), style: theme.textTheme.bodySmall),
                ],
                if (item.eligibility != null) ...[
                  const SizedBox(height: 10),
                  OutcomeChip(outcome: item.eligibility!.outcome),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DaysLeftBadge extends StatelessWidget {
  const _DaysLeftBadge({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final urgent = days <= 7;
    final bg = urgent ? const Color(0xFFC62828) : AppColors.sun;
    final fg = urgent ? Colors.white : AppColors.ink;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule_rounded, size: 14, color: fg),
        const SizedBox(width: 3),
        Text(l.daysLeft(days), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
