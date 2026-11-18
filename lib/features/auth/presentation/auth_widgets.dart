import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/language.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';

/// বাংলা | EN switch. Each label is written in its own language so anyone can
/// find theirs, whatever the screen is currently showing.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.onDark = false});

  /// Draw for a dark (green) background.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final fg = onDark ? Colors.white : AppColors.ink;

    Widget option(String code, String label) {
      final selected = current == code;
      return Semantics(
        button: true,
        selected: selected,
        label: '${l.chooseLanguage}: $label',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => ref.read(languageProvider.notifier).set(code),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? (onDark ? Colors.white : AppColors.primary) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? (onDark ? AppColors.primary : Colors.white) : fg,
                  ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: onDark ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [option('bn', 'বাংলা'), option('en', 'EN')]),
    );
  }
}

/// A PIN field with a show/hide button. Never offered to autofill, suggestions
/// or the clipboard history.
class PinField extends StatefulWidget {
  const PinField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  var _visible = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: !_visible,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _visible ? l.hidePin : l.showPin,
          icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// A red box for a failed attempt, with the support reference when there is one.
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox({super.key, required this.message, this.requestId});
  final String message;
  final String? requestId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
              if (requestId != null) Text(l.errReference(requestId!), style: theme.textTheme.bodySmall),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// "Step 1 of 2" with a segmented bar.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        l.stepOf(step, total),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
      const SizedBox(height: 6),
      ExcludeSemantics(
        child: Row(children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 6,
                decoration: BoxDecoration(
                  color: i <= step ? AppColors.primary : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }
}

/// Six boxes for a one-time code. A real (invisible) text field sits on top,
/// so the keyboard, SMS autofill, paste and screen readers all work normally;
/// the boxes only draw what it holds.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({super.key, required this.controller, required this.label, this.onCompleted, this.errorText});
  final TextEditingController controller;
  final String label;
  final VoidCallback? onCompleted;
  final String? errorText;

  static const length = 6;

  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final _focus = FocusNode();

  var _lastLength = 0;

  @override
  void initState() {
    super.initState();
    _lastLength = widget.controller.text.length;
    widget.controller.addListener(_textChanged);
    _focus.addListener(_redraw);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_textChanged);
    _focus.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  void _textChanged() {
    _redraw();
    final length = widget.controller.text.length;
    // Fire once, when the last digit arrives (typed, pasted or autofilled).
    if (length == OtpBoxes.length && _lastLength != OtpBoxes.length) widget.onCompleted?.call();
    _lastLength = length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = widget.controller.text;
    final hasError = widget.errorText != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        ExcludeSemantics(
          child: Row(children: [
            for (var i = 0; i < OtpBoxes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      width: (_focus.hasFocus && i == text.length.clamp(0, OtpBoxes.length - 1)) ? 2 : 1,
                      color: hasError
                          ? AppColors.danger
                          : (_focus.hasFocus && i == text.length.clamp(0, OtpBoxes.length - 1))
                              ? AppColors.primary
                              : (i < text.length ? AppColors.primary.withValues(alpha: 0.5) : scheme.outlineVariant),
                    ),
                  ),
                  child: Text(
                    i < text.length ? text[i] : '',
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink),
                  ),
                ),
              ),
            ],
          ]),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            alwaysIncludeSemantics: true,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(OtpBoxes.length),
              ],
              showCursor: false,
              enableInteractiveSelection: false,
              decoration: InputDecoration.collapsed(hintText: widget.label).copyWith(filled: false),
            ),
          ),
        ),
      ]),
      if (hasError) ...[
        const SizedBox(height: 6),
        Text(widget.errorText!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger)),
      ],
    ]);
  }
}

/// The app's mark: a gold rounded square holding a window, for "Shebar Janala"
/// (window to services).
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.sun,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(Icons.window_rounded, size: size * 0.55, color: AppColors.ink),
        ),
      );
}
