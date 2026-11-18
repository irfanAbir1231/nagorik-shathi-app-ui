import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../opportunities/application/opportunity_providers.dart';
import '../opportunities/domain/opportunity.dart';

import '../plans/application/plan_controller.dart';
import '../saved/application/saved_controller.dart';
import '../voice/application/voice_controller.dart';
import 'application/home_providers.dart';
import 'widgets/category_grid.dart';
import '../../core/ui/ui.dart';
import 'widgets/compact_opportunity_card.dart';
import 'widgets/home_header.dart';
import 'widgets/progress_card.dart';
import 'widgets/quick_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).value;
    final recommended = ref.watch(recommendedOpportunitiesProvider);
    final closing = ref.watch(closingSoonProvider);
    final filters = ref.read(opportunityFiltersProvider.notifier);

    void openProgramme(OpportunitySummary item) => context.push('/opportunity/${item.slug}');

    void browse({String query = '', String? category}) {
      filters.set(query: query, category: category);
      context.go('/opportunities');
    }

    void ask() => context.push('/chat');

    // Opens the assistant already listening. The chat screen puts the
    // transcript in its text box for the person to check before sending.
    void speak() {
      final voice = ref.read(voiceControllerProvider);
      context.push('/chat');
      if (voice.status == VoiceStatus.idle) {
        ref.read(voiceControllerProvider.notifier).toggle(Localizations.localeOf(context).languageCode);
      }
    }

    Future<void> refresh() async {
      ref.invalidate(planControllerProvider);
      ref.invalidate(savedControllerProvider);
      try {
        await Future.wait([
          ref.refresh(recommendedOpportunitiesProvider.future),
          ref.refresh(closingSoonProvider.future),
        ]);
      } catch (_) {
        // Each section shows its own error with a retry button.
      }
    }

    // Hide "Closing soon" entirely when nothing is closing; an empty section is noise.
    final showClosing = !(closing.hasValue && closing.value!.isEmpty);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: refresh,
          edgeOffset: MediaQuery.paddingOf(context).top + 76,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              HomeHeader(
                user: user,
                onSearch: (q) => browse(query: q),
                onSpeak: speak,
                onProfile: () => context.go('/profile'),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: FadeSlideIn(index: 0, child: ProgressCard(onAsk: ask)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FadeSlideIn(index: 1, child: QuickActions(
                    onSpeak: speak,
                    onMyList: () => context.go('/my-list'),
                    onPlans: () => context.go('/my-list?tab=plans'),
                    onBrowseAll: browse,
                  )),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader(title: l.homeCategories, icon: Icons.grid_view_rounded)),
              SliverToBoxAdapter(child: FadeSlideIn(index: 2, child: CategoryGrid(onPick: (c) => browse(category: c)))),
              if (showClosing) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: l.closingSoon,
                    icon: Icons.alarm_rounded,
                    iconColor: const Color(0xFFC62828),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CardStrip(
                    items: closing,
                    showDaysLeft: true,
                    onOpen: openProgramme,
                    onRetry: () => ref.invalidate(closingSoonProvider),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: l.recommendedForYou,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: AppColors.sun,
                  onSeeAll: browse,
                ),
              ),
              SliverToBoxAdapter(
                child: _CardStrip(
                  items: recommended,
                  emptyText: l.noRecommendations,
                  onOpen: openProgramme,
                  onRetry: () => ref.invalidate(recommendedOpportunitiesProvider),
                ),
              ),
              const SliverToBoxAdapter(child: _TrustNote()),
              // Room for the docked Ask button, which overlaps the bottom of the page.
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal row of compact cards, with its own loading and error states.
class _CardStrip extends StatelessWidget {
  const _CardStrip({
    required this.items,
    required this.onOpen,
    required this.onRetry,
    this.emptyText,
    this.showDaysLeft = false,
  });

  final AsyncValue<List<OpportunitySummary>> items;
  final ValueChanged<OpportunitySummary> onOpen;
  final VoidCallback onRetry;
  final String? emptyText;
  final bool showDaysLeft;

  static const _padding = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    return items.when(
      skipLoadingOnReload: true,
      loading: () => const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        padding: _padding,
        child: Row(children: [
          Skeleton(width: CompactOpportunityCard.width, height: 190, radius: 20),
          SizedBox(width: 12),
          Skeleton(width: CompactOpportunityCard.width, height: 190, radius: 20),
        ]),
      ),
      error: (e, _) => SizedBox(height: 200, child: ErrorRetry(error: e, onRetry: onRetry)),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(emptyText ?? ''),
          );
        }
        // IntrinsicHeight makes every card as tall as the tallest, so long
        // titles or large text grow the row instead of overflowing a fixed height.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: _padding,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                CompactOpportunityCard(item: list[i], showDaysLeft: showDaysLeft, onTap: () => onOpen(list[i])),
              ],
            ]),
          ),
        );
      },
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l.homeTrustNote, style: theme.textTheme.bodySmall)),
        ]),
      ),
    );
  }
}
