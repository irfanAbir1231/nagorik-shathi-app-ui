import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ui/ui.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/auth_widgets.dart' show AppMark;
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'warm_up.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final restoring = ref.watch(authControllerProvider).isLoading;
    final textSize = ref.watch(textSizeProvider);
    ref.watch(warmUpProvider);

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
        // The status bar gets its own solid band, and everything below starts
        // after it, so no header ever sits under the clock and battery icons.
        final inset = media.padding.top;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
          child: Column(children: [
            Container(height: inset, color: AppColors.primaryDeep),
            Expanded(
              child: MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(systemScale * textSize.factor),
                  padding: media.padding.copyWith(top: 0),
                  viewPadding: media.viewPadding.copyWith(top: 0),
                ),
                child: restoring ? const _Splash() : (child ?? const SizedBox.shrink()),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Shown while the saved session is restored. It matches the native launch
/// screen (same colour, same mark in the same place), so the hand-over is
/// invisible, and adds a loading indicator below the mark.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mark = width * 0.467;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.primaryDeep,
        child: Stack(fit: StackFit.expand, alignment: Alignment.center, children: [
          Center(child: AppMark(size: mark)),
          Positioned(
            top: MediaQuery.sizeOf(context).height / 2 + mark / 2 + 44,
            child: const DotsLoader(color: Colors.white),
          ),
        ]),
      ),
    );
  }
}

/// The same firm, no-bounce scrolling on every screen and phone.
class _WeightyScroll extends MaterialScrollBehavior {
  const _WeightyScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}
