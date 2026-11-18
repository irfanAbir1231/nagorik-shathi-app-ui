import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shebar_janala_app/core/ui/theme.dart';
import 'package:shebar_janala_app/features/opportunities/application/opportunity_providers.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/opportunities/presentation/opportunity_detail_screen.dart';
import 'package:shebar_janala_app/features/plans/application/plan_controller.dart';
import 'package:shebar_janala_app/features/plans/domain/plan.dart';
import 'package:shebar_janala_app/features/saved/application/saved_controller.dart';
import 'package:shebar_janala_app/features/saved/domain/saved.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class FakePlans extends PlanController {
  @override
  Future<List<ActionPlan>> build() async => const [];
}

class FakeSaved extends SavedController {
  @override
  Future<List<SavedItem>> build() async => const [];
}

Map<String, String> both(String en) => {'en': en, 'bn': 'বাংলা $en'};

final detail = OpportunityDetail.fromJson({
  'opportunity': {
    'id': 'o1',
    'slug': 'stipend',
    'title': 'Secondary school stipend',
    'titleBn': 'মাধ্যমিক উপবৃত্তি',
    'summary': 'Monthly support',
    'category': 'scholarship',
    'verificationStatus': 'unverified_sample',
    'benefitAmount': 700,
    'benefitPeriod': 'monthly',
    'deadline': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
    'description': 'A long description of the programme. ' * 20,
    'benefits': 'Money every month.',
    'processingTimeDays': '30 days',
    'applicationProcess': [
      {'step': 1, ...both('Visit the school office')},
      {'step': 2, ...both('Fill in the form')},
    ],
  },
  'organization': {
    'name': 'Education Directorate',
    'contactPhone': '+880 2-1234567',
    'address': 'Dhaka',
  },
  'eligibility': {
    'outcome': 'eligible',
    'score': 85,
    'matched': [
      {'reason': both('You are a student')},
    ],
    'failed': [],
    'unknown': [
      {'reason': both('Family income not given')},
    ],
  },
  'confidence': {'band': 'medium', 'score': 60, 'reasons': [both('Sample data')]},
  'documents': [
    {'name': 'Birth certificate', 'required': true, 'tip': 'Bring the original'},
    {'name': 'Photo', 'required': false},
  ],
});

Widget host(Locale locale) => ProviderScope(
      overrides: [
        opportunityDetailProvider.overrideWith((ref, slug) async => detail),
        planControllerProvider.overrideWith(FakePlans.new),
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
        home: const OpportunityDetailScreen(slug: 'stipend'),
      ),
    );

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(420, 4000)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('shows the hero, key facts, verdict and sections', (tester) async {
    await tester.pumpWidget(host(const Locale('en')));
    await settle(tester);

    expect(find.text('Secondary school stipend'), findsWidgets);
    expect(find.text('Sample data, not yet verified'), findsOneWidget);
    expect(find.text('৳700 / month'), findsOneWidget);
    expect(find.text('5 days left'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
    expect(find.text('You may qualify'), findsOneWidget);
    expect(find.text('1 of 2 conditions match'), findsOneWidget);
    expect(find.text('Fill in the form'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Optional'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Make a plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long descriptions collapse behind "Read more"', (tester) async {
    await tester.pumpWidget(host(const Locale('en')));
    await settle(tester);

    await tester.tap(find.text('Read more'));
    await settle(tester);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 5000);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(const Locale('bn')));
    await settle(tester);
    expect(find.text('মাধ্যমিক উপবৃত্তি'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
