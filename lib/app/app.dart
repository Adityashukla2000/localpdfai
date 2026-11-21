import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/constants/app_constants.dart';
import '../core/database/database_service.dart';
import '../core/storage/storage_management_service.dart';
import '../features/dashboard/presentation/bloc/dashboard_cubit.dart';
import '../features/document_chat/data/services/document_assistant_service.dart';
import '../features/document_chat/data/services/prompt_builder_service.dart';
import '../features/document_chat/data/services/retrieval_service.dart';
import '../features/document_chat/domain/repositories/chat_history_repository.dart';
import '../features/document_chat/presentation/bloc/document_chat_cubit.dart';
import '../features/documents/data/services/document_picker_service.dart';
import '../features/documents/data/services/ocr_service.dart';
import '../features/documents/data/services/pdf_extraction_service.dart';
import '../features/documents/data/services/text_chunking_service.dart';
import '../features/documents/domain/repositories/document_repository.dart';
import '../features/documents/presentation/bloc/documents_cubit.dart';
import '../features/model_manager/data/services/local_model_service.dart';
import '../features/model_manager/data/services/model_download_service.dart';
import '../features/model_manager/presentation/bloc/model_manager_cubit.dart';
import '../features/settings/data/services/settings_service.dart';
import '../features/settings/domain/models/settings_entity.dart';
import '../features/settings/presentation/bloc/settings_cubit.dart';
import '../features/summarization/data/services/summary_service.dart';
import '../features/summarization/presentation/bloc/summarization_cubit.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class LocalPdfAiApp extends StatelessWidget {
  final LocalDatabaseService dbService;
  final StorageManagementService storageService;
  final DocumentRepository docRepository;
  final DocumentPickerService pickerService;
  final PdfExtractionService extractionService;
  final TextChunkingService chunkingService;
  final OcrService ocrService;
  final ModelDownloadService downloadService;
  final LocalModelService modelService;
  final RetrievalEngine retrievalEngine;
  final PromptBuilderService promptBuilder;
  final DocumentAssistantService assistantService;
  final SummaryService summaryService;
  final ChatHistoryRepository chatRepository;
  final SettingsService settingsService;

  const LocalPdfAiApp({
    super.key,
    required this.dbService,
    required this.storageService,
    required this.docRepository,
    required this.pickerService,
    required this.extractionService,
    required this.chunkingService,
    required this.ocrService,
    required this.downloadService,
    required this.modelService,
    required this.retrievalEngine,
    required this.promptBuilder,
    required this.assistantService,
    required this.summaryService,
    required this.chatRepository,
    required this.settingsService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: dbService),
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: docRepository),
        RepositoryProvider.value(value: pickerService),
        RepositoryProvider.value(value: extractionService),
        RepositoryProvider.value(value: chunkingService),
        RepositoryProvider.value(value: ocrService),
        RepositoryProvider.value(value: downloadService),
        RepositoryProvider.value(value: modelService),
        RepositoryProvider.value(value: retrievalEngine),
        RepositoryProvider.value(value: promptBuilder),
        RepositoryProvider.value(value: assistantService),
        RepositoryProvider.value(value: summaryService),
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider.value(value: settingsService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(
              settingsService: settingsService,
              storageService: storageService,
              docRepository: docRepository,
              chatRepository: chatRepository,
            )..loadSettings(),
          ),
          BlocProvider<DashboardCubit>(
            create: (_) => DashboardCubit(
              docRepository: docRepository,
              modelService: modelService,
              storageService: storageService,
            ),
          ),
          BlocProvider<DocumentsCubit>(
            create: (_) => DocumentsCubit(
              pickerService: pickerService,
              extractionService: extractionService,
              chunkingService: chunkingService,
              ocrService: ocrService,
              docRepository: docRepository,
              storageService: storageService,
            ),
          ),
          BlocProvider<ModelManagerCubit>(
            create: (_) => ModelManagerCubit(
              downloadService: downloadService,
              modelService: modelService,
            ),
          ),
          BlocProvider<DocumentChatCubit>(
            create: (_) => DocumentChatCubit(
              assistantService: assistantService,
              chatRepository: chatRepository,
            ),
          ),
          BlocProvider<SummarizationCubit>(
            create: (_) => SummarizationCubit(
              summaryService: summaryService,
            ),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settingsState) {
            ThemeMode themeMode = ThemeMode.system;
            switch (settingsState.settings.themeMode) {
              case AppThemeMode.light:
                themeMode = ThemeMode.light;
                break;
              case AppThemeMode.dark:
                themeMode = ThemeMode.dark;
                break;
              case AppThemeMode.system:
                themeMode = ThemeMode.system;
                break;
            }

            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              initialRoute: AppRouter.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            );
          },
        ),
      ),
    );
  }
}
