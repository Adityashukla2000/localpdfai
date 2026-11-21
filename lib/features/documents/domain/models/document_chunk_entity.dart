import 'package:equatable/equatable.dart';

/// Domain entity representing a text chunk extracted from a document page.
class DocumentChunkEntity extends Equatable {
  final String id;
  final String documentId;
  final int chunkIndex;
  final int pageNumber;
  final String content;
  final int charStart;
  final int charEnd;

  const DocumentChunkEntity({
    required this.id,
    required this.documentId,
    required this.chunkIndex,
    required this.pageNumber,
    required this.content,
    required this.charStart,
    required this.charEnd,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'chunk_index': chunkIndex,
      'page_number': pageNumber,
      'content': content,
      'char_start': charStart,
      'char_end': charEnd,
    };
  }

  factory DocumentChunkEntity.fromMap(Map<String, dynamic> map) {
    return DocumentChunkEntity(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      chunkIndex: map['chunk_index'] as int,
      pageNumber: map['page_number'] as int,
      content: map['content'] as String,
      charStart: map['char_start'] as int,
      charEnd: map['char_end'] as int,
    );
  }

  @override
  List<Object?> get props => [
        id,
        documentId,
        chunkIndex,
        pageNumber,
        content,
        charStart,
        charEnd,
      ];
}
