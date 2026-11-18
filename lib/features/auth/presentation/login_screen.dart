import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config.dart';
import '../../../core/i18n/error_text.dart';
import '../../../core/network/api_result.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_controller.dart';
import '../domain/auth_user.dart';
import '../domain/demo_accounts.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Debug builds (or a release built with DEMO_ACCOUNTS=true) prefill the seeded demo
  // citizen. The flag is a compile-time constant, so an ordinary release build
  // contains neither value.
  final _phone = TextEditingController(text: AppConfig.showDemoAccounts ? '01712345678' : null);
  final _pin = TextEditingController(text: AppConfig.showDemoAccounts ? '1234' : null);
  // Debug builds only: which seeded demo role is currently filled in.
  DemoAccount? _demo = AppConfig.showDemoAccounts ? demoAccounts.first : null;
  bool _busy = false;
  String? _error;
  String? _requestId;

  @override
  void dispose() {
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authControllerProvider.notifier).login(phone: _phone.text, pin: _pin.text);
    if (!mounted) return;
    // On success the router redirects; only failures stay on this screen.
    if (result is Err<AuthUser>) {
      setState(() {
        _busy = false;
        _error = errorText(l, result);
        _requestId = result.requestId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Header(),
            // The card rises into the header, so the form reads as one object.
            Transform.translate(
              offset: const Offset(0, -36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      _formCard(l, theme),
                      if (AppConfig.otpFlows) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(l.newHere, style: theme.textTheme.bodyLarge),
                            TextButton(onPressed: () => context.push('/register'), child: Text(l.createAccount)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.shield_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l.pinSafety,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ]),
                      if (AppConfig.showDemoAccounts) ...[
                        const SizedBox(height: 20),
                        _RolePicker(
                          selected: _demo,
                          onPicked: (a) => setState(() {
                            _demo = a;
                            _phone.text = a.phone;
                            _pin.text = a.pin;
                            _error = null;
                          }),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _formCard(AppLocalizations l, ThemeData theme) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.welcomeBack, style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink)),
              const SizedBox(height: 4),
              Text(l.signInSubtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: InputDecoration(
                  labelText: l.phoneLabel,
                  hintText: l.phoneHint,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.errRequired : null,
              ),
              const SizedBox(height: 14),
              PinField(
                controller: _pin,
                label: l.pinLabel,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(l),
                validator: (v) => (v == null || !RegExp(r'^\d{4,6}$').hasMatch(v)) ? l.errPin : null,
              ),
              if (AppConfig.otpFlows)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(onPressed: () => context.push('/forgot-pin'), child: Text(l.forgotPin)),
                )
              else
                const SizedBox(height: 12),
              if (_error != null) ...[
                AuthErrorBox(message: _error!, requestId: _requestId),
                const SizedBox(height: 14),
              ],
              FilledButton(
                onPressed: _busy ? null : () => _submit(l),
                child: _busy
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(l.signInButton),
              ),
              // These all need an SMS code; hidden when the backend cannot send one.
              if (AppConfig.otpFlows) ...[
                const SizedBox(height: 14),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(l.orDivider, style: theme.textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => context.push('/otp-login'),
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(l.signInWithCode),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return HeroBackdrop(
      radius: 36,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 12, 16, 64),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Align(alignment: AlignmentDirectional.centerEnd, child: LanguageSwitch(onDark: true)),
          const SizedBox(height: 12),
          const Align(alignment: AlignmentDirectional.centerStart, child: AppMark()),
          const SizedBox(height: 16),
          Text(l.appName, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            l.appTagline,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ]),
      ),
    );
  }
}

/// Debug-only role chooser: fills in a seeded account's phone number and PIN.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.selected, required this.onPicked});
  final DemoAccount? selected;
  final ValueChanged<DemoAccount> onPicked;

  Future<void> _open(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final picked = await showModalBottomSheet<DemoAccount>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.8),
          child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(l.demoChooseRole, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final a in demoAccounts)
              ListTile(
                leading: Icon(
                  a == selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: a == selected ? AppColors.primary : null,
                ),
                title: Text(a.role.of(locale)),
                subtitle: Text('${a.name}\n${a.phone} · ${a.detail.of(locale)}'),
                isThreeLine: true,
                onTap: () => Navigator.of(ctx).pop(a),
              ),
          ]),
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.science_outlined, size: 18, color: AppColors.warning),
          const SizedBox(width: 6),
          Expanded(child: Text(l.demoHeader, style: theme.textTheme.labelLarge?.copyWith(color: AppColors.warning))),
        ]),
        const SizedBox(height: 4),
        Text(l.demoPickHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: Colors.white),
          onPressed: () => _open(context),
          icon: const Icon(Icons.badge_outlined),
          label: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              selected == null ? l.demoChooseRole : '${selected!.role.of(locale)} · ${selected!.name}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ]),
    );
  }
}
