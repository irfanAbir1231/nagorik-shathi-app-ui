import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shebar_janala_app/features/auth/application/auth_controller.dart';
import 'package:shebar_janala_app/features/auth/domain/auth_user.dart';
import 'package:shebar_janala_app/features/home/application/home_providers.dart';
import 'package:shebar_janala_app/features/home/home_screen.dart';
import 'package:shebar_janala_app/features/opportunities/application/opportunity_providers.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/plans/application/plan_controller.dart';
import 'package:shebar_janala_app/features/plans/domain/plan.dart';
import 'package:shebar_janala_app/features/saved/application/saved_controller.dart';
import 'package:shebar_janala_app/features/saved/domain/saved.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class FakeAuth extends AuthController {
  @override
  Future<AuthUser?> build() async =>
      const AuthUser(id: 'u1', name: 'Rahima', phone: '01712345678', role: 'citizen', language: 'en', district: 'Dhaka');
}

class FakePlans extends PlanController {
  FakePlans(this.plans);
  final List<ActionPlan> plans;
  @override
  Future<List<ActionPlan>> build() async => plans;
}

class FakeSaved extends SavedController {
  FakeSaved(this.items);
  final List<SavedItem> items;
  @override
  Future<List<SavedItem>> build() async => items;
}

OpportunitySummary programme(String slug, {DateTime? deadline}) => OpportunitySummary(
      id: slug,
      slug: slug,
      title: Bilingual('Title $slug', ''),
      summary: const Bilingual('Summary', ''),
      category: 'scholarship',
      verificationStatus: 'verified',
      benefitAmount: 700,
      benefitPeriod: 'monthly',
      deadline: deadline,
      eligibility: const EligibilitySummary(outcome: EligibilityOutcome.eligible, score: 90),
    );

PlanTask task(String id, TaskStatus status) => PlanTask(
      id: id,
      title: Bilingual('Get $id', ''),
      status: status,
      priority: TaskPriority.medium,
      sortOrder: id.codeUnitAt(0),
    );

Widget host({
  List<ActionPlan> plans = const [],
  List<SavedItem> saved = const [],
  Locale locale = const Locale('en'),
}) =>
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(FakeAuth.new),
        planControllerProvider.overrideWith(() => FakePlans(plans)),
        savedControllerProvider.overrideWith(() => FakeSaved(saved)),
        recommendedOpportunitiesProvider.overrideWith((ref) async => [programme('rec-1')]),
        closingSoonProvider.overrideWith(
          (ref) async => [programme('close-1', deadline: DateTime.now().add(const Duration(days: 3)))],
        ),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeScreen(),
      ),
    );

/// Lets the fake futures resolve. Not pumpAndSettle: skeletons pulse forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    // Tall enough that every section is built.
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(420, 2600)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('shows the greeting, sections and programme cards', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    expect(find.text('Rahima'), findsOneWidget);
    expect(find.text('Dhaka'), findsOneWidget);
    expect(find.text('Browse by category'), findsOneWidget);
    expect(find.text('Closing soon'), findsOneWidget);
    expect(find.text('3 days left'), findsOneWidget);
    expect(find.text('Programmes for you'), findsOneWidget);
    expect(find.text('Title rec-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with nothing saved, invites the citizen to ask', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);
    expect(find.text('Find help you qualify for'), findsOneWidget);
  });

  testWidgets('with saved programmes but no plan, shows the saved count', (tester) async {
    final item = SavedItem(id: 's1', status: SavedStatus.interested, opportunity: programme('saved-1'));
    await tester.pumpWidget(host(saved: [item, item]));
    await settle(tester);
    expect(find.text('2 programmes saved'), findsOneWidget);
  });

  testWidgets('an unfinished plan shows progress and the next step', (tester) async {
    final plan = ActionPlan(
      id: 'p1',
      title: const Bilingual('Stipend application', ''),
      tasks: [task('a', TaskStatus.done), task('b', TaskStatus.pending), task('c', TaskStatus.pending)],
    );
    await tester.pumpWidget(host(plans: [plan]));
    await settle(tester);

    expect(find.text('Continue your plan'), findsOneWidget);
    expect(find.text('Stipend application'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('Next: Get b'), findsOneWidget);
  });

  testWidgets('a finished plan is not shown as the one to continue', (tester) async {
    final plan = ActionPlan(id: 'p1', title: const Bilingual('Done plan', ''), tasks: [task('a', TaskStatus.done)]);
    await tester.pumpWidget(host(plans: [plan]));
    await settle(tester);
    expect(find.text('Continue your plan'), findsNothing);
  });

  testWidgets('"More" reveals the remaining categories', (tester) async {
    await tester.pumpWidget(host());
    await settle(tester);

    expect(find.text('Research'), findsNothing);
    await tester.tap(find.text('More'));
    await settle(tester);
    expect(find.text('Research'), findsOneWidget);
    expect(find.text('Less'), findsOneWidget);
  });

  testWidgets('renders in Bangla without layout errors', (tester) async {
    await tester.pumpWidget(host(locale: const Locale('bn')));
    await settle(tester);
    expect(find.text('বিষয় অনুযায়ী খুঁজুন'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 3200);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(locale: const Locale('bn')));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });

  test('daysUntil counts calendar days', () {
    final now = DateTime(2026, 11, 17, 23, 30);
    expect(daysUntil(DateTime(2026, 11, 17, 8), now: now), 0);
    expect(daysUntil(DateTime(2026, 11, 18, 0, 5), now: now), 1);
    expect(daysUntil(DateTime(2026, 11, 16), now: now), -1);
  });
}
