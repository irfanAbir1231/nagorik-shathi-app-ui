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
      final onAuthRoute = Routes.signedOutRoutes.contains(state.matchedLocation);
      if (!signedIn && !onAuthRoute) return Routes.login;
      if (signedIn && onAuthRoute) return Routes.home;
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.opportunities, builder: (_, _) => const OpportunitiesScreen())],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.myList,
              builder: (_, state) => MyListScreen(initialTab: state.uri.queryParameters['tab'] == 'plans' ? 1 : 0),
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      // Opened from the floating Ask button, full-screen with a back button.
      // The conversation lives in chatControllerProvider, so it survives closing.
      GoRoute(path: Routes.chat, builder: (_, _) => const ChatScreen()),
      // Outside the shell so the detail page is full-screen with a back button.
      GoRoute(
        path: '/opportunity/:slug',
        builder: (_, state) => OpportunityDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/plan/:id',
        builder: (_, state) => PlanDetailScreen(planId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.register, builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.register)),
      GoRoute(path: Routes.forgotPin, builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.resetPin)),
      GoRoute(path: Routes.otpLogin, builder: (_, _) => const OtpFlowScreen(flow: OtpFlow.otpLogin)),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    ],
  );
});

/// Four tabs with the Ask button docked in the middle of the bar.
class _Shell extends StatelessWidget {
  const _Shell({required this.shell});
  final StatefulNavigationShell shell;

  static const _askColor = AppColors.sun;
  static const _askInk = AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    Widget tab(int i, IconData icon, IconData selectedIcon, String label) => Expanded(
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

    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton(
        tooltip: l.navAsk,
        shape: const CircleBorder(),
        backgroundColor: _askColor,
        foregroundColor: _askInk,
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push(Routes.chat);
        },
        child: const Icon(Icons.forum_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(children: [
          tab(0, Icons.home_outlined, Icons.home_rounded, l.navHome),
          tab(1, Icons.search, Icons.manage_search, l.navOpportunities),
          // The button's label, under the notch. The button itself carries the
          // same text as its tooltip, so screen readers skip this copy.
          SizedBox(
            width: 72,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ExcludeSemantics(
                child: Text(
                  l.navAsk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          tab(2, Icons.bookmark_border, Icons.bookmark_rounded, l.navSaved),
          tab(3, Icons.person_outline, Icons.person_rounded, l.navProfile),
        ]),
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
    final scheme = theme.colorScheme;
    final color = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 32,
            decoration: BoxDecoration(
              color: selected ? scheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(selected ? selectedIcon : icon, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}
