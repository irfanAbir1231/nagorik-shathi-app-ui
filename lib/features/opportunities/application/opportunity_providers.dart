import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
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
/// [loadMore] appends the next page.
class OpportunityListController extends AsyncNotifier<OpportunityListState> {
  @override
  Future<OpportunityListState> build() async {
    final filters = ref.watch(opportunityFiltersProvider);
    final page = (await _fetch(filters, 0)).unwrap();
    return OpportunityListState(
      items: page.items,
      hasMore: page.items.length >= _pageSize,
      categoryCounts: page.categoryCounts,
    );
  }

  Future<ApiResult<OpportunityPage>> _fetch(OpportunityFilters f, int offset) =>
      ref.read(opportunityRepositoryProvider).list(
            query: f.query,
            category: f.category,
            outcome: f.eligibleOnly ? 'eligible' : null,
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

final opportunityDetailProvider = FutureProvider.autoDispose.family<OpportunityDetail, String>((ref, slug) async {
  return (await ref.read(opportunityRepositoryProvider).detail(slug)).unwrap();
});

/// A few programmes the citizen is likely eligible for, for the Home tab.
final recommendedOpportunitiesProvider = FutureProvider.autoDispose<List<OpportunitySummary>>((ref) async {
  final page = (await ref.read(opportunityRepositoryProvider).list(outcome: 'eligible', limit: 5)).unwrap();
  return page.items;
});
