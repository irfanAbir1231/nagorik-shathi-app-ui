import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

import '../domain/speech_input.dart';

/// Uses the phone's own speech recogniser (Google on most Android devices).
///
/// Needs no server configuration, and reports partial text as the person
/// speaks. The catch is language packs: a phone without a Bangla pack has no
/// Bangla recogniser at all, which is reported as [VoiceFailureKind.localeUnavailable]
/// rather than silently recognising Bangla speech as English.
class DeviceSpeechInput implements SpeechInput {
  DeviceSpeechInput({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  bool _ready = false;
  String _text = '';
  String? _error;
  Completer<void>? _final;
  void Function()? _onAutoStop;
  bool _active = false;

  @override
  String get name => 'device';

  Future<void> _init() async {
    if (_ready) return;
    _ready = await _stt.initialize(
      onStatus: (status) {
        // 'done' also follows a manual stop; only an unprompted end is an auto-stop.
        if ((status == 'done' || status == 'notListening') && _active) {
          _active = false;
          _onAutoStop?.call();
        }
      },
      onError: (e) => _error = e.errorMsg,
    );
    if (!_ready) {
      // initialize() returns false both for a denied permission and for a
      // missing recogniser; the permission flag tells them apart.
      throw VoiceFailure(
        _stt.hasError && (_stt.lastError?.errorMsg == 'error_permission')
            ? VoiceFailureKind.permissionDenied
            : VoiceFailureKind.unavailable,
      );
    }
  }

  /// Finds the installed recogniser locale for 'bn' / 'en' (ids look like `bn_BD` or `bn-BD`).
  Future<String> _localeId(String language) async {
    final locales = await _stt.locales();
    for (final l in locales) {
      if (l.localeId.toLowerCase().replaceAll('-', '_').startsWith('${language}_')) return l.localeId;
    }
    throw const VoiceFailure(VoiceFailureKind.localeUnavailable);
  }

  @override
  Future<void> start({
    required String locale,
    required void Function(String partial) onPartial,
    required void Function() onAutoStop,
  }) async {
    await _init();
    final localeId = await _localeId(locale);
    _text = '';
    _error = null;
    _final = Completer<void>();
    _onAutoStop = onAutoStop;
    _active = true;

    await _stt.listen(
      onResult: (r) {
        _text = r.recognizedWords;
        onPartial(_text);
        if (r.finalResult && !(_final?.isCompleted ?? true)) _final!.complete();
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<String> stop() async {
    _active = false;
    await _stt.stop();
    // The final result lands just after stop(); do not wait forever for it.
    await _final?.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});

    if (_error == 'error_permission') throw const VoiceFailure(VoiceFailureKind.permissionDenied);
    final text = _text.trim();
    if (text.isEmpty) throw const VoiceFailure(VoiceFailureKind.noSpeech);
    return text;
  }

  @override
  Future<void> cancel() async {
    _active = false;
    await _stt.cancel();
  }
}
