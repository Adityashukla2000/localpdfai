import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:local_pdf_ai/core/database/database_service.dart';
import 'package:local_pdf_ai/core/database/tables.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_chunk_entity.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:local_pdf_ai/features/documents/domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final LocalDatabaseService _dbService;

  DocumentRepositoryImpl(this._dbService);

  @override
  Future<List<DocumentEntity>> getAllDocuments() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        DbTables.documents,
        orderBy: '${DbTables.colDocImportedAt} DESC',
      );
      return maps.map((m) => DocumentEntity.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch documents: $e');
    }
  }

  @override
  Future<DocumentEntity?> getDocumentById(String id) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        DbTables.documents,
        where: '${DbTables.colDocId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return DocumentEntity.fromMap(maps.first);
    } catch (e) {
      throw DatabaseException('Failed to fetch document $id: $e');
    }
  }

  @override
  Future<void> saveDocument(DocumentEntity doc) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        DbTables.documents,
        doc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Failed to save document ${doc.id}: $e');
    }
  }

  @override
  Future<void> updateDocumentStatus(
    String id,
    DocumentProcessingStatus status, {
    String? errorMessage,
    int? extractedChars,
    bool? hasSelectableText,
  }) async {
    try {
      final db = await _dbService.database;
      final values = <String, dynamic>{
        DbTables.colDocStatus: status.name,
      };
      if (errorMessage != null) {
        values[DbTables.colDocErrorMessage] = errorMessage;
      }
      if (extractedChars != null) {
        values[DbTables.colDocExtractedChars] = extractedChars;
      }
      if (hasSelectableText != null) {
        values[DbTables.colDocHasSelectableText] = hasSelectableText ? 1 : 0;
      }

      await db.update(
        DbTables.documents,
        values,
        where: '${DbTables.colDocId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to update document status for $id: $e');
    }
  }

  @override
  Future<void> saveChunks(List<DocumentChunkEntity> chunks) async {
    if (chunks.isEmpty) return;
    try {
      final db = await _dbService.database;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final chunk in chunks) {
          batch.insert(
            DbTables.chunks,
            chunk.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw DatabaseException('Failed to save ${chunks.length} chunks: $e');
    }
  }

  @override
  Future<List<DocumentChunkEntity>> getChunksForDocument(String docId) async {
    try {
      final db = await _dbService.database;
      final maps = await db.query(
        DbTables.chunks,
        where: '${DbTables.colChunkDocId} = ?',
        whereArgs: [docId],
        orderBy: '${DbTables.colChunkIndex} ASC',
      );
      return maps.map((m) => DocumentChunkEntity.fromMap(m)).toList();
    } catch (e) {
      throw DatabaseException('Failed to fetch chunks for document $docId: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      final db = await _dbService.database;
      await db.delete(
        DbTables.documents,
        where: '${DbTables.colDocId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Failed to delete document $id: $e');
    }
  }

  @override
  Future<void> deleteAllDocuments() async {
    try {
      final db = await _dbService.database;
      await db.delete(DbTables.documents);
      await db.delete(DbTables.chunks);
    } catch (e) {
      throw DatabaseException('Failed to delete all documents: $e');
    }
  }
}
