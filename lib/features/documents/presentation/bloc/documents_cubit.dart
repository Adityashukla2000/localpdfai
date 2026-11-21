import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/storage/storage_management_service.dart';
import '../../data/services/document_picker_service.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/pdf_extraction_service.dart';
import '../../data/services/text_chunking_service.dart';
import '../../domain/models/document_entity.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentsState extends Equatable {
  final bool isLoading;
  final bool isImporting;
  final String? processingStatusText;
  final double importProgress; // 0.0 to 1.0
  final List<DocumentEntity> documents;
  final DocumentEntity? recentlyImportedDoc;
  final String? errorMessage;

  const DocumentsState({
    this.isLoading = false,
    this.isImporting = false,
    this.processingStatusText,
    this.importProgress = 0.0,
    this.documents = const [],
    this.recentlyImportedDoc,
    this.errorMessage,
  });

  DocumentsState copyWith({
    bool? isLoading,
    bool? isImporting,
    String? processingStatusText,
    double? importProgress,
    List<DocumentEntity>? documents,
    DocumentEntity? recentlyImportedDoc,
    String? errorMessage,
  }) {
    return DocumentsState(
      isLoading: isLoading ?? this.isLoading,
      isImporting: isImporting ?? this.isImporting,
      processingStatusText: processingStatusText,
      importProgress: importProgress ?? this.importProgress,
      documents: documents ?? this.documents,
      recentlyImportedDoc: recentlyImportedDoc,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isImporting,
        processingStatusText,
        importProgress,
        documents,
        recentlyImportedDoc,
        errorMessage,
      ];
}

class DocumentsCubit extends Cubit<DocumentsState> {
  final DocumentPickerService _pickerService;
  final PdfExtractionService _extractionService;
  final TextChunkingService _chunkingService;
  final OcrService _ocrService;
  final DocumentRepository _docRepository;
  final StorageManagementService _storageService;
  final Uuid _uuid = const Uuid();

  DocumentsCubit({
    required this._pickerService,
    required this._extractionService,
    required this._chunkingService,
    required this._ocrService,
    required this._docRepository,
    required this._storageService,
  })  : super(const DocumentsState());

  Future<void> loadDocuments() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final docs = await _docRepository.getAllDocuments();
      emit(state.copyWith(isLoading: false, documents: docs));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load documents: $e'));
    }
  }

  Future<void> importDocument() async {
    try {
      final picked = await _pickerService.pickPdfDocument();
      if (picked == null) return; // User cancelled

      emit(state.copyWith(
        isImporting: true,
        importProgress: 0.05,
        processingStatusText: 'Copying document to private storage...',
        errorMessage: null,
      ));

      final docId = _uuid.v4();
      final targetFileName = '$docId.pdf';
      final storedFile = await _storageService.copyDocumentToAppStorage(
        picked.file,
        targetFileName,
      );

      emit(state.copyWith(
        importProgress: 0.2,
        processingStatusText: 'Extracting text page-by-page...',
      ));

      PdfExtractionResult extraction = await _extractionService.extractText(
        storedFile,
        onProgress: (current, total) {
          final p = 0.2 + (0.5 * (current / total));
          emit(state.copyWith(
            importProgress: p,
            processingStatusText: 'Extracting page $current of $total...',
          ));
        },
      );

      // If document is scanned / has no selectable text, attempt OCR fallback
      if (!extraction.hasSelectableText) {
        emit(state.copyWith(
          importProgress: 0.7,
          processingStatusText: 'Scanned PDF detected. Running on-device OCR...',
        ));
        extraction = await _ocrService.processScannedPdf(storedFile);
      }

      emit(state.copyWith(
        importProgress: 0.8,
        processingStatusText: 'Generating semantic chunks & citations...',
      ));

      final chunks = _chunkingService.chunkPages(
        documentId: docId,
        pages: extraction.pages,
      );

      final documentEntity = DocumentEntity(
        id: docId,
        name: picked.name,
        originalPath: picked.file.path,
        storedPath: storedFile.path,
        fileSizeBytes: picked.sizeBytes,
        pageCount: extraction.pageCount,
        importedAt: DateTime.now(),
        status: extraction.hasSelectableText
            ? DocumentProcessingStatus.indexed
            : DocumentProcessingStatus.scannedOcrNeeded,
        extractedCharacterCount: extraction.totalCharacters,
        hasSelectableText: extraction.hasSelectableText,
      );

      await _docRepository.saveDocument(documentEntity);
      await _docRepository.saveChunks(chunks);

      final updatedDocs = await _docRepository.getAllDocuments();
      emit(state.copyWith(
        isImporting: false,
        importProgress: 1.0,
        processingStatusText: 'Indexing complete!',
        documents: updatedDocs,
        recentlyImportedDoc: documentEntity,
      ));
    } catch (e) {
      emit(state.copyWith(
        isImporting: false,
        processingStatusText: null,
        errorMessage: 'Import failed: $e',
      ));
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      final doc = await _docRepository.getDocumentById(id);
      if (doc != null) {
        await _storageService.deleteFile(doc.storedPath);
        await _docRepository.deleteDocument(id);
        final docs = await _docRepository.getAllDocuments();
        emit(state.copyWith(documents: docs));
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete document: $e'));
    }
  }
}
