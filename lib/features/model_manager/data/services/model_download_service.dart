import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/model_registry.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/storage_management_service.dart';

typedef DownloadProgressCallback = void Function(
  int receivedBytes,
  int totalBytes,
  double progress,
);

/// Service managing GGUF model downloads, atomic saving, and cancellation.
class ModelDownloadService {
  final Dio _dio;
  final StorageManagementService _storageService;

  ModelDownloadService(this._storageService, {Dio? dio}) : _dio = dio ?? Dio();

  /// Downloads a GGUF model with progress reporting and cancellation support.
  Future<File> downloadModel(
    ModelDescriptor model, {
    DownloadProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final modelsDir = await _storageService.getModelsDirectory();
    final targetFilePath = p.join(modelsDir.path, model.fileName);
    final tempFilePath = '$targetFilePath.tmp';

    final tempFile = File(tempFilePath);
    final targetFile = File(targetFilePath);

    // If already downloaded and complete, return target file
    if (await targetFile.exists()) {
      final existingLength = await targetFile.length();
      if (existingLength > 0) {
        return targetFile;
      }
    }

    try {
      // Ensure temp file is clean
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final response = await _dio.download(
        model.downloadUrl,
        tempFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          // If server didn't send Content-Length, fallback to descriptor size
          final totalEffective = total > 0 ? total : model.fileSizeBytes;
          final progress = (received / totalEffective).clamp(0.0, 1.0);
          onProgress?.call(received, totalEffective, progress);
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'User-Agent': 'Local-PDF-AI-Assistant/1.0',
          },
        ),
      );

      if (response.statusCode != null &&
          (response.statusCode! < 200 || response.statusCode! >= 300)) {
        throw ModelDownloadException(
          'Download failed with HTTP status: ${response.statusCode}',
        );
      }

      if (!await tempFile.exists()) {
        throw ModelDownloadException(
          'Downloaded model file was not written to storage.',
        );
      }

      final downloadedSize = await tempFile.length();
      if (downloadedSize == 0) {
        throw ModelDownloadException(
          'Downloaded model file is empty (0 bytes).',
        );
      }

      // Rename temp file to target file atomically
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tempFile.rename(targetFilePath);

      return targetFile;
    } on DioException catch (e) {
      // Clean up partial temp file
      if (await tempFile.exists()) {
        await tempFile.delete().catchError((_) => tempFile);
      }

      if (CancelToken.isCancel(e)) {
        throw ModelDownloadException('Download was cancelled by user.', code: 'CANCELLED');
      }

      throw ModelDownloadException(
        'Network error downloading model: ${e.message ?? e.toString()}',
      );
    } catch (e) {
      if (await tempFile.exists()) {
        await tempFile.delete().catchError((_) => tempFile);
      }
      if (e is ModelDownloadException) rethrow;
      throw ModelDownloadException('Failed to download model: $e');
    }
  }

  /// Cancels an active download.
  void cancelDownload(CancelToken cancelToken) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled download.');
    }
  }
}
