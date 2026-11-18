import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shebar_janala_app/core/network/api_result.dart';
import 'package:shebar_janala_app/core/providers.dart';
import 'package:shebar_janala_app/core/ui/theme.dart';
import 'package:shebar_janala_app/features/auth/application/auth_controller.dart';
import 'package:shebar_janala_app/features/auth/data/auth_repository.dart';
import 'package:shebar_janala_app/features/auth/domain/auth_user.dart';
import 'package:shebar_janala_app/features/auth/presentation/login_screen.dart';
import 'package:shebar_janala_app/features/auth/presentation/otp_flow_screen.dart';
import 'package:shebar_janala_app/l10n/generated/app_localizations.dart';

class MockRepo extends Mock implements AuthRepository {}

class FakeAuth extends AuthController {
  String? codeUsed;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<ApiResult<AuthUser>> loginWithCode({required String phone, required String code}) async {
    codeUsed = code;
    return const Err('OTP_INVALID', 'x');
  }
}

/// Uses the app's real locale logic, so the language switch can be tested.
Widget host(Widget screen, {List overrides = const []}) => ProviderScope(
      overrides: [...overrides],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: AppTheme.light(),
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: screen,
        ),
      ),
    );

void main() {
  setUpAll(() => registerFallbackValue(OtpPurpose.login));

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
  });
  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
    ..resetPhysicalSize()
    ..resetDevicePixelRatio());

  testWidgets('the language switch changes the sign-in screen language', (tester) async {
    await tester.pumpWidget(host(const LoginScreen(), overrides: [authControllerProvider.overrideWith(FakeAuth.new)]));
    await tester.pumpAndSettle();
    expect(find.text('আবার স্বাগতম'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('sign-in and sign-up fit a small phone with large Bangla text', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(host(const LoginScreen(), overrides: [authControllerProvider.overrideWith(FakeAuth.new)]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(host(
      const OtpFlowScreen(flow: OtpFlow.register),
      overrides: [authControllerProvider.overrideWith(FakeAuth.new)],
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the PIN can be shown and hidden', (tester) async {
    await tester.pumpWidget(host(const LoginScreen(), overrides: [authControllerProvider.overrideWith(FakeAuth.new)]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    TextField pin() => tester.widget<TextField>(find.byType(TextField).at(1));
    expect(pin().obscureText, isTrue);
    await tester.tap(find.byTooltip('Show PIN'));
    await tester.pump();
    expect(pin().obscureText, isFalse);
  });

  testWidgets('code sign-in: phone, then six boxes that submit when full', (tester) async {
    final repo = MockRepo();
    when(() => repo.requestOtp(any(), any()))
        .thenAnswer((_) async => const Ok(OtpIssue(resendAfter: Duration(seconds: 30))));
    final auth = FakeAuth();

    await tester.pumpWidget(host(
      const OtpFlowScreen(flow: OtpFlow.otpLogin),
      overrides: [authRepositoryProvider.overrideWithValue(repo), authControllerProvider.overrideWith(() => auth)],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 2'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '01712345678');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('We sent a 6-digit code to 01712345678.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pumpAndSettle();
    expect(auth.codeUsed, '123456');
    expect(find.text('That code is not right. Check it and try again.'), findsOneWidget);
  });

  testWidgets('registering with an incomplete code shows the code error', (tester) async {
    final repo = MockRepo();
    when(() => repo.requestOtp(any(), any()))
        .thenAnswer((_) async => const Ok(OtpIssue(resendAfter: Duration(seconds: 30))));

    await tester.pumpWidget(host(
      const OtpFlowScreen(flow: OtpFlow.register),
      overrides: [authRepositoryProvider.overrideWithValue(repo), authControllerProvider.overrideWith(FakeAuth.new)],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '01712345678');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '12');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 6-digit code.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
