import '../models/document_chunk_entity.dart';
import '../models/document_entity.dart';

/// Contract for document metadata and chunk persistence.
abstract class DocumentRepository {
  Future<List<DocumentEntity>> getAllDocuments();
  Future<DocumentEntity?> getDocumentById(String id);
  Future<void> saveDocument(DocumentEntity doc);
  Future<void> updateDocumentStatus(
    String id,
    DocumentProcessingStatus status, {
    String? errorMessage,
    int? extractedChars,
    bool? hasSelectableText,
  });
  Future<void> saveChunks(List<DocumentChunkEntity> chunks);
  Future<List<DocumentChunkEntity>> getChunksForDocument(String docId);
  Future<void> deleteDocument(String id);
  Future<void> deleteAllDocuments();
}
