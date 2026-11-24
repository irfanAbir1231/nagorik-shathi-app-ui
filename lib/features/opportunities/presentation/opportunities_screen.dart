import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../voice/application/voice_controller.dart';
import '../../voice/presentation/voice_text.dart';
import '../application/opportunity_providers.dart';
import '../domain/opportunity.dart';
import 'category_visuals.dart';
import 'labels.dart';
import 'opportunity_card.dart';

class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends ConsumerState<OpportunitiesScreen> {
  final _scroll = ScrollController();

  // Rows that already faded in, so a row scrolled away and back does not fade again.
  final _faded = <String>{};
  final _search = TextEditingController();
  Timer? _debounce;

  /// True while a voice search started on this screen is running. The voice
  /// controller is shared with Ask, whose transcripts must not land here.
  var _listeningHere = false;

  @override
  void initState() {
    super.initState();
    // Home's search box sets the query before opening this tab.
    _search.text = ref.read(opportunityFiltersProvider).query;
    _search.addListener(() => setState(() {})); // clear button follows the text
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(opportunityListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  OpportunityFiltersController get _filters => ref.read(opportunityFiltersProvider.notifier);

  // One request per pause in typing, not one per keystroke: each query runs the
  // server's retriever and counts against the rate limit.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _filters.setQuery(value));
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    _filters.setQuery('');
  }

  void _clearAll() {
    _debounce?.cancel();
    _search.clear();
    _filters.clear();
  }

  void _toggleVoice() {
    final voice = ref.read(voiceControllerProvider);
    if (voice.status == VoiceStatus.idle) _listeningHere = true;
    ref.read(voiceControllerProvider.notifier).toggle(Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filters = ref.watch(opportunityFiltersProvider);
    final list = ref.watch(opportunityListProvider);
    final voice = ref.watch(voiceControllerProvider);
    final listening = _listeningHere && voice.status != VoiceStatus.idle;

    // Keep the box in step when the query is changed from Home while this tab
    // is already open. Typing here also updates it, so skip when they agree.
    ref.listen(opportunityFiltersProvider.select((f) => f.query), (_, q) {
      if (q != _search.text) {
        _debounce?.cancel();
        _search.text = q;
      }
    });
    // A spoken search runs at once: there is nothing to correct in two words.
    ref.listen(voiceControllerProvider, (prev, next) {
      if (!_listeningHere) return;
      if (next.resultSeq != prev?.resultSeq && (next.result ?? '').isNotEmpty) {
        _listeningHere = false;
        _debounce?.cancel();
        _search.text = next.result!;
        _filters.setQuery(next.result!);
      } else if (next.failure != null && prev?.failure == null) {
        _listeningHere = false;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(voiceFailureText(l, next.failure!))));
      } else if (next.status == VoiceStatus.idle && next.failure == null && next.resultSeq == prev?.resultSeq) {
        _listeningHere = false;
      }
    });

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: const AppBarBackdrop(),
        title: Text(l.navOpportunities),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: _SearchField(
              controller: _search,
              listening: listening,
              partial: listening ? voice.partial : '',
              transcribing: listening && voice.status == VoiceStatus.transcribing,
              onChanged: _onQueryChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                _filters.setQuery(v);
              },
              onClear: _clearSearch,
              onMic: _toggleVoice,
            ),
          ),
        ),
      ),
      body: Column(children: [
        _FilterBar(filters: filters, counts: list.value?.categoryCounts ?? const {}),
        _ResultsBar(filters: filters, list: list, onClear: _clearAll),
        // A thin bar while a new filter loads over the old results.
        SizedBox(
          height: 3,
          child: list.isLoading && list.hasValue ? const LinearProgressIndicator(minHeight: 3) : null,
        ),
        Expanded(
          child: list.when(
            // Keep showing the old list while a new filter loads, instead of a blank flash.
            skipLoadingOnReload: true,
            loading: () => const _ListSkeleton(),
            error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(opportunityListProvider)),
            data: (state) {
              if (state.items.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off_rounded,
                  title: l.noResults,
                  message: l.noResultsHint,
                  actionLabel: filters.isActive ? l.clearFilters : null,
                  onAction: filters.isActive ? _clearAll : null,
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(opportunityListProvider.future),
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Bottom room for the docked Ask button.
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 56),
                  itemCount: state.items.length + (state.hasMore || state.moreError != null ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == state.items.length) return _ListFooter(state: state);
                    final item = state.items[i];
                    return FadeSlideIn(
                      // Only the rows on screen when results arrive; rows built
                      // while scrolling appear in place.
                      key: ValueKey(item.id),
                      index: i,
                      enabled: i < 6 && _faded.add(item.id),
                      child: OpportunityCard(item: item, onTap: () => context.push('/opportunity/${item.slug}')),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.listening,
    required this.partial,
    required this.transcribing,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool listening;
  final String partial;
  final bool transcribing;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    final Widget suffix;
    if (transcribing) {
      suffix = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (listening) {
      suffix = IconButton.filled(
        tooltip: l.voiceStop,
        style: IconButton.styleFrom(backgroundColor: AppColors.danger),
        onPressed: onMic,
        icon: const Icon(Icons.stop_rounded),
      );
    } else if (controller.text.isNotEmpty) {
      suffix = IconButton(tooltip: l.clearSearch, onPressed: onClear, icon: const Icon(Icons.close_rounded));
    } else {
      suffix = IconButton(tooltip: l.voiceSearch, onPressed: onMic, icon: const Icon(Icons.mic_none_rounded));
    }

    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: listening ? (partial.isEmpty ? l.voiceListening : partial) : l.searchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: Padding(padding: const EdgeInsets.only(right: 4), child: suffix),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: pill,
        enabledBorder: listening ? pill.copyWith(borderSide: const BorderSide(color: AppColors.danger, width: 2)) : pill,
        focusedBorder: pill.copyWith(borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

/// "I may qualify", then the categories, each with its icon. Counts show only
/// when no search or eligibility filter is on: the server's counts describe the
/// whole catalogue, so with a filter they would promise results that aren't there.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters, required this.counts});
  final OpportunityFilters filters;
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final notifier = ref.read(opportunityFiltersProvider.notifier);
    final showCounts = filters.query.trim().isEmpty && !filters.eligibleOnly && counts.isNotEmpty;
    final total = counts.values.fold(0, (a, b) => a + b);

    String withCount(String label, int? n) => showCounts && n != null ? '$label · $n' : label;

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _Chip(
            label: l.eligibleOnly,
            icon: Icons.verified_rounded,
            color: AppColors.success,
            selected: filters.eligibleOnly,
            onTap: () => notifier.setEligibleOnly(!filters.eligibleOnly),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 14),
            child: VerticalDivider(width: 1),
          ),
          _Chip(
            label: withCount(l.allCategories, total),
            icon: Icons.apps_rounded,
            color: AppColors.primary,
            selected: filters.category == null,
            onTap: () => notifier.setCategory(null),
          ),
          for (final c in opportunityCategories)
            _Chip(
              label: withCount(categoryLabel(l, c), counts[c]),
              icon: categoryVisual(c).icon,
              color: categoryVisual(c).color,
              selected: filters.category == c,
              onTap: () => notifier.setCategory(filters.category == c ? null : c),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});
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
          side: BorderSide(color: selected ? color : Theme.of(context).colorScheme.outlineVariant, width: kHairline),
        ),
      );
}

/// How many results, and a way to clear the filters.
class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.filters, required this.list, required this.onClear});
  final OpportunityFilters filters;
  final AsyncValue<OpportunityListState> list;
  final VoidCallback onClear;

  /// A number only when it is known to be true: everything is loaded, or no
  /// search/eligibility filter is on so the catalogue counts apply.
  int? _count() {
    final state = list.value;
    if (state == null) return null;
    if (!state.hasMore) return state.items.length;
    if (filters.query.trim().isNotEmpty || filters.eligibleOnly || state.categoryCounts.isEmpty) return null;
    final c = filters.category;
    return c == null ? state.categoryCounts.values.fold<int>(0, (a, b) => a + b) : state.categoryCounts[c];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = _count();
    if (count == null && !filters.isActive) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
      child: Row(children: [
        Expanded(
          child: count == null
              ? const SizedBox.shrink()
              : Semantics(
                  liveRegion: true,
                  child: Text(
                    l.resultsCount(count),
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
        ),
        if (filters.isActive)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
            label: Text(l.clearFilters),
          ),
      ]),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const Skeleton(height: 150, radius: AppRadius.lg),
      );
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});
  final OpportunityListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (state.moreError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Text(l.loadMoreFailed, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(opportunityListProvider.notifier).loadMore(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l.retry),
          ),
        ]),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))),
    );
  }
}
