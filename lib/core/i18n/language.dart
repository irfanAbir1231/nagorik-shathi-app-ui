import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the language choice is kept. A provider so tests can replace it.
final preferenceStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

/// The language picked on this phone ('bn' or 'en'), or null if never picked.
///
/// It wins over the account's language: someone who switches to English on the
/// sign-in screen should not be put back into Bangla by signing in.
class LanguageController extends Notifier<String?> {
  static const _key = 'sj_language';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final saved = await ref.read(preferenceStorageProvider).read(key: _key);
      // Only if nothing was picked while reading.
      if (state == null && (saved == 'bn' || saved == 'en')) state = saved;
    } catch (_) {
      // No storage (tests, or a broken keystore): use the default language.
    }
  }

  Future<void> set(String language) async {
    state = language;
    try {
      await ref.read(preferenceStorageProvider).write(key: _key, value: language);
    } catch (_) {
      // Still applied for this session.
    }
  }
}

final languageProvider = NotifierProvider<LanguageController, String?>(LanguageController.new);
