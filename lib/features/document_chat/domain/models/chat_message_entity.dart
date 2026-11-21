import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'source_citation.dart';

enum MessageSender { user, assistant }

/// Domain model for chat messages stored in SQLite.
class ChatMessageEntity extends Equatable {
  final String id;
  final String documentId;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final List<SourceCitation> citations;
  final bool isSummary;

  const ChatMessageEntity({
    required this.id,
    required this.documentId,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.citations = const [],
    this.isSummary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'source_citations_json': citations.isEmpty
          ? null
          : jsonEncode(citations.map((c) => c.toMap()).toList()),
      'is_summary': isSummary ? 1 : 0,
    };
  }

  factory ChatMessageEntity.fromMap(Map<String, dynamic> map) {
    List<SourceCitation> citationsList = [];
    final rawJson = map['source_citations_json'] as String?;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        citationsList = decoded
            .map((e) => SourceCitation.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return ChatMessageEntity(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      sender: map['sender'] == 'assistant'
          ? MessageSender.assistant
          : MessageSender.user,
      text: map['text'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      citations: citationsList,
      isSummary: (map['is_summary'] as int?) == 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        sender,
        text,
        timestamp,
        citations,
        isSummary,
      ];
}
