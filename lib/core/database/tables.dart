/// Database table and column names for SQLite.
class DbTables {
  static const String documents = 'documents';
  static const String chunks = 'document_chunks';
  static const String chatMessages = 'chat_messages';
  static const String settings = 'app_settings';

  // Documents Columns
  static const String colDocId = 'id';
  static const String colDocName = 'name';
  static const String colDocOriginalPath = 'original_path';
  static const String colDocStoredPath = 'stored_path';
  static const String colDocFileSizeBytes = 'file_size_bytes';
  static const String colDocPageCount = 'page_count';
  static const String colDocImportedAt = 'imported_at';
  static const String colDocStatus = 'status';
  static const String colDocErrorMessage = 'error_message';
  static const String colDocExtractedChars = 'extracted_character_count';
  static const String colDocHasSelectableText = 'has_selectable_text';

  // Chunks Columns
  static const String colChunkId = 'id';
  static const String colChunkDocId = 'document_id';
  static const String colChunkIndex = 'chunk_index';
  static const String colChunkPageNumber = 'page_number';
  static const String colChunkContent = 'content';
  static const String colChunkCharStart = 'char_start';
  static const String colChunkCharEnd = 'char_end';

  // Chat Messages Columns
  static const String colMsgId = 'id';
  static const String colMsgDocId = 'document_id';
  static const String colMsgSender = 'sender';
  static const String colMsgText = 'text';
  static const String colMsgTimestamp = 'timestamp';
  static const String colMsgCitations = 'source_citations_json';
  static const String colMsgIsSummary = 'is_summary';

  // Settings Columns
  static const String colSettingKey = 'key';
  static const String colSettingValue = 'value';
}
