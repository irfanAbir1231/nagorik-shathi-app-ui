import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/application/home_providers.dart' show nextTask;
import '../../opportunities/presentation/category_visuals.dart';
import '../../opportunities/presentation/labels.dart';
import '../../plans/application/plan_controller.dart';
import '../../plans/domain/plan.dart';
import '../application/saved_controller.dart';
import '../domain/saved.dart';
import 'saved_labels.dart';

/// The "My list" tab: what the citizen has saved, and the plans they are working through.
class MyListScreen extends ConsumerWidget {
  const MyListScreen({super.key, this.initialTab = 0});

  /// 0 = Saved, 1 = Plans. Home's "Plans" shortcut opens the second.
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final savedCount = ref.watch(savedControllerProvider).value?.length;
    final planCount = ref.watch(planControllerProvider).value?.length;
    String label(String name, int? n) => n == null || n == 0 ? name : '$name · $n';

    return DefaultTabController(
      // A new key when the requested tab changes, so the controller restarts
      // there; initialIndex alone is only read the first time.
      key: ValueKey(initialTab),
      initialIndex: initialTab,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.navSaved),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _SegmentedTabs(labels: [label(l.savedTab, savedCount), label(l.plansTab, planCount)]),
            ),
          ),
        ),
        body: const TabBarView(children: [_SavedTab(), _PlansTab()]),
      ),
    );
  }
}

/// Tabs drawn as a two-part pill, which reads as "one or the other" at a glance.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        splashBorderRadius: BorderRadius.circular(20),
        tabs: [for (final t in labels) Tab(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis))],
      ),
    );
  }
}

/* ------------------------------------------------------------------ saved */

class _SavedTab extends ConsumerWidget {
  const _SavedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(savedControllerProvider);
    final filter = ref.watch(savedStatusFilterProvider);

    return async.when(
      skipLoadingOnReload: true,
      loading: () => const _CardsSkeleton(),
      error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(savedControllerProvider)),
      data: (all) {
        if (all.isEmpty) {
          return EmptyState(
            icon: Icons.bookmark_border_rounded,
            color: const Color(0xFF6B4FBB),
            message: l.savedEmpty,
            actionLabel: l.browseAll,
            onAction: () => context.go('/opportunities'),
          );
        }
        final items = filter == null ? all : all.where((i) => i.status == filter).toList();
        // Only offer filters for statuses that have something in them.
        final present = SavedStatus.values.where((s) => all.any((i) => i.status == s)).toList();

        return Column(children: [
          if (present.length > 1)
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _StatusChip(
                    label: l.allStatuses,
                    icon: Icons.apps_rounded,
                    color: AppColors.primary,
                    selected: filter == null,
                    onTap: () => ref.read(savedStatusFilterProvider.notifier).set(null),
                  ),
                  for (final s in present)
                    _StatusChip(
                      label: '${savedStatusLabel(l, s)} · ${all.where((i) => i.status == s).length}',
                      icon: savedStatusVisual(s).icon,
                      color: savedStatusVisual(s).color,
                      selected: filter == s,
                      onTap: () => ref.read(savedStatusFilterProvider.notifier).set(filter == s ? null : s),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(savedControllerProvider.future),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 56),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _SavedCard(item: items[i]),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: FilterChip(
          avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: color,
          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
          side: BorderSide(color: selected ? color : Theme.of(context).colorScheme.outlineVariant),
        ),
      );
}

class _SavedCard extends ConsumerWidget {
  const _SavedCard({required this.item});
  final SavedItem item;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<SavedStatus>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 12), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l.changeStatus, style: Theme.of(ctx).textTheme.titleLarge),
          ),
          for (final s in SavedStatus.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: savedStatusVisual(s).color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(savedStatusVisual(s).icon, color: savedStatusVisual(s).color, size: 22),
              ),
              title: Text(
                savedStatusLabel(l, s),
                style: TextStyle(fontWeight: s == item.status ? FontWeight.w700 : FontWeight.w500),
              ),
              trailing: s == item.status ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              selected: s == item.status,
              onTap: () => Navigator.of(ctx).pop(s),
            ),
        ]),
      ),
    );
    if (picked == null || picked == item.status || !context.mounted) return;
    final error = await ref.read(savedControllerProvider.notifier).setStatus(item.id, picked);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText(l, error))));
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Taken now, not later: the swiped card is gone from the tree by the time
    // Undo is tapped, and a disposed card's `ref` can no longer be used.
    final controller = ref.read(savedControllerProvider.notifier);
    final result = await controller.remove(item.id);
    if (result.error != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(l, result.error!))));
      return;
    }
    final removed = result.removed;
    if (removed == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.removedToast),
        action: SnackBarAction(label: l.undo, onPressed: () => controller.undoRemove(removed)),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final opp = item.opportunity;
    final money = benefitText(l, locale, opp.benefitAmount, opp.benefitPeriod);
    final visual = categoryVisual(opp.category);
    final status = savedStatusVisual(item.status);
    final stage = savedJourney.indexOf(item.status); // -1 when not approved

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
      ),
      // The swipe removes at once and offers Undo, rather than asking "are you
      // sure": a confirmation dialog costs every citizen a tap to protect against
      // a rare slip that Undo already covers.
      onDismissed: (_) => _remove(context, ref),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Tap(
          onTap: () => context.push('/opportunity/${opp.slug}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(visual.icon, color: visual.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      opp.title.of(locale),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    if (opp.organization != null)
                      Text(
                        opp.organization!.name.of(locale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (money != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        money,
                        style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              // Where they are on the way to getting it.
              if (stage >= 0)
                Semantics(
                  label: l.stepOf(stage + 1, savedJourney.length),
                  child: ExcludeSemantics(
                    child: Row(children: [
                      for (var i = 0; i < savedJourney.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: i <= stage ? status.color : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              const SizedBox(height: 10),
              Row(children: [
                Flexible(
                  child: Material(
                    color: status.color.withValues(alpha: 0.12),
                    shape: const StadiumBorder(),
                    child: Tap(
                      customBorder: const StadiumBorder(),
                      onTap: () => _changeStatus(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(status.icon, size: 18, color: status.color),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              savedStatusLabel(l, item.status),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(color: status.color),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more_rounded, size: 18, color: status.color),
                        ]),
                      ),
                    ),
                  ),
                ),
                if (stage >= 0) ...[
                  const SizedBox(width: 8),
                  Text(l.stepOf(stage + 1, savedJourney.length), style: theme.textTheme.labelMedium),
                ],
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ plans */

class _PlansTab extends ConsumerWidget {
  const _PlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(planControllerProvider);
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const _CardsSkeleton(),
      error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(planControllerProvider)),
      data: (plans) {
        if (plans.isEmpty) {
          return EmptyState(
            icon: Icons.checklist_rounded,
            color: const Color(0xFF00838F),
            message: l.plansEmpty,
            actionLabel: l.browseAll,
            onAction: () => context.go('/opportunities'),
          );
        }
        // Plans still in progress first; finished ones sink to the bottom.
        final sorted = [...plans]..sort((a, b) {
            final aDone = nextTask(a) == null ? 1 : 0;
            final bDone = nextTask(b) == null ? 1 : 0;
            return aDone - bDone;
          });
        return RefreshIndicator(
          onRefresh: () => ref.refresh(planControllerProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => PlanCard(plan: sorted[i]),
          ),
        );
      },
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan});
  final ActionPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final next = nextTask(plan);
    final finished = next == null && plan.tasks.isNotEmpty;
    final color = finished ? AppColors.success : AppColors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Tap(
        onTap: () => context.push('/plan/${plan.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ProgressRing(progress: plan.progress, color: color, size: 60, done: finished),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  plan.title.of(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(l.progressOf(plan.doneCount, plan.tasks.length), style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                if (finished)
                  Pill(label: l.statusCompleted, color: AppColors.success, icon: Icons.emoji_events_rounded)
                else if (next != null)
                  Text(
                    l.homeNextStep(next.title.of(locale)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

/// A circular progress meter with the percentage in the middle, or a tick
/// once [done].
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.progress, required this.color, this.size = 64, this.done = false});
  final double progress;
  final Color color;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(fit: StackFit.expand, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (_, value, _) => CircularProgressIndicator(
            value: value,
            strokeWidth: size / 9,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
        Center(
          child: done
              ? Icon(Icons.check_rounded, color: color, size: size * 0.45)
              : Text(
                  NumberFormat.percentPattern(locale.languageCode).format(progress),
                  style: (size > 80 ? theme.textTheme.titleLarge : theme.textTheme.labelLarge)
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
        ),
      ]),
    );
  }
}

class _CardsSkeleton extends StatelessWidget {
  const _CardsSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const Skeleton(height: 140, radius: AppRadius.lg),
      );
}
