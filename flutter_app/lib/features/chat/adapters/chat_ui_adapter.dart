import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_app/shared/models/chat_message.dart';

// ============================================================
// [어댑터] chat_ui_adapter.dart
// 내부 ChatMessage 모델 ↔ flutter_chat_ui의 types.Message 변환.
//
// 규칙:
//   - 사용자 메시지: types.TextMessage
//   - AI 일반 응답: types.TextMessage
//   - AI 액션/리포트 메시지(metadata.actionType 존재): types.CustomMessage
//     metadata에 원본 ChatMessage의 metadata를 그대로 담아 전달 →
//     customMessageBuilder에서 액션 버튼/리포트 카드 렌더링
// ============================================================

class ChatUIAdapter {
  ChatUIAdapter._();

  static const String aiUserId = 'assistant';
  static const String aiUserName = 'AI 어시스턴트';

  /// 현재 사용자를 chat_ui의 User 타입으로.
  static types.User currentUser({
    required String userId,
    String name = '나',
  }) {
    return types.User(id: userId, firstName: name);
  }

  /// AI 어시스턴트 User.
  static types.User aiUser() =>
      const types.User(id: aiUserId, firstName: aiUserName);

  /// ChatMessage → types.Message.
  /// 주의: chat_ui는 가장 최근 메시지가 리스트의 0번째에 오도록 정렬된 상태를 기대함.
  static types.Message toUiMessage(
    ChatMessage msg, {
    required String currentUserId,
  }) {
    final author = msg.role == 'user'
        ? types.User(id: currentUserId)
        : aiUser();
    final ts = _toMillis(msg.createdAt);
    final id = msg.id.toString();

    final actionType = msg.metadata?['actionType'] as String?;
    final hasAction = actionType != null && actionType.isNotEmpty;

    if (hasAction) {
      return types.CustomMessage(
        author: author,
        id: id,
        createdAt: ts,
        metadata: {
          'kind': 'action',
          'text': msg.content,
          ...?msg.metadata,
        },
      );
    }

    return types.TextMessage(
      author: author,
      id: id,
      createdAt: ts,
      text: msg.content,
    );
  }

  /// 옵티미스틱(서버 저장 전) 사용자 메시지.
  static types.TextMessage optimisticUserMessage({
    required String currentUserId,
    required String text,
  }) {
    return types.TextMessage(
      author: types.User(id: currentUserId),
      id: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: text,
      status: types.Status.sending,
    );
  }

  static int _toMillis(String iso) {
    try {
      return DateTime.parse(iso).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }
}
