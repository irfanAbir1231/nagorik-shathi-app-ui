import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/theme.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_flow_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/opportunities/presentation/opportunities_screen.dart';
import '../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../features/plans/presentation/plan_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/saved/presentation/my_list_screen.dart';
import '../l10n/generated/app_localizations.dart';

const _appChannel = MethodChannel('com.shebarjanala/app');

abstract final class Routes {
  static const home = '/';
  static const opportunities = '/opportunities';
  static const chat = '/chat';
  static const myList = '/my-list';
  static const profile = '/profile';
  static const login = '/login';
  static const register = '/register';
  static const forgotPin = '/forgot-pin';
  static const otpLogin = '/otp-login';
  static const signedOutRoutes = {login, register, forgotPin, otpLogin};
  static String opportunity(String slug) => '/opportunity/$slug';
}

final routerProvider = Provider<GoRouter>((ref) {
  // go_router re-evaluates `redirect` whenever this notifier fires.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null; // splash is shown by the app builder
      final signedIn = auth.value != null;
      final onAuthRoute = Routes.signedOutRoutes.contains(
        state.matchedLocation,
      );
      if (!signedIn && !onAuthRoute) return Routes.login;
      if (signedIn && onAuthRoute) return Routes.home;
      return null;
    },
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => _Shell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            _FadeBranches(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.opportunities,
                builder: (_, _) => const OpportunitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myList,
                builder: (_, state) => MyListScreen(
                  initialTab: state.uri.queryParameters['tab'] == 'plans'
                      ? 1
                      : 0,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Opened from the floating Ask button, full-screen with a back button.
      // The conversation lives in chatControllerProvider, so it survives closing.
      GoRoute(path: Routes.chat, builder: (_, _) => const ChatScreen()),
      // Outside the shell so the detail page is full-screen with a back button.
      GoRoute(
        path: '/opportunity/:slug',
        builder: (_, state) =>
            OpportunityDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/plan/:id',
        builder: (_, state) =>
            PlanDetailScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.register),
      ),
      GoRoute(
        path: Routes.forgotPin,
        builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.resetPin),
      ),
      GoRoute(
        path: Routes.otpLogin,
        builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.otpLogin),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    ],
  );
});

/// Four tabs with a raised Ask button in the middle. The bar is flat with a
/// hairline on top, and the active tab is marked by a colour change and a short
/// bar above the icon, rather than Material's stock tinted pill.
class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  static const _barHeight = 62.0;
  static const _askSize = 60.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget tab(int i, IconData icon, IconData selectedIcon, String label) =>
        Expanded(
          child: _NavItem(
            icon: icon,
            selectedIcon: selectedIcon,
            label: label,
            selected: shell.currentIndex == i,
            // Tapping the active tab returns to that tab's root.
            onTap: () {
              HapticFeedback.selectionClick();
              shell.goBranch(i, initialLocation: i == shell.currentIndex);
            },
          ),
        );

    // Back on another tab returns to Home; back on Home sends the app to the
    // background instead of closing it.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
        } else {
          _appChannel.invokeMethod<void>('minimize');
        }
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFB9B5A8), width: kHairline),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: SizedBox(
              height: _barHeight,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Row(
                    children: [
                      tab(
                        0,
                        Icons.home_outlined,
                        Icons.home_rounded,
                        l.navHome,
                      ),
                      tab(
                        1,
                        Icons.explore_outlined,
                        Icons.explore_rounded,
                        l.navOpportunities,
                      ),
                      const SizedBox(width: _askSize + 16),
                      tab(
                        2,
                        Icons.bookmark_border_rounded,
                        Icons.bookmark_rounded,
                        l.navSaved,
                      ),
                      tab(
                        3,
                        Icons.person_outline_rounded,
                        Icons.person_rounded,
                        l.navProfile,
                      ),
                    ],
                  ),
                  // Raised button with a white ring that cuts it cleanly out of the bar.
                  Positioned(
                    top: -22,
                    child: Semantics(
                      button: true,
                      label: l.navAsk,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push(Routes.chat);
                        },
                        child: Container(
                          width: _askSize + 8,
                          height: _askSize + 8,
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Color(0xFFB9B5A8),
                                width: kHairline,
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDeep,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : const Color(0xFF7C8794);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            // Active marker: a short bar flush with the top edge.
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 28 : 0,
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
            const Spacer(),
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                selected ? selectedIcon : icon,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

/// Keeps every tab alive and cross-fades between them when the tab changes.
class _FadeBranches extends StatelessWidget {
  const _FadeBranches({required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (var i = 0; i < children.length; i++)
        _FadeBranch(active: i == index, child: children[i]),
    ],
  );
}

class _FadeBranch extends StatefulWidget {
  const _FadeBranch({required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<_FadeBranch> createState() => _FadeBranchState();
}

class _FadeBranchState extends State<_FadeBranch>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_FadeBranch old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active)
      widget.active ? _c.forward() : _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) => Offstage(
      offstage: _c.isDismissed,
      child: TickerMode(
        enabled: widget.active,
        child: IgnorePointer(
          ignoring: !widget.active,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
            child: child,
          ),
        ),
      ),
    ),
  );
}
