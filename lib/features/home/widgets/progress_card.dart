import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../opportunities/presentation/labels.dart';
import '../../plans/application/plan_controller.dart';
import '../../plans/domain/plan.dart';
import '../../saved/application/saved_controller.dart';
import '../application/home_providers.dart';
import '../../../core/ui/ui.dart';

/// The card that changes with the citizen's situation: the plan they are
/// working through, else what they have saved, else an invitation to start.
///
/// It never shows an error. If plans or saved items fail to load, Home falls
/// back to the invitation; the My list tab is where those errors are reported.
class ProgressCard extends ConsumerWidget {
  const ProgressCard({super.key, required this.onAsk});
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(planControllerProvider);
    final saved = ref.watch(savedControllerProvider);

    if ((plans.isLoading && !plans.hasValue) || (saved.isLoading && !saved.hasValue)) {
      return const Skeleton(height: 132, radius: 24);
    }

    final plan = activePlan(plans.value ?? const []);
    if (plan != null) return _PlanCard(plan: plan);

    final savedCount = saved.value?.length ?? 0;
    if (savedCount > 0) return _SavedCard(count: savedCount);

    return _StartCard(onAsk: onAsk);
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap, this.gradient});
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? scheme.surface : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: kHairline),
          boxShadow: [BoxShadow(color: const Color(0x59123456), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Tap(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final ActionPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final next = nextTask(plan);

    const onGreen = Colors.white;
    return _CardShell(
      onTap: () => context.push('/plan/${plan.id}'),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryBright, AppColors.primary],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              l.homeContinuePlan,
              style: theme.textTheme.labelLarge?.copyWith(color: onGreen.withValues(alpha: 0.85)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: onGreen, width: kHairline),
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: onGreen, size: 20),
          ),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: plan.progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              NumberFormat.percentPattern(locale.languageCode).format(v),
              style: theme.textTheme.displaySmall?.copyWith(color: onGreen, fontWeight: FontWeight.w700, height: 1.1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.progressOf(plan.doneCount, plan.tasks.length),
                style: theme.textTheme.bodyMedium?.copyWith(color: onGreen.withValues(alpha: 0.9)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: plan.progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: 8,
            color: Colors.white,
            backgroundColor: onGreen.withValues(alpha: 0.25),
          )),
        ),
        const SizedBox(height: 14),
        Text(
          plan.title.of(locale),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(color: onGreen, fontWeight: FontWeight.w700),
        ),
        if (next != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                l.homeNextStep(next.title.of(locale)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              if (next.dueDate != null)
                Text(
                  l.dueOn(formatDate(locale, next.dueDate!)),
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ink),
                ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _CardShell(
      onTap: () => context.go('/my-list'),
      child: Row(children: [
        const IllustratedBadge(icon: Icons.bookmark_rounded, color: Color(0xFF6B4FBB), size: 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.homeSavedCount(count), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l.homeSavedBody, style: theme.textTheme.bodyMedium),
          ]),
        ),
        const Icon(Icons.chevron_right),
      ]),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onAsk});
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _CardShell(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.sun.withValues(alpha: 0.28), theme.colorScheme.primaryContainer.withValues(alpha: 0.7)],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              l.homeStartTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(l.homeStartBody, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: onAsk, icon: const Icon(Icons.forum_rounded), label: Text(l.homeStartCta)),
          ]),
        ),
        const SizedBox(width: 12),
        const IllustratedBadge(icon: Icons.lightbulb_rounded, color: AppColors.primary, size: 80),
      ]),
    );
  }
}
