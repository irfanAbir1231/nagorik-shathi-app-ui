import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shebar_janala_app/core/network/api_result.dart';
import 'package:shebar_janala_app/core/ui/theme.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/plans/application/plan_controller.dart';
import 'package:shebar_janala_app/features/plans/domain/plan.dart';
import 'package:shebar_janala_app/features/plans/presentation/plan_detail_screen.dart';
import 'package:shebar_janala_app/features/saved/application/saved_controller.dart';
import 'package:shebar_janala_app/features/saved/domain/saved.dart';
import 'package:shebar_janala_app/features/saved/presentation/my_list_screen.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class FakeSaved extends SavedController {
  FakeSaved(this.items);
  final List<SavedItem> items;
  @override
  Future<List<SavedItem>> build() async => items;
}

/// Ticks tasks locally, as the real controller does before the server answers.
class FakePlans extends PlanController {
  FakePlans(this.plans);
  final List<ActionPlan> plans;
  @override
  Future<List<ActionPlan>> build() async => plans;

  @override
  Future<Err<dynamic>?> setTaskStatus(String planId, String taskId, TaskStatus status) async {
    state = AsyncData([for (final p in state.value!) p.id == planId ? p.withTask(taskId, status) : p]);
    return null;
  }
}

SavedItem saved(String id, SavedStatus status) => SavedItem(
      id: id,
      status: status,
      opportunity: OpportunitySummary(
        id: 'o$id',
        slug: 'o$id',
        title: Bilingual('Programme $id', 'কর্মসূচি $id'),
        summary: const Bilingual('', ''),
        category: 'healthcare',
        verificationStatus: 'verified',
        benefitAmount: 500,
        benefitPeriod: 'monthly',
      ),
    );

PlanTask task(String id, TaskStatus status, {DateTime? due}) => PlanTask(
      id: id,
      title: Bilingual('Task $id', 'কাজ $id'),
      status: status,
      priority: TaskPriority.high,
      sortOrder: id.codeUnitAt(0),
      dueDate: due,
    );

final unfinished = ActionPlan(
  id: 'p1',
  title: const Bilingual('Allowance plan', 'ভাতার পরিকল্পনা'),
  tasks: [
    task('a', TaskStatus.done),
    task('b', TaskStatus.pending, due: DateTime.now().subtract(const Duration(days: 2))),
  ],
);

final finished = ActionPlan(
  id: 'p2',
  title: const Bilingual('Finished plan', 'শেষ পরিকল্পনা'),
  tasks: [task('a', TaskStatus.done)],
);

Widget host(Widget screen, {List<SavedItem> items = const [], List<ActionPlan> plans = const [], Locale? locale}) =>
    ProviderScope(
      overrides: [
        savedControllerProvider.overrideWith(() => FakeSaved(items)),
        planControllerProvider.overrideWith(() => FakePlans(plans)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale ?? const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: screen,
      ),
    );

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(420, 1400)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('My list: counts in the tabs, journey stage on each card', (tester) async {
    await tester.pumpWidget(host(
      const MyListScreen(),
      items: [saved('1', SavedStatus.applied), saved('2', SavedStatus.interested)],
      plans: [unfinished],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Saved · 2'), findsOneWidget);
    expect(find.text('Plans · 1'), findsOneWidget);
    expect(find.text('Step 4 of 7'), findsOneWidget); // applied
    expect(find.text('Step 1 of 7'), findsOneWidget); // interested
    expect(find.text('Applied · 1'), findsOneWidget); // status filter chip
  });

  testWidgets('Plans tab: unfinished first with its next step, finished marked completed', (tester) async {
    await tester.pumpWidget(host(const MyListScreen(initialTab: 1), plans: [finished, unfinished]));
    await tester.pumpAndSettle();

    expect(find.text('Next: Task b'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    final first = tester.getTopLeft(find.text('Allowance plan')).dy;
    final second = tester.getTopLeft(find.text('Finished plan')).dy;
    expect(first, lessThan(second));
  });

  testWidgets('empty saved list offers a way to browse', (tester) async {
    await tester.pumpWidget(host(const MyListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Browse all programmes'), findsOneWidget);
  });

  testWidgets('plan detail: overdue step, and finishing the last one celebrates', (tester) async {
    await tester.pumpWidget(host(const PlanDetailScreen(planId: 'p1'), plans: [unfinished]));
    await tester.pumpAndSettle();

    expect(find.text('To do · 1'), findsOneWidget);
    expect(find.text('Done · 1'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);

    await tester.tap(find.text('Task b'));
    await tester.pumpAndSettle();
    expect(find.text('All steps done!'), findsOneWidget);
    expect(find.text('Done · 2'), findsOneWidget);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    const bn = Locale('bn');

    await tester.pumpWidget(host(const MyListScreen(), items: [saved('1', SavedStatus.underReview)], locale: bn));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(const MyListScreen(initialTab: 1), plans: [unfinished, finished], locale: bn));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(const PlanDetailScreen(planId: 'p1'), plans: [unfinished], locale: bn));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
