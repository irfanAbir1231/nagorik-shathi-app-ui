import 'package:flutter_tts/flutter_tts.dart';

/// Reads text aloud with the phone's own voice.
///
/// Android often ships with no Bangla voice, and then it either stays silent or
/// reads Bangla with an English voice, which sounds like the feature works while
/// being unintelligible. So availability is checked per language, and the UI
/// offers no speaker button where no proper voice exists.
abstract class Speaker {
  Future<bool> canSpeak(String language);
  Future<void> speak(String text, String language, {required void Function() onDone});
  Future<void> stop();
}

class DeviceSpeaker implements Speaker {
  DeviceSpeaker({FlutterTts? tts}) : _tts = tts ?? FlutterTts();
  final FlutterTts _tts;

  static String _tag(String language) => language == 'bn' ? 'bn-BD' : 'en-US';

  @override
  Future<bool> canSpeak(String language) async {
    try {
      final available = await _tts.isLanguageAvailable(_tag(language));
      // Android returns true/false; some engines return 0/1 style ints.
      return available == true || available == 1;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speak(String text, String language, {required void Function() onDone}) async {
    await _tts.stop();
    await _tts.setLanguage(_tag(language));
    _tts.setCompletionHandler(onDone);
    _tts.setCancelHandler(onDone);
    _tts.setErrorHandler((_) => onDone());
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
