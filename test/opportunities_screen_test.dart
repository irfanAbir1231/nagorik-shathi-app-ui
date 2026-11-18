import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shebar_janala_app/core/network/api_result.dart';
import 'package:shebar_janala_app/core/providers.dart';
import 'package:shebar_janala_app/core/ui/theme.dart';
import 'package:shebar_janala_app/features/opportunities/data/opportunity_repository.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/opportunities/presentation/opportunities_screen.dart';
import 'package:shebar_janala_app/features/saved/application/saved_controller.dart';
import 'package:shebar_janala_app/features/saved/domain/saved.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class MockRepo extends Mock implements OpportunityRepository {}

class FakeSaved extends SavedController {
  @override
  Future<List<SavedItem>> build() async => const [];
}

OpportunitySummary programme(String slug, {String category = 'healthcare'}) => OpportunitySummary(
      id: slug,
      slug: slug,
      title: Bilingual('Title $slug', 'শিরোনাম $slug'),
      summary: const Bilingual('A short summary', 'সংক্ষিপ্ত বিবরণ'),
      category: category,
      verificationStatus: 'verified',
      benefitAmount: 1500,
      benefitPeriod: 'monthly',
      eligibility: const EligibilitySummary(outcome: EligibilityOutcome.eligible, score: 80),
    );

const counts = {'healthcare': 7, 'scholarship': 3};

/// Answers every list call with [items]; records the last outcome filter.
MockRepo repoWith(List<OpportunitySummary> Function(String? outcome) items) {
  final repo = MockRepo();
  when(() => repo.list(
        query: any(named: 'query'),
        category: any(named: 'category'),
        outcome: any(named: 'outcome'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer((inv) async {
    final outcome = inv.namedArguments[#outcome] as String?;
    return Ok(OpportunityPage(items(outcome), categoryCounts: counts));
  });
  return repo;
}

Widget host(MockRepo repo, {Locale locale = const Locale('en')}) => ProviderScope(
      overrides: [
        opportunityRepositoryProvider.overrideWithValue(repo),
        savedControllerProvider.overrideWith(FakeSaved.new),
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
        home: const OpportunitiesScreen(),
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(420, 1600)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('shows cards with amount and verdict, counts on chips and a result count', (tester) async {
    // Wide, so the chip row (which only builds what is on screen) reaches Healthcare.
    tester.view.physicalSize = const Size(1600, 1600);
    await tester.pumpWidget(host(repoWith((_) => [programme('a'), programme('b'), programme('c')])));
    await settle(tester);

    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('৳1,500 / month'), findsNWidgets(3));
    expect(find.text('You may qualify'), findsNWidgets(3));
    expect(find.text('All · 10'), findsOneWidget);
    expect(find.text('Healthcare · 7'), findsOneWidget);
    expect(find.text('3 programmes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"I may qualify" asks the server for eligible programmes and hides catalogue counts', (tester) async {
    String? lastOutcome;
    await tester.pumpWidget(host(repoWith((outcome) {
      lastOutcome = outcome;
      return [programme('a')];
    })));
    await settle(tester);

    await tester.tap(find.text('I may qualify'));
    await settle(tester);

    expect(lastOutcome, 'eligible');
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Healthcare · 7'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('no results shows the empty state, and "Clear filters" resets', (tester) async {
    await tester.pumpWidget(host(repoWith((outcome) => outcome == 'eligible' ? const [] : [programme('a')])));
    await settle(tester);

    await tester.tap(find.text('I may qualify'));
    await settle(tester);
    expect(find.text('No programmes found.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
    await settle(tester);
    expect(find.text('Title a'), findsOneWidget);
    expect(find.text('Clear filters'), findsNothing);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(repoWith((_) => [programme('a'), programme('b')]), locale: const Locale('bn')));
    await settle(tester);
    expect(find.text('শিরোনাম a'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
