import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/chat.dart';

class ChatRepository {
  ChatRepository(this.api);
  final ApiClient api;

  /// `POST /chat` — one turn. The server allows up to 45 s for a model call, so
  /// the receive timeout is a little longer than the default.
  Future<ApiResult<ChatTurn>> send({
    required String message,
    String? conversationId,
    String? locale,
  }) {
    return api.post<ChatTurn>(
      '/chat',
      body: {
        'message': message,
        'conversationId': ?conversationId,
        'locale': ?locale,
      },
      receiveTimeout: const Duration(seconds: 55),
      parse: (d) => ChatTurn.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<ConversationSummary>>> conversations() {
    return api.get<List<ConversationSummary>>(
      '/chat',
      parse: (d) => [
        for (final c in ((d as Map<String, dynamic>)['conversations'] as List))
          ConversationSummary.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  Future<ApiResult<List<ChatMessage>>> transcript(String id) {
    return api.get<List<ChatMessage>>(
      '/chat/${Uri.encodeComponent(id)}',
      parse: (d) => [
        for (final m in ((d as Map<String, dynamic>)['messages'] as List))
          ChatMessage.fromJson(m as Map<String, dynamic>),
      ],
    );
  }
}
