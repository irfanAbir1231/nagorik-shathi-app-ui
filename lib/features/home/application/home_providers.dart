import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../../../core/providers.dart';
import '../../opportunities/domain/opportunity.dart';
import '../../plans/domain/plan.dart';

/// Programmes whose deadline has not passed, soonest first, for the Home tab.
///
/// The API has no sort-by-deadline option, so this sorts the first page on the
/// phone. A programme closing soon that is not on that page will not show here.
/// It is the same request as the unfiltered Programmes tab, so the two share
/// one answer.
final closingSoonProvider = FutureProvider.autoDispose<List<OpportunitySummary>>((ref) {
  final repo = ref.read(opportunityRepositoryProvider);
  return cachedFirst(
    ref,
    id: 'closingSoon',
    peek: () => repo.cachedList(limit: 20)?.map(_closing),
    fetch: () async => _closing((await repo.list(limit: 20)).unwrap()),
  );
});

List<OpportunitySummary> _closing(OpportunityPage page) {
  final open = [
    for (final o in page.items)
      if (o.deadline != null && daysUntil(o.deadline!) >= 0) o,
  ]..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  return open.take(8).toList();
}

/// Whole calendar days from today to [date], in the phone's time zone.
/// 0 means today is the last day; negative means it has passed.
int daysUntil(DateTime date, {DateTime? now}) {
  DateTime day(DateTime d) {
    final l = d.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  // Rounded because a day across a daylight-saving change is not 24 hours.
  return (day(date).difference(day(now ?? DateTime.now())).inHours / 24).round();
}

/// The first step still to do, or null when every step is done or skipped.
PlanTask? nextTask(ActionPlan plan) =>
    plan.tasks.where((t) => t.status != TaskStatus.done && t.status != TaskStatus.skipped).firstOrNull;

/// The plan Home shows: the newest one that still has a step to do.
ActionPlan? activePlan(List<ActionPlan> plans) {
  final open = plans.where((p) => nextTask(p) != null).toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  return open.firstOrNull;
}
