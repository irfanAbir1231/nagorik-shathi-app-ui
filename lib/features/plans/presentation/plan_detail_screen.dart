import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/application/home_providers.dart' show daysUntil;
import '../../opportunities/presentation/labels.dart';
import '../../saved/presentation/my_list_screen.dart' show ProgressRing;
import '../application/plan_controller.dart';
import '../domain/plan.dart';

/// A plan's checklist: progress at the top, what is left to do, then what is done.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(planControllerProvider);

    // The last step ticked: mark the moment. Only on a change made here, not
    // when opening a plan that was already finished.
    ref.listen(planControllerProvider, (prev, next) {
      double progressIn(AsyncValue<List<ActionPlan>>? v) =>
          v?.value?.where((p) => p.id == planId).firstOrNull?.progress ?? 0;
      if (prev?.hasValue == true && progressIn(prev) < 1 && progressIn(next) >= 1) _celebrate(context);
    });

    return Scaffold(
      appBar: AppBar(title: Text(l.planTitle)),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(planControllerProvider)),
        data: (plans) {
          final plan = plans.where((p) => p.id == planId).firstOrNull;
          if (plan == null) return EmptyState(icon: Icons.search_off_rounded, message: l.noResults);
          bool isClosed(PlanTask t) => t.status == TaskStatus.done || t.status == TaskStatus.skipped;
          final todo = plan.tasks.where((t) => !isClosed(t)).toList();
          final done = plan.tasks.where(isClosed).toList();

          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            _Header(plan: plan),
            if (todo.isNotEmpty) ...[
              SectionHeader(
                title: '${l.toDoSection} · ${todo.length}',
                icon: Icons.pending_actions_rounded,
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
              ),
              for (final t in todo)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: _TaskCard(planId: plan.id, task: t)),
            ],
            if (done.isNotEmpty) ...[
              SectionHeader(
                title: '${l.doneSection} · ${done.length}',
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.success,
                padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
              ),
              for (final t in done)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: _TaskCard(planId: plan.id, task: t)),
            ],
          ]);
        },
      ),
    );
  }

  void _celebrate(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        final theme = Theme.of(ctx);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const IllustratedBadge(icon: Icons.celebration_rounded, color: AppColors.success, size: 112),
              const SizedBox(height: 16),
              Text(l.planCompleteTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l.planCompleteBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l.gotIt)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.go('/my-list');
                  },
                  child: Text(l.updateStatus),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan});
  final ActionPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final finished = plan.tasks.isNotEmpty && plan.doneCount == plan.tasks.length;
    final color = finished ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.14), Colors.white],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Semantics(
          label: l.progressOf(plan.doneCount, plan.tasks.length),
          child: ExcludeSemantics(child: ProgressRing(progress: plan.progress, color: color, size: 92, done: finished)),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.title.of(locale), style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(
              l.progressOf(plan.doneCount, plan.tasks.length),
              style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            if (plan.opportunitySlug != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 40)),
                onPressed: () => context.push('/opportunity/${plan.opportunitySlug}'),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l.chatViewProgramme),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.planId, required this.task});
  final String planId;
  final PlanTask task;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    final error = await ref
        .read(planControllerProvider.notifier)
        .setTaskStatus(planId, task.id, task.isDone ? TaskStatus.pending : TaskStatus.done);
    if (error != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${l.taskUpdateFailed} ${errorText(l, error)}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final done = task.isDone;
    final due = task.dueDate;
    final overdue = !done && due != null && daysUntil(due) < 0;

    final (priorityLabel, priorityColor) = switch (task.priority) {
      TaskPriority.high => (l.priorityHigh, AppColors.danger),
      TaskPriority.medium => (l.priorityMedium, AppColors.warning),
      TaskPriority.low => (l.priorityLow, theme.colorScheme.outline),
    };

    return Card(
      color: done ? AppColors.canvas : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        checked: done,
        button: true,
        label: done ? l.markNotDone : l.markDone,
        child: Tap(
          onTap: () => _toggle(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CheckCircle(done: done),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w600,
                      color: done ? theme.colorScheme.onSurfaceVariant : AppColors.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                    child: Text(task.title.of(locale)),
                  ),
                  if (task.description != null && !done) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!.of(locale),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  if (!done) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Pill(label: priorityLabel, color: priorityColor, icon: Icons.flag_rounded),
                      if (due != null)
                        Pill(
                          label: overdue ? l.overdue : l.dueOn(formatDate(locale, due)),
                          color: overdue ? AppColors.danger : theme.colorScheme.onSurfaceVariant,
                          icon: overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
                          filled: overdue,
                        ),
                      if (task.estimatedMinutes != null)
                        Pill(
                          label: l.minutesShort(task.estimatedMinutes!),
                          color: theme.colorScheme.onSurfaceVariant,
                          icon: Icons.timer_outlined,
                        ),
                    ]),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A large round tick that fills in when done. The whole card is the tap target.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.done});
  final bool done;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? AppColors.success : Colors.transparent,
          border: Border.all(color: done ? AppColors.success : Theme.of(context).colorScheme.outline, width: 2),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: done
              ? const Icon(Icons.check_rounded, key: ValueKey('on'), size: 20, color: Colors.white)
              : const SizedBox(key: ValueKey('off')),
        ),
      );
}
