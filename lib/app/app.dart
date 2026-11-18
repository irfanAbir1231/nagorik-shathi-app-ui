import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ui/ui.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_widgets.dart' show AppMark;
import '../l10n/generated/app_localizations.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final restoring = ref.watch(authControllerProvider).isLoading;
    final textSize = ref.watch(textSizeProvider);

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      scrollBehavior: const _WeightyScroll(),
      builder: (context, child) {
        // The in-app text size multiplies the phone's own setting.
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(100) / 100;
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(systemScale * textSize.factor)),
          child: restoring ? const _Splash() : (child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}

/// Shown while the saved session is restored.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: HeroBackdrop(
            radius: 0,
            child: SizedBox.expand(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const AppMark(size: 88),
                const SizedBox(height: 18),
                Text(
                  AppLocalizations.of(context).appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Bouncy, weighty scrolling on every screen, with the same feel on all phones.
class _WeightyScroll extends MaterialScrollBehavior {
  const _WeightyScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
