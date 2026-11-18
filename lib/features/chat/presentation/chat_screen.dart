import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/error_text.dart';
import '../../../core/ui/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../opportunities/presentation/labels.dart';
import '../../voice/application/voice_controller.dart';
import '../../voice/application/voice_providers.dart';
import '../../voice/presentation/voice_text.dart';
import '../application/chat_controller.dart';
import '../domain/chat.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  var _awayFromBottom = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {})); // mic ↔ send follows the text
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final away = _scroll.position.maxScrollExtent - _scroll.offset > 300;
      if (away != _awayFromBottom) setState(() => _awayFromBottom = away);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).languageCode;

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    ref.read(voiceControllerProvider.notifier).cancel();
    ref.read(chatControllerProvider.notifier).send(text, locale: _locale);
    _input.clear();
  }

  /// Puts a transcript into the box for the person to read and fix before
  /// sending. Speech recognition is wrong often enough, especially in Bangla,
  /// that sending it straight to the assistant would be a mistake.
  void _insertTranscript(String text) {
    final existing = _input.text.trimRight();
    final joined = existing.isEmpty ? text : '$existing $text';
    _input.value = TextEditingValue(text: joined, selection: TextSelection.collapsed(offset: joined.length));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showHistory() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _HistorySheet(currentId: ref.read(chatControllerProvider).conversationId),
    );
    if (id != null) ref.read(chatControllerProvider.notifier).open(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chat = ref.watch(chatControllerProvider);
    ref.listen(chatControllerProvider.select((s) => s.messages.length), (_, _) => _scrollToEnd());
    final voice = ref.watch(voiceControllerProvider);
    ref.listen(voiceControllerProvider.select((s) => s.resultSeq), (_, _) {
      final text = ref.read(voiceControllerProvider).result;
      if (text != null && text.isNotEmpty) _insertTranscript(text);
    });

    // The engine of the latest reply says whether answers come from live AI.
    final replies = chat.messages.where((m) => m.role == ChatRole.assistant);
    final lastReply = replies.isEmpty ? null : replies.last;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          const _AssistantAvatar(size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.assistantName, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (lastReply != null)
                Text(
                  lastReply.isSimulated ? l.aiSimulated : l.aiLive,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: lastReply.isSimulated ? AppColors.warning : AppColors.success,
                      ),
                ),
            ]),
          ),
        ]),
        actions: [
          IconButton(tooltip: l.chatHistory, icon: const Icon(Icons.history_rounded), onPressed: _showHistory),
          IconButton(
            tooltip: l.chatNew,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: chat.sending ? null : () => ref.read(chatControllerProvider.notifier).newChat(),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(child: _body(l, chat)),
            if (_awayFromBottom && chat.messages.isNotEmpty)
              Positioned(
                right: 16,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: l.scrollToLatest,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: _scrollToEnd,
                  child: const Icon(Icons.keyboard_double_arrow_down_rounded),
                ),
              ),
          ]),
        ),
        if (chat.error != null && chat.messages.any((m) => m.state == SendState.failed))
          _Banner(text: errorText(l, chat.error!), color: AppColors.danger, icon: Icons.error_outline_rounded),
        _VoiceStatus(state: voice),
        _Composer(
          controller: _input,
          sending: chat.sending,
          voice: voice,
          onSend: _send,
          onMic: () => ref.read(voiceControllerProvider.notifier).toggle(_locale),
        ),
      ]),
    );
  }

  Widget _body(AppLocalizations l, ChatState chat) {
    if (chat.messages.isEmpty && chat.sending) {
      return const Center(child: CircularProgressIndicator()); // opening a past chat
    }
    if (chat.messages.isEmpty && chat.error != null) {
      return ErrorRetry(
        error: chat.error!,
        onRetry: () {
          final id = chat.conversationId;
          if (id != null) ref.read(chatControllerProvider.notifier).open(id);
        },
      );
    }
    if (chat.messages.isEmpty) return _EmptyState(onPick: _send);

    final thinking = chat.sending && chat.messages.last.role == ChatRole.user;
    final messages = chat.messages;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: messages.length + (thinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == messages.length) return const _ThinkingBubble();
        final m = messages[i];
        final newDay = i == 0 || !DateUtils.isSameDay(messages[i - 1].createdAt.toLocal(), m.createdAt.toLocal());
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (newDay) _DayDivider(date: m.createdAt),
          _MessageView(
            message: m,
            onRetry: () => ref.read(chatControllerProvider.notifier).retry(m.id, locale: _locale),
          ),
        ]);
      },
    );
  }
}

/* ---------------------------------------------------------------- pieces */

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryBright]),
          ),
          child: Icon(Icons.auto_awesome_rounded, size: size * 0.55, color: AppColors.sun),
        ),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color))),
          ]),
        ),
      );
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final local = date.toLocal();
    final now = DateTime.now();
    final label = DateUtils.isSameDay(local, now)
        ? l.today
        : DateUtils.isSameDay(local, now.subtract(const Duration(days: 1)))
            ? l.yesterday
            : formatDate(locale, local);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});
  final void Function(String text) onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final suggestions = [
      (Icons.volunteer_activism_rounded, const Color(0xFFC2185B), l.chatSuggestion1),
      (Icons.agriculture_rounded, const Color(0xFF3E8E41), l.chatSuggestion2),
      (Icons.school_rounded, const Color(0xFF3F6FD8), l.chatSuggestion3),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(children: [
        const IllustratedBadge(icon: Icons.forum_rounded, color: AppColors.primary, size: 110),
        const SizedBox(height: 16),
        Text(l.chatEmptyTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l.chatEmptyBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(l.chatTryAsking, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        for (final (icon, color, text) in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPick(text),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                    Icon(Icons.north_east_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.mic_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              l.chatMicHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ]),
      ]),
    );
  }
}

/* ---------------------------------------------------------------- composer */

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.voice,
    required this.onSend,
    required this.onMic,
  });
  final TextEditingController controller;
  final bool sending;
  final VoiceState voice;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasText = controller.text.trim().isNotEmpty;

    // One round button that changes with the moment: mic when the box is
    // empty, send once there is text, stop while listening.
    final Widget action;
    if (voice.status == VoiceStatus.transcribing) {
      action = const SizedBox(
        key: ValueKey('transcribing'),
        width: 52,
        height: 52,
        child: Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    } else if (voice.status == VoiceStatus.listening) {
      action = _RoundButton(tooltip: l.voiceStop, icon: Icons.stop_rounded, color: AppColors.danger, onPressed: onMic);
    } else if (hasText) {
      action = _RoundButton(
        tooltip: l.chatSend,
        icon: Icons.send_rounded,
        color: AppColors.primary,
        onPressed: sending ? null : onSend,
      );
    } else {
      action = _RoundButton(tooltip: l.voiceStart, icon: Icons.mic_rounded, color: AppColors.primary, onPressed: onMic);
    }

    final radius = BorderRadius.circular(26);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000, // the server's limit
                buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l.chatHint,
                  fillColor: AppColors.canvas,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(duration: const Duration(milliseconds: 150), child: action),
          ]),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.icon, required this.color, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: ValueKey(icon),
        width: 52,
        height: 52,
        child: IconButton.filled(
          tooltip: tooltip,
          style: IconButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          onPressed: onPressed,
          icon: Icon(icon),
        ),
      );
}

/// One line above the box: what the microphone is doing, or why it could not.
class _VoiceStatus extends StatelessWidget {
  const _VoiceStatus({required this.state});
  final VoiceState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final failure = state.failure;
    if (state.status == VoiceStatus.listening) {
      return _Banner(
        text: state.partial.isEmpty ? l.voiceListening : state.partial,
        color: AppColors.danger,
        icon: Icons.graphic_eq_rounded,
      );
    }
    if (state.status == VoiceStatus.transcribing) {
      return _Banner(text: l.voiceTranscribing, color: AppColors.primary, icon: Icons.hourglass_top_rounded);
    }
    if (failure != null) {
      return _Banner(text: voiceFailureText(l, failure), color: AppColors.warning, icon: Icons.mic_off_rounded);
    }
    return const SizedBox.shrink();
  }
}

/* ---------------------------------------------------------------- messages */

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onRetry});
  final ChatMessage message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final time = DateFormat.jm(locale.languageCode).format(message.createdAt.toLocal());
    final maxWidth = MediaQuery.sizeOf(context).width * 0.8;

    if (message.role == ChatRole.user) {
      final failed = message.state == SendState.failed;
      final sending = message.state == SendState.sending;
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: failed ? AppColors.danger.withValues(alpha: 0.08) : AppColors.primary,
              border: failed ? Border.all(color: AppColors.danger.withValues(alpha: 0.4)) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: SelectableText(
              message.text,
              style: theme.textTheme.bodyLarge?.copyWith(color: failed ? AppColors.ink : Colors.white),
            ),
          ),
          const SizedBox(height: 3),
          if (failed)
            InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.refresh_rounded, size: 16, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l.chatNotSent,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelMedium?.copyWith(color: AppColors.danger),
                    ),
                  ),
                ]),
              ),
            )
          else
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(sending ? l.chatSending : time, style: theme.textTheme.labelSmall),
              if (!sending) ...[
                const SizedBox(width: 3),
                const Icon(Icons.done_rounded, size: 14, color: AppColors.primary),
              ],
            ]),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _AssistantAvatar(size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: SelectableText(message.text, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.ink)),
            ),
            for (final o in message.opportunities)
              Padding(padding: const EdgeInsets.only(top: 8), child: _ProgrammeCard(item: o)),
            Row(children: [
              Text(time, style: theme.textTheme.labelSmall),
              const Spacer(),
              _ReadAloudButton(message: message),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l.copy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l.copied), duration: const Duration(seconds: 2)));
                },
              ),
            ]),
            if (message.isSimulated)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(child: Text(l.chatSimulatedNote, style: theme.textTheme.bodySmall)),
              ]),
          ]),
        ),
      ]),
    );
  }
}

class _ReadAloudButton extends ConsumerWidget {
  const _ReadAloudButton({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    // No button where the phone has no proper voice: Bangla read by an English
    // voice is worse than silence because it sounds like it works.
    if (ref.watch(canSpeakProvider(language)).value != true) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final speaking = ref.watch(speakingProvider) == message.id;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: speaking ? l.stopReading : l.readAloud,
      color: speaking ? AppColors.primary : null,
      icon: Icon(speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded, size: 20),
      onPressed: () => ref
          .read(speakingProvider.notifier)
          .toggle(messageId: message.id, text: message.text, language: language),
    );
  }
}

/// Three dots that rise in turn while the assistant works.
class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 over the first 40% of each dot's cycle, then rest.
  double _lift(int dot) {
    final t = (_controller.value - dot * 0.18) % 1.0;
    if (t >= 0.4) return 0;
    return t < 0.2 ? t / 0.2 : (0.4 - t) / 0.2;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(children: [
        const _AssistantAvatar(size: 30),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) => Row(children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 8,
                        height: 8,
                        transform: Matrix4.translationValues(0, -4 * _lift(i), 0),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.4 + 0.6 * _lift(i)),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Semantics(liveRegion: true, child: Text(l.chatThinking, style: theme.textTheme.bodyMedium)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ProgrammeCard extends StatelessWidget {
  const _ProgrammeCard({required this.item});
  final ChatOpportunity item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final money = benefitText(l, locale, item.benefitAmount, item.benefitPeriod);
    final style = outcomeStyle(theme.colorScheme, item.outcome);
    void open() => context.push('/opportunity/${item.slug}');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              item.title.of(locale),
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            if (item.organisation != null)
              Text(
                item.organisation!.of(locale),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (money != null) Pill(label: money, color: AppColors.primary, icon: Icons.payments_rounded),
              Pill(label: outcomeLabel(l, item.outcome), color: style.color, icon: style.icon),
              if (item.isUnverified)
                Pill(label: verificationLabel(l, 'unverified_sample'), color: AppColors.warning, icon: Icons.info_outline),
            ]),
            if (item.nextStep != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sun.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${l.chatNextStep}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                    TextSpan(text: item.nextStep!.of(locale)),
                  ]),
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                ),
              ),
            ],
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: open,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(l.openProgramme),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------- history */

class _HistorySheet extends ConsumerWidget {
  const _HistorySheet({this.currentId});
  final String? currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final theme = Theme.of(context);
    final async = ref.watch(conversationsProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(l.chatHistory, style: theme.textTheme.titleLarge),
          ),
          Flexible(
            child: async.when(
              loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SizedBox(
                height: 260,
                child: ErrorRetry(error: e, onRetry: () => ref.invalidate(conversationsProvider)),
              ),
              data: (items) => items.isEmpty
                  ? SizedBox(height: 240, child: EmptyState(icon: Icons.history_rounded, message: l.chatNoHistory))
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final c = items[i];
                        final current = c.id == currentId;
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          tileColor: current ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5) : null,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                          ),
                          title: Text(c.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(formatDate(locale, c.lastMessageAt)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(c.id),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
