import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../../../core/providers.dart';
import '../domain/plan.dart';

class PlanController extends AsyncNotifier<List<ActionPlan>> {
  /// Opens from the phone's copy when there is one, refreshed behind it.
  @override
  FutureOr<List<ActionPlan>> build() {
    final repo = ref.read(planRepositoryProvider);
    return cachedFirst(
      ref,
      id: planControllerProvider,
      peek: repo.cachedList,
      fetch: () async => (await repo.list()).unwrap(),
      onUpdate: (fresh, shown) {
        // Never over a tick the person made meanwhile.
        if (identical(state.value, shown)) state = AsyncData(fresh);
      },
    );
  }

  /// Creates (or fetches the existing) plan for a programme.
  Future<ApiResult<ActionPlan>> createFor(String opportunityId) async {
    final result = await ref.read(planRepositoryProvider).create(opportunityId);
    if (result is Ok<ActionPlan>) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  /// Ticks a task. Updates at once and reverts, returning the error, if the
  /// server refuses; a checklist that silently forgets a tick is worse than none.
  Future<Err<dynamic>?> setTaskStatus(String planId, String taskId, TaskStatus status) async {
    final before = state.value;
    if (before == null) return null;
    state = AsyncData([for (final p in before) p.id == planId ? p.withTask(taskId, status) : p]);
    final result = await ref.read(planRepositoryProvider).setTaskStatus(taskId, status);
    if (result is Err<void>) {
      state = AsyncData(before);
      return result;
    }
    return null;
  }
}

final planControllerProvider = AsyncNotifierProvider<PlanController, List<ActionPlan>>(PlanController.new);

/// The plan for a programme, if one exists.
final planForOpportunityProvider = Provider.family<ActionPlan?, String>((ref, slug) {
  final plans = ref.watch(planControllerProvider).value;
  return plans?.where((p) => p.opportunitySlug == slug).firstOrNull;
});
