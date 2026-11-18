import '../../../l10n/generated/app_localizations.dart';
import '../domain/speech_input.dart';

/// What to tell the person when voice input fails, and what to do instead.
String voiceFailureText(AppLocalizations l, VoiceFailure failure) => switch (failure.kind) {
      VoiceFailureKind.permissionDenied => l.voiceErrPermission,
      VoiceFailureKind.unavailable => l.voiceErrUnavailable,
      VoiceFailureKind.localeUnavailable => l.voiceErrLocale,
      VoiceFailureKind.noSpeech => l.voiceErrNoSpeech,
      VoiceFailureKind.server => l.voiceErrServer,
    };
