import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_chunk_entity.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite ffi for desktop/test VM
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Operations Unit Tests (SQLite in-memory)', () {
    late Database db;

    setUp(() async {
      db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (d) async => await d.execute('PRAGMA foreign_keys = ON;'),
          onCreate: (d, version) async {
            await d.execute('''
              CREATE TABLE documents (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                original_path TEXT NOT NULL,
                stored_path TEXT NOT NULL,
                file_size_bytes INTEGER NOT NULL,
                page_count INTEGER NOT NULL,
                imported_at INTEGER NOT NULL,
                status TEXT NOT NULL,
                error_message TEXT,
                extracted_character_count INTEGER DEFAULT 0,
                has_selectable_text INTEGER DEFAULT 1
              )
            ''');

            await d.execute('''
              CREATE TABLE document_chunks (
                id TEXT PRIMARY KEY,
                document_id TEXT NOT NULL,
                chunk_index INTEGER NOT NULL,
                page_number INTEGER NOT NULL,
                content TEXT NOT NULL,
                char_start INTEGER NOT NULL,
                char_end INTEGER NOT NULL,
                FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
              )
            ''');

            await d.execute('''
              CREATE TABLE chat_messages (
                id TEXT PRIMARY KEY,
                document_id TEXT NOT NULL,
                sender TEXT NOT NULL,
                text TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                source_citations_json TEXT,
                is_summary INTEGER DEFAULT 0,
                FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
              )
            ''');
          },
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Inserts document and retrieves it by id', () async {
      final doc = DocumentEntity(
        id: 'doc-sqlite-1',
        name: 'Report.pdf',
        originalPath: '/tmp/Report.pdf',
        storedPath: '/app/documents/doc-sqlite-1.pdf',
        fileSizeBytes: 10240,
        pageCount: 5,
        importedAt: DateTime.now(),
        status: DocumentProcessingStatus.indexed,
        extractedCharacterCount: 5000,
        hasSelectableText: true,
      );

      await db.insert('documents', doc.toMap());

      final results = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [doc.id],
      );

      expect(results, isNotEmpty);
      final fetched = DocumentEntity.fromMap(results.first);
      expect(fetched.name, equals('Report.pdf'));
      expect(fetched.pageCount, equals(5));
      expect(fetched.status, equals(DocumentProcessingStatus.indexed));
    });

    test('Batch inserts chunks and verifies cascade delete on document removal', () async {
      final doc = DocumentEntity(
        id: 'doc-sqlite-2',
        name: 'CascadeTest.pdf',
        originalPath: '/tmp/test.pdf',
        storedPath: '/app/documents/test.pdf',
        fileSizeBytes: 2048,
        pageCount: 2,
        importedAt: DateTime.now(),
      );
      await db.insert('documents', doc.toMap());

      final chunks = [
        const DocumentChunkEntity(
          id: 'chunk-c1',
          documentId: 'doc-sqlite-2',
          chunkIndex: 0,
          pageNumber: 1,
          content: 'First page content',
          charStart: 0,
          charEnd: 18,
        ),
        const DocumentChunkEntity(
          id: 'chunk-c2',
          documentId: 'doc-sqlite-2',
          chunkIndex: 1,
          pageNumber: 2,
          content: 'Second page content',
          charStart: 0,
          charEnd: 19,
        ),
      ];

      final batch = db.batch();
      for (final chunk in chunks) {
        batch.insert('document_chunks', chunk.toMap());
      }
      await batch.commit(noResult: true);

      final chunksBefore = await db.query('document_chunks', where: 'document_id = ?', whereArgs: [doc.id]);
      expect(chunksBefore.length, equals(2));

      // Delete parent document
      await db.delete('documents', where: 'id = ?', whereArgs: [doc.id]);

      // Verify cascade deletion
      final chunksAfter = await db.query('document_chunks', where: 'document_id = ?', whereArgs: [doc.id]);
      expect(chunksAfter, isEmpty);
    });
  });
}
