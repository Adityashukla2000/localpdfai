import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:local_pdf_ai/core/constants/app_constants.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/core/database/tables.dart';

/// Service managing the local SQLite database lifecycle and migrations.
class LocalDatabaseService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      return await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
      );
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to initialize local SQLite database: $e',
        details: stack.toString(),
      );
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE ${DbTables.documents} (
        ${DbTables.colDocId} TEXT PRIMARY KEY,
        ${DbTables.colDocName} TEXT NOT NULL,
        ${DbTables.colDocOriginalPath} TEXT NOT NULL,
        ${DbTables.colDocStoredPath} TEXT NOT NULL,
        ${DbTables.colDocFileSizeBytes} INTEGER NOT NULL,
        ${DbTables.colDocPageCount} INTEGER NOT NULL,
        ${DbTables.colDocImportedAt} INTEGER NOT NULL,
        ${DbTables.colDocStatus} TEXT NOT NULL,
        ${DbTables.colDocErrorMessage} TEXT,
        ${DbTables.colDocExtractedChars} INTEGER DEFAULT 0,
        ${DbTables.colDocHasSelectableText} INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.chunks} (
        ${DbTables.colChunkId} TEXT PRIMARY KEY,
        ${DbTables.colChunkDocId} TEXT NOT NULL,
        ${DbTables.colChunkIndex} INTEGER NOT NULL,
        ${DbTables.colChunkPageNumber} INTEGER NOT NULL,
        ${DbTables.colChunkContent} TEXT NOT NULL,
        ${DbTables.colChunkCharStart} INTEGER NOT NULL,
        ${DbTables.colChunkCharEnd} INTEGER NOT NULL,
        FOREIGN KEY (${DbTables.colChunkDocId})
          REFERENCES ${DbTables.documents} (${DbTables.colDocId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.chatMessages} (
        ${DbTables.colMsgId} TEXT PRIMARY KEY,
        ${DbTables.colMsgDocId} TEXT NOT NULL,
        ${DbTables.colMsgSender} TEXT NOT NULL,
        ${DbTables.colMsgText} TEXT NOT NULL,
        ${DbTables.colMsgTimestamp} INTEGER NOT NULL,
        ${DbTables.colMsgCitations} TEXT,
        ${DbTables.colMsgIsSummary} INTEGER DEFAULT 0,
        FOREIGN KEY (${DbTables.colMsgDocId})
          REFERENCES ${DbTables.documents} (${DbTables.colDocId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbTables.settings} (
        ${DbTables.colSettingKey} TEXT PRIMARY KEY,
        ${DbTables.colSettingValue} TEXT NOT NULL
      )
    ''');

    // Indices for performance
    await db.execute(
      'CREATE INDEX idx_chunks_doc_id ON ${DbTables.chunks} (${DbTables.colChunkDocId});',
    );
    await db.execute(
      'CREATE INDEX idx_chat_doc_id ON ${DbTables.chatMessages} (${DbTables.colMsgDocId});',
    );
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
