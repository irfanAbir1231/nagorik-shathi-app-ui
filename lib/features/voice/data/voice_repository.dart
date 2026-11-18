import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';

class VoiceCapabilities {
  const VoiceCapabilities({required this.serverStt, required this.serverTts});
  final bool serverStt;
  final bool serverTts;
}

class VoiceRepository {
  VoiceRepository(this.api);
  final ApiClient api;

  /// `GET /voice/transcribe` — what this server can do. Lets the app pick an
  /// engine up front instead of failing on every press of the microphone.
  Future<ApiResult<VoiceCapabilities>> capabilities() {
    return api.get<VoiceCapabilities>('/voice/transcribe', parse: (d) {
      final voice = (d as Map<String, dynamic>)['voice'] as Map<String, dynamic>;
      return VoiceCapabilities(serverStt: voice['serverStt'] == true, serverTts: voice['serverTts'] == true);
    });
  }

  /// `POST /voice/transcribe` — one short clip in, text out. The server discards
  /// the audio after transcribing it.
  Future<ApiResult<String>> transcribe(Uint8List audio, {required String locale}) {
    return api.post<String>(
      '/voice/transcribe',
      // A FormData can only be sent once, so build a new one per attempt.
      bodyBuilder: () => FormData.fromMap({
        'audio': MultipartFile.fromBytes(
          audio,
          filename: 'speech.mp4',
          contentType: DioMediaType('audio', 'mp4'),
        ),
        'locale': locale,
        'purpose': 'dictation',
      }),
      parse: (d) => ((d as Map<String, dynamic>)['text'] as String? ?? '').trim(),
    );
  }
}
