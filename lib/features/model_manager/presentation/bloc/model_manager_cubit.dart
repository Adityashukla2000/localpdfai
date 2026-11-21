import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/model_registry.dart';
import '../../data/services/local_model_service.dart';
import '../../data/services/model_download_service.dart';
import '../../domain/models/model_status.dart';

class ModelManagerState extends Equatable {
  final bool isLoading;
  final List<ModelStatus> models;
  final String? activeModelId;
  final bool isDownloading;
  final String? downloadingModelId;
  final double currentDownloadProgress;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final String? operationNotice;

  const ModelManagerState({
    this.isLoading = false,
    this.models = const [],
    this.activeModelId,
    this.isDownloading = false,
    this.downloadingModelId,
    this.currentDownloadProgress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.operationNotice,
  });

  ModelManagerState copyWith({
    bool? isLoading,
    List<ModelStatus>? models,
    String? activeModelId,
    bool? isDownloading,
    String? downloadingModelId,
    double? currentDownloadProgress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    String? operationNotice,
  }) {
    return ModelManagerState(
      isLoading: isLoading ?? this.isLoading,
      models: models ?? this.models,
      activeModelId: activeModelId ?? this.activeModelId,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadingModelId: downloadingModelId ?? this.downloadingModelId,
      currentDownloadProgress:
          currentDownloadProgress ?? this.currentDownloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage,
      operationNotice: operationNotice,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        models,
        activeModelId,
        isDownloading,
        downloadingModelId,
        currentDownloadProgress,
        downloadedBytes,
        totalBytes,
        errorMessage,
        operationNotice,
      ];
}

class ModelManagerCubit extends Cubit<ModelManagerState> {
  final ModelDownloadService _downloadService;
  final LocalModelService _modelService;
  CancelToken? _activeCancelToken;

  ModelManagerCubit({
    required this._downloadService,
    required this._modelService,
  })  : super(const ModelManagerState());

  Future<void> loadModels() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final statuses = <ModelStatus>[];
      for (final descriptor in ModelRegistry.availableModels) {
        final downloaded = await _modelService.isModelDownloaded(descriptor);
        final file = await _modelService.getModelFile(descriptor);

        ModelExecutionState execState = ModelExecutionState.notDownloaded;
        if (downloaded) {
          if (_modelService.activeModel?.id == descriptor.id &&
              _modelService.isModelLoaded) {
            execState = ModelExecutionState.loaded;
          } else {
            execState = ModelExecutionState.ready;
          }
        }

        statuses.add(ModelStatus(
          descriptor: descriptor,
          state: execState,
          localPath: downloaded ? file.path : null,
        ));
      }

      emit(state.copyWith(
        isLoading: false,
        models: statuses,
        activeModelId: _modelService.activeModel?.id ?? ModelRegistry.defaultModel.id,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to inspect models: $e',
      ));
    }
  }

  Future<void> downloadModel(ModelDescriptor model) async {
    if (state.isDownloading) return;

    _activeCancelToken = CancelToken();
    emit(state.copyWith(
      isDownloading: true,
      downloadingModelId: model.id,
      currentDownloadProgress: 0.0,
      downloadedBytes: 0,
      totalBytes: model.fileSizeBytes,
      errorMessage: null,
      operationNotice: 'Starting download for ${model.name}...',
    ));

    try {
      await _downloadService.downloadModel(
        model,
        cancelToken: _activeCancelToken,
        onProgress: (received, total, progress) {
          emit(state.copyWith(
            currentDownloadProgress: progress,
            downloadedBytes: received,
            totalBytes: total,
            operationNotice:
                'Downloading ${model.name}: ${(progress * 100).toStringAsFixed(1)}%',
          ));
        },
      );

      // Auto-load model into memory after successful download
      await _modelService.loadModel(model);

      emit(state.copyWith(
        isDownloading: false,
        downloadingModelId: null,
        currentDownloadProgress: 1.0,
        operationNotice: '${model.name} downloaded and ready for inference!',
      ));

      await loadModels();
    } catch (e) {
      emit(state.copyWith(
        isDownloading: false,
        downloadingModelId: null,
        operationNotice: null,
        errorMessage: e.toString(),
      ));
      await loadModels();
    } finally {
      _activeCancelToken = null;
    }
  }

  void cancelDownload() {
    if (_activeCancelToken != null && !_activeCancelToken!.isCancelled) {
      _downloadService.cancelDownload(_activeCancelToken!);
      emit(state.copyWith(
        isDownloading: false,
        downloadingModelId: null,
        operationNotice: 'Download cancelled.',
      ));
    }
  }

  Future<void> loadModelIntoMemory(ModelDescriptor model) async {
    emit(state.copyWith(
      operationNotice: 'Loading ${model.name} into device memory...',
      errorMessage: null,
    ));
    try {
      await _modelService.loadModel(model);
      emit(state.copyWith(
        activeModelId: model.id,
        operationNotice: '${model.name} loaded successfully.',
      ));
      await loadModels();
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to load model into memory: $e',
        operationNotice: null,
      ));
    }
  }

  Future<void> unloadModel() async {
    try {
      await _modelService.unloadModel();
      emit(state.copyWith(operationNotice: 'Model unloaded from memory.'));
      await loadModels();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to unload model: $e'));
    }
  }

  Future<void> deleteModel(ModelDescriptor model) async {
    try {
      await _modelService.deleteModel(model);
      emit(state.copyWith(operationNotice: 'Deleted ${model.name}.'));
      await loadModels();
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete model: $e'));
    }
  }
}
