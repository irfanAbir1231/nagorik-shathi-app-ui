import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shebar_janala_app/core/ui/ui.dart';
import 'package:shebar_janala_app/features/auth/application/auth_controller.dart';
import 'package:shebar_janala_app/features/auth/domain/auth_user.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/plans/application/plan_controller.dart';
import 'package:shebar_janala_app/features/plans/domain/plan.dart';
import 'package:shebar_janala_app/features/profile/profile_screen.dart';
import 'package:shebar_janala_app/features/saved/application/saved_controller.dart';
import 'package:shebar_janala_app/features/saved/domain/saved.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class FakeAuth extends AuthController {
  var loggedOut = false;

  @override
  Future<AuthUser?> build() async =>
      const AuthUser(id: 'u1', name: 'Rahima Begum', phone: '01712345678', role: 'citizen', language: 'en', district: 'Rangpur');

  @override
  Future<void> logout() async => loggedOut = true;
}

class FakeSaved extends SavedController {
  @override
  Future<List<SavedItem>> build() async => [
        for (final id in ['1', '2'])
          SavedItem(
            id: id,
            status: SavedStatus.interested,
            opportunity: OpportunitySummary(
              id: id,
              slug: id,
              title: const Bilingual('T', 'T'),
              summary: const Bilingual('', ''),
              category: 'healthcare',
              verificationStatus: 'verified',
            ),
          ),
      ];
}

class FakePlans extends PlanController {
  @override
  Future<List<ActionPlan>> build() async => [
        ActionPlan(id: 'p1', title: const Bilingual('A', 'A'), tasks: [
          PlanTask(
            id: 't',
            title: const Bilingual('t', 't'),
            status: TaskStatus.pending,
            priority: TaskPriority.low,
            sortOrder: 0,
          ),
        ]),
      ];
}

Widget host(FakeAuth auth, {Locale locale = const Locale('en')}) => ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        savedControllerProvider.overrideWith(FakeSaved.new),
        planControllerProvider.overrideWith(FakePlans.new),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ProfileScreen(),
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(420, 1800)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('shows the person, their activity and the settings', (tester) async {
    await tester.pumpWidget(host(FakeAuth()));
    await tester.pumpAndSettle();

    expect(find.text('Rahima Begum'), findsOneWidget);
    expect(find.text('Rangpur'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // saved
    expect(find.text('1'), findsOneWidget); // plans in progress
    expect(find.text('0'), findsOneWidget); // finished
    expect(find.text('Government helpline 333'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choosing a text size stores it', (tester) async {
    await tester.pumpWidget(host(FakeAuth()));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(ProfileScreen)));
    expect(container.read(textSizeProvider), TextSize.normal);

    await tester.tap(find.text('Larger'));
    await tester.pumpAndSettle();
    expect(container.read(textSizeProvider), TextSize.larger);
  });

  testWidgets('sign out asks first; cancel keeps you signed in', (tester) async {
    final auth = FakeAuth();
    await tester.pumpWidget(host(auth));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.loggedOut, isFalse);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(auth.loggedOut, isTrue);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 2200);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(FakeAuth(), locale: const Locale('bn')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
