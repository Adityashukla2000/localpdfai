import 'package:equatable/equatable.dart';
import '../../../../core/constants/model_registry.dart';

enum ModelExecutionState {
  notDownloaded,
  downloading,
  ready,
  loading,
  loaded,
  error;
}

class ModelStatus extends Equatable {
  final ModelDescriptor descriptor;
  final ModelExecutionState state;
  final double downloadProgress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final String? localPath;

  const ModelStatus({
    required this.descriptor,
    required this.state,
    this.downloadProgress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.localPath,
  });

  String get formattedProgress => '${(downloadProgress * 100).toStringAsFixed(1)}%';

  ModelStatus copyWith({
    ModelDescriptor? descriptor,
    ModelExecutionState? state,
    double? downloadProgress,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    String? localPath,
  }) {
    return ModelStatus(
      descriptor: descriptor ?? this.descriptor,
      state: state ?? this.state,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  List<Object?> get props => [
        descriptor,
        state,
        downloadProgress,
        downloadedBytes,
        totalBytes,
        errorMessage,
        localPath,
      ];
}
