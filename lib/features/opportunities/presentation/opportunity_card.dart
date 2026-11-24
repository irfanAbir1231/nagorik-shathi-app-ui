import 'package:flutter/material.dart';

import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/application/home_providers.dart' show daysUntil;
import '../../saved/presentation/save_toggle.dart';
import '../domain/opportunity.dart';
import 'category_visuals.dart';
import 'labels.dart';

class OutcomeChip extends StatelessWidget {
  const OutcomeChip({super.key, required this.outcome});
  final EligibilityOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = outcomeStyle(Theme.of(context).colorScheme, outcome);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(style.icon, size: 18, color: style.color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          outcomeLabel(l, outcome),
          style: TextStyle(color: style.color, fontWeight: FontWeight.w600),
        ),
      ),
    ]);
  }
}

/// A programme in the browse list: category, title, provider, a short summary,
/// then the facts that decide whether to open it — amount, verdict, deadline.
class OpportunityCard extends StatelessWidget {
  const OpportunityCard({super.key, required this.item, required this.onTap});
  final OpportunitySummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final visual = categoryVisual(item.category);
    final money = benefitText(l, locale, item.benefitAmount, item.benefitPeriod);
    final elig = item.eligibility;
    final summary = item.summary.of(locale);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Tap(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: visual.color, width: kHairline),
                ),
                child: Icon(visual.icon, color: visual.color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    categoryLabel(l, item.category),
                    style: theme.textTheme.labelMedium?.copyWith(color: visual.color, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    item.title.of(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  if (item.organization != null)
                    Text(
                      item.organization!.name.of(locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ]),
              ),
              SaveIconButton(opportunityId: item.id),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
                if (money != null || elig != null || item.deadline != null) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (money != null) Pill(label: money, color: AppColors.primary, icon: Icons.payments_rounded),
                    if (elig != null) _OutcomePill(outcome: elig.outcome),
                    if (item.deadline != null) _DeadlinePill(deadline: item.deadline!),
                  ]),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OutcomePill extends StatelessWidget {
  const _OutcomePill({required this.outcome});
  final EligibilityOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final style = outcomeStyle(Theme.of(context).colorScheme, outcome);
    return Pill(label: outcomeLabel(AppLocalizations.of(context), outcome), color: style.color, icon: style.icon);
  }
}

/// Days left when it is near (urgent in red within a week), the date when far,
/// "Closed" once passed.
class _DeadlinePill extends StatelessWidget {
  const _DeadlinePill({required this.deadline});
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final days = daysUntil(deadline);
    if (days < 0) {
      return Pill(label: l.deadlinePassed, color: Theme.of(context).colorScheme.outline, icon: Icons.event_busy_rounded);
    }
    if (days <= 30) {
      return Pill(
        label: l.daysLeft(days),
        color: days <= 7 ? AppColors.danger : AppColors.warning,
        icon: Icons.schedule_rounded,
      );
    }
    return Pill(
      label: l.deadlineOn(formatDate(locale, deadline)),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: Icons.event_rounded,
    );
  }
}
