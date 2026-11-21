import 'package:equatable/equatable.dart';

enum DocumentProcessingStatus {
  idle,
  processing,
  indexed,
  scannedOcrNeeded,
  error;

  static DocumentProcessingStatus fromString(String val) {
    return DocumentProcessingStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => DocumentProcessingStatus.idle,
    );
  }
}

/// Domain entity representing an imported PDF document.
class DocumentEntity extends Equatable {
  final String id;
  final String name;
  final String originalPath;
  final String storedPath;
  final int fileSizeBytes;
  final int pageCount;
  final DateTime importedAt;
  final DocumentProcessingStatus status;
  final String? errorMessage;
  final int extractedCharacterCount;
  final bool hasSelectableText;

  const DocumentEntity({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.storedPath,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.importedAt,
    this.status = DocumentProcessingStatus.processing,
    this.errorMessage,
    this.extractedCharacterCount = 0,
    this.hasSelectableText = true,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  DocumentEntity copyWith({
    String? id,
    String? name,
    String? originalPath,
    String? storedPath,
    int? fileSizeBytes,
    int? pageCount,
    DateTime? importedAt,
    DocumentProcessingStatus? status,
    String? errorMessage,
    int? extractedCharacterCount,
    bool? hasSelectableText,
  }) {
    return DocumentEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      originalPath: originalPath ?? this.originalPath,
      storedPath: storedPath ?? this.storedPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      importedAt: importedAt ?? this.importedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      extractedCharacterCount:
          extractedCharacterCount ?? this.extractedCharacterCount,
      hasSelectableText: hasSelectableText ?? this.hasSelectableText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'original_path': originalPath,
      'stored_path': storedPath,
      'file_size_bytes': fileSizeBytes,
      'page_count': pageCount,
      'imported_at': importedAt.millisecondsSinceEpoch,
      'status': status.name,
      'error_message': errorMessage,
      'extracted_character_count': extractedCharacterCount,
      'has_selectable_text': hasSelectableText ? 1 : 0,
    };
  }

  factory DocumentEntity.fromMap(Map<String, dynamic> map) {
    return DocumentEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      originalPath: map['original_path'] as String,
      storedPath: map['stored_path'] as String,
      fileSizeBytes: map['file_size_bytes'] as int,
      pageCount: map['page_count'] as int,
      importedAt:
          DateTime.fromMillisecondsSinceEpoch(map['imported_at'] as int),
      status: DocumentProcessingStatus.fromString(map['status'] as String),
      errorMessage: map['error_message'] as String?,
      extractedCharacterCount:
          (map['extracted_character_count'] as int?) ?? 0,
      hasSelectableText: (map['has_selectable_text'] as int?) == 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        originalPath,
        storedPath,
        fileSizeBytes,
        pageCount,
        importedAt,
        status,
        errorMessage,
        extractedCharacterCount,
        hasSelectableText,
      ];
}
