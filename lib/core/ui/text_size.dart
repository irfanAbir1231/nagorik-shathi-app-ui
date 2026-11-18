import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/language.dart' show preferenceStorageProvider;

/// The text sizes offered in Profile. Applied on top of the phone's own font
/// size setting, so it never makes text smaller than the person chose there.
enum TextSize {
  normal(1.0),
  large(1.15),
  larger(1.3);

  const TextSize(this.factor);
  final double factor;
}

class TextSizeController extends Notifier<TextSize> {
  static const _key = 'sj_text_size';
  var _picked = false;

  @override
  TextSize build() {
    _load();
    return TextSize.normal;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(preferenceStorageProvider).read(key: _key);
      final match = TextSize.values.where((s) => s.name == saved).firstOrNull;
      if (!_picked && match != null) state = match;
    } catch (_) {
      // No storage (tests, or a broken keystore): normal size.
    }
  }

  Future<void> set(TextSize size) async {
    _picked = true;
    state = size;
    try {
      await ref.read(preferenceStorageProvider).write(key: _key, value: size.name);
    } catch (_) {
      // Still applied for this session.
    }
  }
}

final textSizeProvider = NotifierProvider<TextSizeController, TextSize>(TextSizeController.new);
