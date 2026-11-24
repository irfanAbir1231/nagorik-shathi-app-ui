import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/app_cache.dart';

/// Where the language choice was kept by earlier versions (read once, to carry
/// it over). A provider so tests can replace it.
final preferenceStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

/// The language picked on this phone ('bn' or 'en'), or null if never picked.
///
/// It wins over the account's language: someone who switches to English on the
/// sign-in screen should not be put back into Bangla by signing in.
class LanguageController extends Notifier<String?> {
  static const _key = 'sj_language';

  /// Read synchronously, so the first frame is already in the chosen
  /// language: no flash of Bangla before switching to English.
  @override
  String? build() {
    final saved = ref.read(appCacheProvider).pref(_key);
    if (saved == 'bn' || saved == 'en') return saved;
    _migrate();
    return null;
  }

  /// Earlier versions kept the choice in the keystore: carry it over once.
  Future<void> _migrate() async {
    try {
      final saved = await ref.read(preferenceStorageProvider).read(key: _key);
      // Only if nothing was picked while reading.
      if (state == null && (saved == 'bn' || saved == 'en')) {
        state = saved;
        ref.read(appCacheProvider).setPref(_key, saved);
      }
    } catch (_) {
      // No storage (tests, or a broken keystore): use the default language.
    }
  }

  Future<void> set(String language) async {
    state = language;
    ref.read(appCacheProvider).setPref(_key, language);
  }
}

final languageProvider = NotifierProvider<LanguageController, String?>(LanguageController.new);
