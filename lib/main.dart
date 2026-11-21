import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/database/database_service.dart';
import 'core/storage/storage_management_service.dart';
import 'features/document_chat/data/repositories/chat_history_repository_impl.dart';
import 'features/document_chat/data/services/document_assistant_service.dart';
import 'features/document_chat/data/services/prompt_builder_service.dart';
import 'features/document_chat/data/services/retrieval_service.dart';
import 'features/documents/data/repositories/document_repository_impl.dart';
import 'features/documents/data/services/document_picker_service.dart';
import 'features/documents/data/services/ocr_service.dart';
import 'features/documents/data/services/pdf_extraction_service.dart';
import 'features/documents/data/services/text_chunking_service.dart';
import 'features/model_manager/data/services/local_model_service.dart';
import 'features/model_manager/data/services/model_download_service.dart';
import 'features/settings/data/services/settings_service.dart';
import 'features/summarization/data/services/summary_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Core Services & Database
  final dbService = LocalDatabaseService();
  final storageService = StorageManagementService();
  final docRepository = DocumentRepositoryImpl(dbService);
  final chatRepository = ChatHistoryRepositoryImpl(dbService);
  final settingsService = SettingsService(dbService);

  // 2. Document Processing Pipeline Services
  final pickerService = DocumentPickerService();
  final extractionService = PdfExtractionService();
  final chunkingService = TextChunkingService();
  final ocrService = OcrService();

  // 3. Local Model & Download Services
  final downloadService = ModelDownloadService(storageService);
  final modelService = LocalModelService(storageService);

  // 4. RAG Retrieval & Prompt Construction
  final retrievalEngine = KeywordRetrievalService();
  final promptBuilder = PromptBuilderService();
  final assistantService = DocumentAssistantService(
    docRepository: docRepository,
    retrievalEngine: retrievalEngine,
    promptBuilder: promptBuilder,
    modelService: modelService,
    chatRepository: chatRepository,
  );
  final summaryService = SummaryService(
    docRepository: docRepository,
    modelService: modelService,
    promptBuilder: promptBuilder,
  );

  runApp(
    LocalPdfAiApp(
      dbService: dbService,
      storageService: storageService,
      docRepository: docRepository,
      pickerService: pickerService,
      extractionService: extractionService,
      chunkingService: chunkingService,
      ocrService: ocrService,
      downloadService: downloadService,
      modelService: modelService,
      retrievalEngine: retrievalEngine,
      promptBuilder: promptBuilder,
      assistantService: assistantService,
      summaryService: summaryService,
      chatRepository: chatRepository,
      settingsService: settingsService,
    ),
  );
}
