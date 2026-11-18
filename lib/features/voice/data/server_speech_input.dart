import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/network/api_result.dart';
import '../domain/speech_input.dart';
import 'voice_repository.dart';

/// Records a short clip and has the backend transcribe it.
///
/// One completed upload rather than a streamed socket: a ~100 KB clip survives a
/// bad 2G link far better than a connection held open for the whole utterance.
class ServerSpeechInput implements SpeechInput {
  ServerSpeechInput(this._repo, {AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final VoiceRepository _repo;
  final AudioRecorder _recorder;
  Timer? _limit;
  String? _path;
  String _locale = 'bn';

  /// The server caps a clip at 2 MB; 30 s of this encoding is ~120 KB, so the
  /// limit is about a stuck microphone, not the byte budget.
  static const maxDuration = Duration(seconds: 30);

  @override
  String get name => 'server';

  @override
  Future<void> start({
    required String locale,
    required void Function(String partial) onPartial,
    required void Function() onAutoStop,
  }) async {
    if (!await _recorder.hasPermission()) {
      throw const VoiceFailure(VoiceFailureKind.permissionDenied);
    }
    _locale = locale;
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/speech_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 32000),
      path: _path!,
    );
    _limit = Timer(maxDuration, onAutoStop);
  }

  @override
  Future<String> stop() async {
    _limit?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (path == null) throw const VoiceFailure(VoiceFailureKind.noSpeech);
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      // A press-and-release leaves a container header and nothing else.
      if (bytes.length < 2000) throw const VoiceFailure(VoiceFailureKind.noSpeech);

      final result = await _repo.transcribe(bytes, locale: _locale);
      switch (result) {
        case Ok<String>(:final data):
          if (data.isEmpty) throw const VoiceFailure(VoiceFailureKind.noSpeech);
          return data;
        case final Err<String> e:
          // 503 here means the server has no speech provider after all.
          throw VoiceFailure(VoiceFailureKind.server, err: e);
      }
    } finally {
      // The recording is sensitive and the server never stores it; neither do we.
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<void> cancel() async {
    _limit?.cancel();
    final path = await _recorder.stop() ?? _path;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
}
