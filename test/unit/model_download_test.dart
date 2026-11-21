import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/constants/model_registry.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/core/storage/storage_management_service.dart';
import 'package:local_pdf_ai/features/model_manager/data/services/model_download_service.dart';

class TestStorageManagementService extends StorageManagementService {
  final Directory tempDirectory;
  TestStorageManagementService(this.tempDirectory);

  @override
  Future<Directory> getModelsDirectory() async {
    final dir = Directory('${tempDirectory.path}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

class FakeHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) onFetch;
  FakeHttpClientAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;
  late TestStorageManagementService storageService;
  late ModelDescriptor testModel;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_service_test_');
    storageService = TestStorageManagementService(tempDir);
    testModel = const ModelDescriptor(
      id: 'test_model',
      name: 'Test Model',
      fileName: 'test-model.gguf',
      fileSizeBytes: 1000,
      minRamMb: 500,
      defaultContextLength: 2048,
      downloadUrl: 'https://huggingface.co/test/model.gguf',
      quantization: 'Q4_K_M',
      license: 'Apache-2.0',
      description: 'Test GGUF Model',
      isRecommended: true,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ModelDownloadService Unit Tests', () {
    test('Returns existing file immediately if already downloaded and non-empty', () async {
      final modelsDir = await storageService.getModelsDirectory();
      final targetFile = File('${modelsDir.path}/${testModel.fileName}');
      await targetFile.writeAsString('EXISTING_GGUF_CONTENT');

      final downloadService = ModelDownloadService(storageService);
      final downloaded = await downloadService.downloadModel(testModel);

      expect(downloaded.path, targetFile.path);
      expect(await downloaded.readAsString(), 'EXISTING_GGUF_CONTENT');
    });

    test('Downloads file successfully, calculates progress, and creates target atomically', () async {
      final dio = Dio();
      final streamBytes = Uint8List.fromList(List.generate(500, (i) => i % 256));

      dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        return ResponseBody(
          Stream.value(streamBytes),
          200,
          headers: {
            Headers.contentLengthHeader: [streamBytes.length.toString()],
          },
        );
      });

      final downloadService = ModelDownloadService(storageService, dio: dio);

      final progressList = <double>[];
      final file = await downloadService.downloadModel(
        testModel,
        onProgress: (received, total, progress) {
          progressList.add(progress);
        },
      );

      expect(await file.exists(), isTrue);
      expect(await file.length(), 500);
      expect(progressList.isNotEmpty, isTrue);

      // Verify temp file .tmp is cleaned up
      final tempFile = File('${file.path}.tmp');
      expect(await tempFile.exists(), isFalse);
    });

    test('Handles cancellation gracefully and cleans up partial temp file', () async {
      final dio = Dio();
      final cancelToken = CancelToken();

      dio.httpClientAdapter = FakeHttpClientAdapter((options) {
        final controller = StreamController<Uint8List>();
        // Feed partial bytes then cancel
        controller.add(Uint8List.fromList([1, 2, 3, 4]));
        cancelToken.cancel('Cancelled during transfer');
        controller.close();

        return ResponseBody(
          controller.stream,
          200,
          headers: {
            Headers.contentLengthHeader: ['1000'],
          },
        );
      });

      final downloadService = ModelDownloadService(storageService, dio: dio);

      expect(
        () => downloadService.downloadModel(testModel, cancelToken: cancelToken),
        throwsA(
          predicate<ModelDownloadException>(
            (e) => e.code == 'CANCELLED',
          ),
        ),
      );

      final modelsDir = await storageService.getModelsDirectory();
      final tempFile = File('${modelsDir.path}/${testModel.fileName}.tmp');
      expect(await tempFile.exists(), isFalse);
    });
  });
}
