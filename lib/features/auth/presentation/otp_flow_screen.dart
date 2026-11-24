import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/network/api_result.dart';
import '../../../core/providers.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/phone.dart';
import 'auth_widgets.dart';

/// The three sign-in routes that start with an SMS code. They share one screen
/// because they are the same two steps: prove you own the number, then finish.
enum OtpFlow {
  /// New account: code, name, PIN.
  register(OtpPurpose.register),

  /// Forgotten PIN: code, new PIN, then signed in.
  resetPin(OtpPurpose.resetPin),

  /// Recovery when the PIN is forgotten or the account is temporarily locked:
  /// the code alone signs you in (BDS 10.2.5 asks for a non-punitive route).
  otpLogin(OtpPurpose.login);

  const OtpFlow(this.purpose);
  final OtpPurpose purpose;
}

class OtpFlowScreen extends ConsumerStatefulWidget {
  const OtpFlowScreen({super.key, required this.flow});
  final OtpFlow flow;

  @override
  ConsumerState<OtpFlowScreen> createState() => _OtpFlowScreenState();
}

class _OtpFlowScreenState extends ConsumerState<OtpFlowScreen> {
  final _phoneForm = GlobalKey<FormState>();
  final _detailsForm = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();

  OtpIssue? _issue; // non-null once a code has been sent: that is "step 2"
  String? _language;
  bool _busy = false;
  String? _error;
  String? _requestId;
  String? _codeError;
  int _secondsLeft = 0;
  Timer? _ticker;

  bool get _needsName => widget.flow == OtpFlow.register;
  bool get _needsPin => widget.flow != OtpFlow.otpLogin;

  @override
  void dispose() {
    _ticker?.cancel();
    for (final c in [_phone, _code, _name, _pin, _pin2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _startCountdown(Duration d) {
    _ticker?.cancel();
    setState(() => _secondsLeft = d.inSeconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 1 << 30));
      if (_secondsLeft == 0) t.cancel();
    });
  }

  void _fail(AppLocalizations l, Err<dynamic> e) {
    setState(() {
      _busy = false;
      _error = errorText(l, e);
      _requestId = e.requestId;
    });
  }

  Future<void> _sendCode(AppLocalizations l, {bool resend = false}) async {
    if (!resend && !_phoneForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).requestOtp(_phone.text, widget.flow.purpose);
    if (!mounted) return;
    switch (result) {
      case Ok<OtpIssue>(:final data):
        setState(() {
          _busy = false;
          _issue = data;
          _code.clear();
        });
        _startCountdown(data.resendAfter);
      case final Err<OtpIssue> e:
        _fail(l, e);
    }
  }

  Future<void> _finish(AppLocalizations l) async {
    // The code boxes are not a form field, so they are checked here.
    final codeOk = isValidOtp(_code.text);
    setState(() => _codeError = codeOk ? null : l.errCode);
    final formOk = _detailsForm.currentState!.validate();
    if (!codeOk || !formOk) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    final lang = _language ?? Localizations.localeOf(context).languageCode;
    final ApiResult<AuthUser> result = switch (widget.flow) {
      OtpFlow.register =>
        await auth.register(phone: _phone.text, code: _code.text, name: _name.text, pin: _pin.text, language: lang),
      OtpFlow.resetPin => await auth.resetPin(phone: _phone.text, code: _code.text, pin: _pin.text),
      OtpFlow.otpLogin => await auth.loginWithCode(phone: _phone.text, code: _code.text),
    };
    if (!mounted) return;
    // On success the router leaves this screen by itself; only failures stay.
    if (result is Err<AuthUser>) _fail(l, result);
  }

  String _title(AppLocalizations l) => switch (widget.flow) {
        OtpFlow.register => l.registerTitle,
        OtpFlow.resetPin => l.resetPinTitle,
        OtpFlow.otpLogin => l.otpLoginTitle,
      };

  String _finishLabel(AppLocalizations l) => switch (widget.flow) {
        OtpFlow.register => l.finishRegister,
        OtpFlow.resetPin => l.finishResetPin,
        OtpFlow.otpLogin => l.finishOtpLogin,
      };

  String _subtitle(AppLocalizations l) => switch (widget.flow) {
        OtpFlow.register => l.registerSubtitle,
        OtpFlow.resetPin => l.resetPinSubtitle,
        OtpFlow.otpLogin => l.otpLoginSubtitle,
      };

  IconData get _icon => switch (widget.flow) {
        OtpFlow.register => Icons.person_add_alt_1_rounded,
        OtpFlow.resetPin => Icons.lock_reset_rounded,
        OtpFlow.otpLogin => Icons.sms_rounded,
      };

  void _changeNumber() => setState(() {
        _issue = null;
        _error = null;
        _codeError = null;
        _ticker?.cancel();
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final onCode = _issue != null;

    return Scaffold(
      appBar: AppBar(flexibleSpace: const AppBarBackdrop(), actions: const [Padding(padding: EdgeInsets.only(right: 12), child: LanguageSwitch())]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IllustratedBadge(icon: _icon, color: AppColors.primary, size: 84),
                ),
                const SizedBox(height: 16),
                Text(
                  onCode ? l.enterCodeTitle : _title(l),
                  style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  onCode ? l.codeSentTo(_phone.text.trim()) : _subtitle(l),
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (onCode)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: _busy ? null : _changeNumber,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l.changeNumber),
                    ),
                  ),
                const SizedBox(height: 16),
                StepIndicator(step: onCode ? 2 : 1, total: 2),
                const SizedBox(height: 20),
                if (onCode) _detailsStep(l) else _phoneStep(l),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  AuthErrorBox(message: _error!, requestId: _requestId),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep(AppLocalizations l) {
    final theme = Theme.of(context);
    return Form(
      key: _phoneForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: _phone,
          autofocus: true,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendCode(l),
          decoration: InputDecoration(
            labelText: l.phoneLabel,
            hintText: l.phoneHint,
            prefixIcon: const Icon(Icons.phone_iphone_rounded),
          ),
          validator: (v) => (v == null || !isValidBdPhone(v)) ? l.errPhone : null,
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.sms_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.codeWillBeSent,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : () => _sendCode(l), child: _label(l.sendCode)),
      ]),
    );
  }

  Widget _detailsStep(AppLocalizations l) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final issue = _issue!;
    final devCode = kDebugMode ? issue.devCode : null; // never surfaced in release builds

    return Form(
      key: _detailsForm,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OtpBoxes(
          controller: _code,
          label: l.codeLabel,
          errorText: _codeError,
          // Code sign-in has nothing else to fill in, so finish straight away.
          onCompleted: () {
            if (_codeError != null) setState(() => _codeError = null);
            if (widget.flow == OtpFlow.otpLogin && !_busy) _finish(l);
          },
        ),
        if (devCode != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: () => _code.text = devCode, child: Text(l.devCodeLabel(devCode))),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: (_busy || _secondsLeft > 0) ? null : () => _sendCode(l, resend: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_secondsLeft > 0 ? l.resendIn(_secondsLeft) : l.resendCode),
          ),
        ),
        if (_needsName) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.nameLabel,
              helperText: l.nameHelp,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            validator: (v) => (v == null || v.trim().length < 2) ? l.errName : null,
          ),
        ],
        if (_needsPin) ...[
          const SizedBox(height: 20),
          Text(l.choosePinTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          PinField(
            controller: _pin,
            label: l.newPinLabel,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || !isValidPin(v)) ? l.errPin : (isGuessablePin(v) ? l.errPinWeak : null),
          ),
          const SizedBox(height: 14),
          PinField(
            controller: _pin2,
            label: l.confirmPinLabel,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _finish(l),
            validator: (v) => v != _pin.text ? l.pinMismatch : null,
          ),
        ],
        if (_needsName) ...[
          const SizedBox(height: 20),
          Text(l.chooseLanguage, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'bn', label: Text('বাংলা')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {_language ?? locale},
            onSelectionChanged: (s) => setState(() => _language = s.first),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(onPressed: _busy ? null : () => _finish(l), child: _label(_finishLabel(l))),
      ]),
    );
  }

  Widget _label(String text) => _busy
      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
      : Text(text);
}
