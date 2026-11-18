import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ui/ui.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/application/auth_controller.dart';
import '../auth/presentation/auth_widgets.dart' show AppMark, LanguageSwitch;
import '../home/application/home_providers.dart' show nextTask;
import '../plans/application/plan_controller.dart';
import '../saved/application/saved_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(l.signOutConfirmTitle),
        content: Text(l.signOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.signOut),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }

  Future<void> _callHelpline(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: '333'));
    } catch (_) {
      opened = false;
    }
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(l.couldNotOpen)));
  }

  void _showAbout(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppMark(size: 56),
            const SizedBox(height: 14),
            Text(l.aboutApp, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(l.aboutBody, style: Theme.of(ctx).textTheme.bodyLarge),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final saved = ref.watch(savedControllerProvider).value;
    final plans = ref.watch(planControllerProvider).value;
    final textSize = ref.watch(textSizeProvider);

    final inProgress = plans?.where((p) => nextTask(p) != null).length;
    final finished = plans?.where((p) => p.tasks.isNotEmpty && nextTask(p) == null).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileBar(
              top: MediaQuery.paddingOf(context).top,
              scale: MediaQuery.textScalerOf(context).scale(1),
              title: l.profileTitle,
              name: user?.name ?? '',
              phone: user?.phone,
              district: user?.district,
            ),
          ),
          SliverList(delegate: SliverChildListDelegate([
          SectionHeader(title: l.yourActivity, icon: Icons.insights_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _StatTile(
                  icon: Icons.bookmark_rounded,
                  color: const Color(0xFF6B4FBB),
                  count: saved?.length,
                  label: l.savedTab,
                  onTap: () => context.go('/my-list'),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  icon: Icons.checklist_rounded,
                  color: const Color(0xFF00838F),
                  count: inProgress,
                  label: l.plansTab,
                  onTap: () => context.go('/my-list?tab=plans'),
                ),
                const SizedBox(width: 10),
                _StatTile(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.success,
                  count: finished,
                  label: l.statusCompleted,
                  onTap: () => context.go('/my-list?tab=plans'),
                ),
              ]),
            ),
          ),
          SectionHeader(title: l.settingsSection, icon: Icons.tune_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(children: [
                _Row(
                  icon: Icons.translate_rounded,
                  title: l.language,
                  trailing: const LanguageSwitch(),
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const _RowIcon(icon: Icons.format_size_rounded),
                      const SizedBox(width: 14),
                      Expanded(child: Text(l.textSize, style: theme.textTheme.titleMedium)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TextSize>(
                        showSelectedIcon: false,
                        segments: [
                          for (final (size, label, glyph) in [
                            (TextSize.normal, l.textNormal, 14.0),
                            (TextSize.large, l.textLarge, 17.0),
                            (TextSize.larger, l.textLarger, 20.0),
                          ])
                            ButtonSegment(
                              value: size,
                              tooltip: label,
                              label: Column(mainAxisSize: MainAxisSize.min, children: [
                                ExcludeSemantics(
                                  child: Text('Aa', style: TextStyle(fontSize: glyph, fontWeight: FontWeight.w700)),
                                ),
                                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                        ],
                        selected: {textSize},
                        onSelectionChanged: (s) => ref.read(textSizeProvider.notifier).set(s.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: theme.colorScheme.primaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
          SectionHeader(title: l.helpSection, icon: Icons.support_agent_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                _Row(
                  icon: Icons.call_rounded,
                  iconColor: AppColors.success,
                  title: l.helpline,
                  subtitle: l.helplineBody,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _callHelpline(context),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Row(
                  icon: Icons.info_outline_rounded,
                  title: l.aboutApp,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAbout(context),
                ),
                const Divider(indent: 16, endIndent: 16),
                _Row(icon: Icons.shield_outlined, iconColor: AppColors.warning, title: l.pinSafety),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
              ),
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l.signOut),
            ),
          ),
          // Room for the docked Ask button.
          const SizedBox(height: 64),
          ])),
        ]),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.name, this.phone, this.district});
  final String name;
  final String? phone;
  final String? district;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isEmpty ? '' : name.characters.first.toUpperCase();
    final muted = Colors.white.withValues(alpha: 0.9);
    return Row(children: [
      Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.sun,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: ExcludeSemantics(
          child: initial.isEmpty
              ? const Icon(Icons.person, size: 36, color: AppColors.ink)
              : Text(initial, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.ink)),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          if (phone != null)
            Row(children: [
              Icon(Icons.phone_iphone_rounded, size: 16, color: muted),
              const SizedBox(width: 4),
              Flexible(child: Text(phone!, style: theme.textTheme.bodyMedium?.copyWith(color: muted))),
            ]),
          if (district != null && district!.isNotEmpty)
            Row(children: [
              Icon(Icons.place_rounded, size: 16, color: muted),
              const SizedBox(width: 4),
              Flexible(child: Text(district!, style: theme.textTheme.bodyMedium?.copyWith(color: muted))),
            ]),
        ]),
      ),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final int? count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Tap(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              // A dash while loading or unknown, never a made-up zero.
              Text(
                count?.toString() ?? '–',
                style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon({required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: c, size: 22),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.trailing, this.onTap, this.iconColor});
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          _RowIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ]),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
  }
}

/// Pinned profile header: the title bar stays; the avatar block collapses away.
class _ProfileBar extends SliverPersistentHeaderDelegate {
  _ProfileBar({
    required this.top,
    required this.scale,
    required this.title,
    required this.name,
    required this.phone,
    required this.district,
  });

  final double top;
  final double scale;
  final String title;
  final String name;
  final String? phone;
  final String? district;

  @override
  double get minExtent => top + 64;
  @override
  double get maxExtent => top + 16 + 30 * scale + 18 + 72 * (scale > 1 ? scale : 1) + 28;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 0.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final fade = (1 - t / 0.6).clamp(0.0, 1.0);
    return HeroBackdrop(
      radius: 28 * (1 - t) + 18 * t,
      child: Stack(children: [
        Positioned(
          left: 20,
          right: 20,
          top: top + 16,
          child: Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: top + 16 + 30 * scale + 18 - shrinkOffset * 0.3,
          child: Opacity(opacity: fade, child: _Identity(name: name, phone: phone, district: district)),
        ),
      ]),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileBar old) => true;
}
