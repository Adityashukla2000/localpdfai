import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_pdf_ai/core/storage/storage_management_service.dart';
import 'package:local_pdf_ai/features/document_chat/domain/repositories/chat_history_repository.dart';
import 'package:local_pdf_ai/features/documents/domain/repositories/document_repository.dart';
import 'package:local_pdf_ai/features/settings/data/services/settings_service.dart';
import 'package:local_pdf_ai/features/settings/domain/models/settings_entity.dart';

class SettingsState extends Equatable {
  final bool isLoading;
  final SettingsEntity settings;
  final StorageUsageStats? storageStats;
  final String? noticeMessage;
  final String? errorMessage;

  const SettingsState({
    this.isLoading = false,
    required this.settings,
    this.storageStats,
    this.noticeMessage,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isLoading,
    SettingsEntity? settings,
    StorageUsageStats? storageStats,
    String? noticeMessage,
    String? errorMessage,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      settings: settings ?? this.settings,
      storageStats: storageStats ?? this.storageStats,
      noticeMessage: noticeMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        settings,
        storageStats,
        noticeMessage,
        errorMessage,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsService _settingsService;
  final StorageManagementService _storageService;
  final DocumentRepository _docRepository;
  final ChatHistoryRepository _chatRepository;

  SettingsCubit({
    required this._settingsService,
    required this._storageService,
    required this._docRepository,
    required this._chatRepository,
  })  : super(SettingsState(settings: SettingsEntity.defaults()));

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final s = await _settingsService.getSettings();
      final stats = await _storageService.getStorageUsage();
      emit(state.copyWith(
        isLoading: false,
        settings: s,
        storageStats: stats,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      ));
    }
  }

  Future<void> updateSettings(SettingsEntity newSettings) async {
    try {
      await _settingsService.saveSettings(newSettings);
      emit(state.copyWith(
        settings: newSettings,
        noticeMessage: 'Settings saved successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save settings: $e'));
    }
  }

  Future<void> clearAllDocuments() async {
    try {
      await _docRepository.deleteAllDocuments();
      await _storageService.clearAllDocuments();
      final stats = await _storageService.getStorageUsage();
      emit(state.copyWith(
        storageStats: stats,
        noticeMessage: 'All local documents and chunks deleted.',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to clear documents: $e'));
    }
  }

  Future<void> clearAllChatHistory() async {
    try {
      await _chatRepository.clearAllChatHistory();
      emit(state.copyWith(noticeMessage: 'All chat history cleared.'));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to clear chat history: $e'));
    }
  }
}
