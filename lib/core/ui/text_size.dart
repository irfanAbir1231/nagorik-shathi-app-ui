import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/language.dart' show preferenceStorageProvider;
import '../storage/app_cache.dart';

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

  /// Read synchronously, so the first frame already has the chosen size:
  /// no jump in text size a moment after launch.
  @override
  TextSize build() {
    final match = _parse(ref.read(appCacheProvider).pref(_key));
    if (match != null) return match;
    _migrate();
    return TextSize.normal;
  }

  static TextSize? _parse(String? saved) => TextSize.values.where((s) => s.name == saved).firstOrNull;

  /// Earlier versions kept the choice in the keystore: carry it over once.
  Future<void> _migrate() async {
    try {
      final match = _parse(await ref.read(preferenceStorageProvider).read(key: _key));
      if (!_picked && match != null) {
        state = match;
        ref.read(appCacheProvider).setPref(_key, match.name);
      }
    } catch (_) {
      // No storage (tests, or a broken keystore): normal size.
    }
  }

  Future<void> set(TextSize size) async {
    _picked = true;
    state = size;
    ref.read(appCacheProvider).setPref(_key, size.name);
  }
}

final textSizeProvider = NotifierProvider<TextSizeController, TextSize>(
  TextSizeController.new,
);
