import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/shared/models/chat_message.dart';

// ============================================================
// [채팅 Provider] chat_provider.dart
// 세션 기반 채팅의 메시지 조회/전송을 담당합니다.
// ChatScreen(채팅 화면)에서 사용됩니다.
//
// chatMessagesProvider(sessionId) — 특정 세션의 메시지 목록 상태
// sendChatMessageProvider((text, sessionId)) — POST 응답 메시지를 로컬 캐시에 병합
// ============================================================

class ChatMessagesController
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatMessagesController(this._apiClient, this._sessionId)
    : super(const AsyncValue.loading()) {
    load();
  }

  final ApiClient _apiClient;
  final int _sessionId;

  Future<void> load() async {
    try {
      final messages = await _apiClient.getSessionMessages(_sessionId);
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final current = state.valueOrNull ?? const <ChatMessage>[];
      state = AsyncValue.data(_mergeMessages(current, messages));
    } catch (error, stackTrace) {
      state = AsyncValue.error(
        Exception('Error loading messages: $error'),
        stackTrace,
      );
    }
  }

  void merge(List<ChatMessage> messages) {
    final current = state.valueOrNull ?? const <ChatMessage>[];
    state = AsyncValue.data(_mergeMessages(current, messages));
  }
}

final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesController, AsyncValue<List<ChatMessage>>, int>((
      ref,
      sessionId,
    ) {
      final apiClient = ref.watch(apiClientProvider);
      return ChatMessagesController(apiClient, sessionId);
    });

/// Send a chat message and get AI response
final sendChatMessageProvider =
    FutureProvider.family<List<ChatMessage>, (String, int)>((ref, args) async {
      final apiClient = ref.watch(apiClientProvider);
      final (text, sessionId) = args;

      try {
        final newMessages = await apiClient.sendSessionMessage(sessionId, text);
        ref.read(chatMessagesProvider(sessionId).notifier).merge(newMessages);
        return newMessages;
      } catch (e) {
        throw Exception('Error sending message: $e');
      }
    });

List<ChatMessage> _mergeMessages(
  List<ChatMessage> existing,
  List<ChatMessage> incoming,
) {
  final byId = <int, ChatMessage>{
    for (final message in existing) message.id: message,
    for (final message in incoming) message.id: message,
  };
  final merged = byId.values.toList();
  merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return merged;
}
