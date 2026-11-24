import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/home/application/home_providers.dart';
import '../features/opportunities/application/opportunity_providers.dart';
import '../features/opportunities/domain/opportunity.dart';

/// Background work while signed in that makes the next screens open at once:
///
/// * the Programmes tab's list starts loading with Home (it is the same request
///   as "Closing soon", so it costs nothing extra), so the tab is ready on first tap;
/// * the pages of the programmes shown on Home are fetched a little after
///   launch, one at a time, so tapping a card opens its page without a wait.
final warmUpProvider = Provider<void>((ref) {
  if (ref.watch(authControllerProvider.select((a) => a.value?.id)) == null) return;

  ref.listen(opportunityListProvider, (_, _) {});

  final repo = ref.read(opportunityRepositoryProvider);
  final timers = <Timer>[];
  ref.onDispose(() {
    for (final t in timers) {
      t.cancel();
    }
  });

  void prefetch(AsyncValue<List<OpportunitySummary>>? _, AsyncValue<List<OpportunitySummary>> next) {
    final items = next.value;
    if (items == null || items.isEmpty) return;
    // After the launch requests, so it never competes with what is on screen.
    timers.add(Timer(const Duration(seconds: 3), () => prefetchDetails(repo, items)));
  }

  ref.listen(recommendedOpportunitiesProvider, prefetch, fireImmediately: true);
  ref.listen(closingSoonProvider, prefetch, fireImmediately: true);
});
