import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shebar_janala_app/core/ui/theme.dart';
import 'package:shebar_janala_app/features/chat/application/chat_controller.dart';
import 'package:shebar_janala_app/features/chat/domain/chat.dart';
import 'package:shebar_janala_app/features/chat/presentation/chat_screen.dart';
import 'package:shebar_janala_app/features/opportunities/domain/opportunity.dart';
import 'package:shebar_janala_app/features/voice/application/voice_providers.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

/// Holds a fixed conversation and records what is sent.
class FakeChat extends ChatController {
  FakeChat(this.initial);
  final ChatState initial;
  final sent = <String>[];

  @override
  ChatState build() => initial;

  @override
  Future<void> send(String text, {String? locale}) async => sent.add(text);
}

final now = DateTime.now();

final conversation = ChatState(conversationId: 'c1', messages: [
  ChatMessage(id: 'u1', role: ChatRole.user, text: 'I am a farmer', createdAt: now),
  ChatMessage(
    id: 'a1',
    role: ChatRole.assistant,
    text: 'Here is a programme for you.',
    createdAt: now,
    engine: 'simulated',
    opportunities: const [
      ChatOpportunity(
        slug: 'seed-support',
        title: Bilingual('Seed support', 'বীজ সহায়তা'),
        outcome: EligibilityOutcome.eligible,
        isUnverified: true,
        benefitAmount: 2000,
        benefitPeriod: 'one_time',
        nextStep: Bilingual('Visit the agriculture office', 'কৃষি অফিসে যান'),
      ),
    ],
  ),
  ChatMessage(id: 'local-1', role: ChatRole.user, text: 'And for my son?', createdAt: now, state: SendState.failed),
]);

Widget host(FakeChat chat, {Locale locale = const Locale('en')}) => ProviderScope(
      overrides: [
        chatControllerProvider.overrideWith(() => chat),
        canSpeakProvider.overrideWith((ref, language) async => false),
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
        home: const ChatScreen(),
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

  testWidgets('an empty chat shows suggestions; tapping one sends it', (tester) async {
    final chat = FakeChat(const ChatState());
    await tester.pumpWidget(host(chat));
    await tester.pumpAndSettle();

    expect(find.text('How can we help?'), findsOneWidget);
    expect(find.byTooltip('Speak'), findsOneWidget); // mic while the box is empty
    await tester.tap(find.text('I am a farmer. What support is there?'));
    expect(chat.sent, ['I am a farmer. What support is there?']);
  });

  testWidgets('the mic turns into send once there is text', (tester) async {
    final chat = FakeChat(const ChatState());
    await tester.pumpWidget(host(chat));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Speak'), findsNothing);
    await tester.tap(find.byTooltip('Send'));
    expect(chat.sent, ['Hello']);
  });

  testWidgets('a conversation shows the day, engine, programme card and a failed message', (tester) async {
    await tester.pumpWidget(host(FakeChat(conversation)));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Simulated AI'), findsOneWidget);
    expect(find.text('Seed support'), findsOneWidget);
    expect(find.text('৳2,000 one-time'), findsOneWidget);
    expect(find.text('You may qualify'), findsOneWidget);
    expect(find.text('Sample data, not yet verified'), findsOneWidget);
    expect(find.textContaining('Visit the agriculture office'), findsOneWidget);
    expect(find.text('Not sent. Tap to try again.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a small phone with large Bangla text does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 1800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(FakeChat(conversation), locale: const Locale('bn')));
    await tester.pumpAndSettle();
    expect(find.text('বীজ সহায়তা'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(FakeChat(const ChatState()), locale: const Locale('bn')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
