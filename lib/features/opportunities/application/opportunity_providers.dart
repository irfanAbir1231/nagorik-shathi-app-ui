import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/cached.dart';
import '../../../core/providers.dart';
import '../data/opportunity_repository.dart';
import '../domain/opportunity.dart';

const _pageSize = 20;
const _keep = Object();

/// What the list is currently filtered by.
class OpportunityFilters {
  const OpportunityFilters({this.query = '', this.category, this.eligibleOnly = false});
  final String query;
  final String? category;

  /// Only programmes the citizen may qualify for.
  final bool eligibleOnly;

  bool get isActive => query.trim().isNotEmpty || category != null || eligibleOnly;

  OpportunityFilters copyWith({String? query, Object? category = _keep, bool? eligibleOnly}) => OpportunityFilters(
        query: query ?? this.query,
        category: identical(category, _keep) ? this.category : category as String?,
        eligibleOnly: eligibleOnly ?? this.eligibleOnly,
      );

  @override
  bool operator ==(Object other) =>
      other is OpportunityFilters &&
      other.query == query &&
      other.category == category &&
      other.eligibleOnly == eligibleOnly;

  @override
  int get hashCode => Object.hash(query, category, eligibleOnly);
}

class OpportunityFiltersController extends Notifier<OpportunityFilters> {
  @override
  OpportunityFilters build() => const OpportunityFilters();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(String? c) => state = state.copyWith(category: c);
  void setEligibleOnly(bool on) => state = state.copyWith(eligibleOnly: on);

  /// Replaces every filter at once (one reload, not one per field).
  void set({String query = '', String? category, bool eligibleOnly = false}) =>
      state = OpportunityFilters(query: query, category: category, eligibleOnly: eligibleOnly);

  void clear() => state = const OpportunityFilters();
}

final opportunityFiltersProvider =
    NotifierProvider<OpportunityFiltersController, OpportunityFilters>(OpportunityFiltersController.new);

class OpportunityListState {
  const OpportunityListState({
    required this.items,
    required this.hasMore,
    this.categoryCounts = const {},
    this.loadingMore = false,
    this.moreError,
  });
  final List<OpportunitySummary> items;
  final bool hasMore;
  final Map<String, int> categoryCounts;
  final bool loadingMore;
  final Err<dynamic>? moreError;

  OpportunityListState copyWith({
    List<OpportunitySummary>? items,
    bool? hasMore,
    bool? loadingMore,
    Err<dynamic>? moreError,
    bool clearError = false,
  }) =>
      OpportunityListState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        categoryCounts: categoryCounts,
        loadingMore: loadingMore ?? this.loadingMore,
        moreError: clearError ? null : (moreError ?? this.moreError),
      );
}

/// First page loads in `build` (and reloads whenever a filter changes);
/// [loadMore] appends the next page. A first page seen before opens at once
/// from the phone's copy and is refreshed behind it.
class OpportunityListController extends AsyncNotifier<OpportunityListState> {
  @override
  FutureOr<OpportunityListState> build() {
    final filters = ref.watch(opportunityFiltersProvider);
    return cachedFirst(
      ref,
      id: opportunityListProvider,
      peek: () => ref
          .read(opportunityRepositoryProvider)
          .cachedList(
            query: filters.query,
            category: filters.category,
            outcome: _outcome(filters),
            limit: _pageSize,
            offset: 0,
          )
          ?.map(_firstPage),
      fetch: () async => _firstPage((await _fetch(filters, 0)).unwrap()),
      onUpdate: (fresh, shown) {
        // Not over more pages the person has already loaded, or a change in flight.
        if (identical(state.value, shown)) state = AsyncData(fresh);
      },
    );
  }

  static OpportunityListState _firstPage(OpportunityPage page) => OpportunityListState(
        items: page.items,
        hasMore: page.items.length >= _pageSize,
        categoryCounts: page.categoryCounts,
      );

  static String? _outcome(OpportunityFilters f) => f.eligibleOnly ? 'eligible' : null;

  Future<ApiResult<OpportunityPage>> _fetch(OpportunityFilters f, int offset) =>
      ref.read(opportunityRepositoryProvider).list(
            query: f.query,
            category: f.category,
            outcome: _outcome(f),
            limit: _pageSize,
            offset: offset,
          );

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, clearError: true));

    final filters = ref.read(opportunityFiltersProvider);
    final result = await _fetch(filters, current.items.length);
    // The filters may have changed while this was in flight; `build` has then
    // already replaced the state, so this page no longer applies.
    if (filters != ref.read(opportunityFiltersProvider)) return;

    state = AsyncData(switch (result) {
      Ok<OpportunityPage>(:final data) => current.copyWith(
          items: [...current.items, ...data.items],
          hasMore: data.items.length >= _pageSize,
          loadingMore: false,
        ),
      final Err<OpportunityPage> e => current.copyWith(loadingMore: false, moreError: e),
    });
  }
}

final opportunityListProvider =
    AsyncNotifierProvider<OpportunityListController, OpportunityListState>(OpportunityListController.new);

/// A programme page opened before shows at once from the phone's copy.
final opportunityDetailProvider = FutureProvider.autoDispose.family<OpportunityDetail, String>((ref, slug) {
  final repo = ref.read(opportunityRepositoryProvider);
  return cachedFirst(
    ref,
    id: 'opportunity:$slug',
    peek: () => repo.cachedDetail(slug),
    fetch: () async => (await repo.detail(slug)).unwrap(),
  );
});

/// A few programmes the citizen is likely eligible for, for the Home tab.
final recommendedOpportunitiesProvider = FutureProvider.autoDispose<List<OpportunitySummary>>((ref) {
  final repo = ref.read(opportunityRepositoryProvider);
  return cachedFirst(
    ref,
    id: 'recommended',
    peek: () => repo.cachedList(outcome: 'eligible', limit: 5)?.map((p) => p.items),
    fetch: () async => (await repo.list(outcome: 'eligible', limit: 5)).unwrap().items,
  );
});

/// Loads the pages of [items] into the phone's copy in the background, one at
/// a time, so opening any of them shows the page at once. Pages already kept
/// are skipped; they are refreshed when opened.
Future<void> prefetchDetails(OpportunityRepository repo, Iterable<OpportunitySummary> items) async {
  for (final item in items) {
    if (repo.cachedDetail(item.slug) != null) continue;
    final result = await repo.detail(item.slug);
    if (result is Err) return; // Offline or failing: try again next time.
  }
}
