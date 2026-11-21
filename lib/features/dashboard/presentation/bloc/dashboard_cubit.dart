import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/model_registry.dart';
import '../../../../core/storage/storage_management_service.dart';
import '../../../documents/domain/models/document_entity.dart';
import '../../../documents/domain/repositories/document_repository.dart';
import '../../../model_manager/data/services/local_model_service.dart';
import '../../../model_manager/domain/models/model_status.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final List<DocumentEntity> recentDocuments;
  final ModelStatus activeModelStatus;
  final StorageUsageStats? storageStats;
  final String? errorMessage;

  const DashboardState({
    this.isLoading = false,
    this.recentDocuments = const [],
    required this.activeModelStatus,
    this.storageStats,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    List<DocumentEntity>? recentDocuments,
    ModelStatus? activeModelStatus,
    StorageUsageStats? storageStats,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      recentDocuments: recentDocuments ?? this.recentDocuments,
      activeModelStatus: activeModelStatus ?? this.activeModelStatus,
      storageStats: storageStats ?? this.storageStats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        recentDocuments,
        activeModelStatus,
        storageStats,
        errorMessage,
      ];
}

class DashboardCubit extends Cubit<DashboardState> {
  final DocumentRepository _docRepository;
  final LocalModelService _modelService;
  final StorageManagementService _storageService;

  DashboardCubit({
    required this._docRepository,
    required this._modelService,
    required this._storageService,
  })  : super(
          DashboardState(
            isLoading: true,
            activeModelStatus: ModelStatus(
              descriptor: ModelRegistry.defaultModel,
              state: ModelExecutionState.notDownloaded,
            ),
          ),
        );

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final docs = await _docRepository.getAllDocuments();
      final stats = await _storageService.getStorageUsage();

      final defaultModel = ModelRegistry.defaultModel;
      final isDownloaded = await _modelService.isModelDownloaded(defaultModel);

      ModelExecutionState modelState = ModelExecutionState.notDownloaded;
      if (isDownloaded) {
        modelState = _modelService.isModelLoaded
            ? ModelExecutionState.loaded
            : ModelExecutionState.ready;
      }

      emit(state.copyWith(
        isLoading: false,
        recentDocuments: docs,
        storageStats: stats,
        activeModelStatus: ModelStatus(
          descriptor: _modelService.activeModel ?? defaultModel,
          state: modelState,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard: $e',
      ));
    }
  }
}
