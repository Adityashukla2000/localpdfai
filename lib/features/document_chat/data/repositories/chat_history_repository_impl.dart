import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:local_pdf_ai/core/database/database_service.dart';
import 'package:local_pdf_ai/core/database/tables.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/document_chat/domain/models/chat_message_entity.dart';
import 'package:local_pdf_ai/features/document_chat/domain/repositories/chat_history_repository.dart';

class ChatHistoryRepositoryImpl implements ChatHistoryRepository {
  final LocalDatabaseService _dbService;

  ChatHistoryRepositoryImpl(this._dbService);

  @override
  Future<List<ChatMessageEntity>> getMessagesForDocument(String documentId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        DbTables.chatMessages,
        where: '${DbTables.colMsgDocId} = ?',
        whereArgs: [documentId],
        orderBy: '${DbTables.colMsgTimestamp} ASC',
      );
      return maps.map((m) => ChatMessageEntity.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch chat messages for document $documentId: $e');
    }
  }

  @override
  Future<void> saveMessage(ChatMessageEntity message) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        DbTables.chatMessages,
        message.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to save message: $e');
    }
  }

  @override
  Future<void> clearMessagesForDocument(String documentId) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        DbTables.chatMessages,
        where: '${DbTables.colMsgDocId} = ?',
        whereArgs: [documentId],
      );
    } catch (e) {
      throw DatabaseException('Failed to clear chat for document $documentId: $e');
    }
  }

  @override
  Future<void> clearAllChatHistory() async {
    try {
      final db = await _dbService.database;
      await db.delete(DbTables.chatMessages);
    } catch (e) {
      throw DatabaseException('Failed to clear all chat history: $e');
    }
  }
}
