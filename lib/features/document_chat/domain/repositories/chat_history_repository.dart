import '../models/chat_message_entity.dart';

/// Contract for persistent chat history.
abstract class ChatHistoryRepository {
  Future<List<ChatMessageEntity>> getMessagesForDocument(String documentId);
  Future<void> saveMessage(ChatMessageEntity message);
  Future<void> clearMessagesForDocument(String documentId);
  Future<void> clearAllChatHistory();
}
