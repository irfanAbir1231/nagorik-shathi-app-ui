import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_user.dart';
import '../../../core/ui/ui.dart';

/// The green illustrated header: greeting, district, profile shortcut and search.
class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.user,
    required this.onSearch,
    required this.onSpeak,
    required this.onProfile,
  });

  final AuthUser? user;
  final ValueChanged<String> onSearch;
  final VoidCallback onSpeak;
  final VoidCallback onProfile;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _submit(String value) {
    widget.onSearch(value.trim());
    _search.clear();
  }

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.greetMorning;
    if (hour < 17) return l.greetAfternoon;
    return l.greetEvening;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final scaler = MediaQuery.textScalerOf(context);
    const searchHeight = 56.0;
    // Collapsed: just the search bar under the status bar. Expanded: greeting above it.
    final minExtent = top + 10 + searchHeight + 12;
    final maxExtent = top + 16 + scaler.scale(98) + 18 + searchHeight + 18;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderDelegate(
        minExtent: minExtent,
        maxExtent: maxExtent,
        top: top,
        searchHeight: searchHeight,
        builder: _buildContent,
        search: _buildSearch,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = widget.user;
    final name = user?.name ?? '';
    final district = user?.district;
    const onHero = Colors.white;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(l),
                style: theme.textTheme.bodyLarge?.copyWith(color: onHero.withValues(alpha: 0.85)),
              ),
              if (name.isNotEmpty)
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(color: onHero, fontWeight: FontWeight.w700),
                ),
              if (district != null && district.isNotEmpty) ...[
                const SizedBox(height: 8),
                _DistrictChip(district: district),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(name: name, onTap: widget.onProfile),
      ],
    );
  }

  Widget _buildSearch(BuildContext context, double elevation) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: const StadiumBorder(),
      elevation: elevation,
      shadowColor: Colors.black38,
      child: TextField(
        controller: _search,
        onSubmitted: _submit,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l.searchHint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton.filledTonal(
              tooltip: l.homeSpeak,
              onPressed: widget.onSpeak,
              icon: const Icon(Icons.mic),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.top,
    required this.searchHeight,
    required this.builder,
    required this.search,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;
  final double top;
  final double searchHeight;
  final WidgetBuilder builder;
  final Widget Function(BuildContext, double) search;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    // The greeting fades out in the first 60% of the collapse.
    final fade = (1 - t / 0.6).clamp(0.0, 1.0);
    final bottomGap = 18 - 6 * t;
    return HeroBackdrop(
      radius: 28 * (1 - t) + 18 * t,
      child: Stack(children: [
        Positioned(
          left: 20,
          right: 20,
          top: top + 16 - shrinkOffset * 0.4,
          child: IgnorePointer(
            ignoring: fade < 0.5,
            child: Opacity(opacity: fade, child: builder(context)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomGap,
          height: searchHeight,
          child: search(context, 3 + 3 * t),
        ),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) => true;
}

class _DistrictChip extends StatelessWidget {
  const _DistrictChip({required this.district});
  final String district;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            district,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    return Semantics(
      button: true,
      label: l.profileTitle,
      child: Tap(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.sun,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: ExcludeSemantics(
            child: initial.isEmpty
                ? const Icon(Icons.person, color: AppColors.ink)
                : Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
