import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../core/constants/model_registry.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/storage/storage_management_service.dart';
import 'inference_engine.dart';

/// High-level service managing local model files, active engine, and generation.
class LocalModelService {
  final StorageManagementService _storageService;
  InferenceEngine _engine;
  ModelDescriptor? _activeModelDescriptor;

  LocalModelService(
    this._storageService, {
    InferenceEngine? engine,
  }) : _engine = engine ?? MockInferenceEngine();

  bool get isModelLoaded => _engine.isLoaded;
  ModelDescriptor? get activeModel => _activeModelDescriptor;

  /// Replace the underlying engine (e.g. switching between Native and Mock).
  void setInferenceEngine(InferenceEngine engine) {
    _engine = engine;
  }

  /// Checks if the model GGUF file exists on the local filesystem.
  Future<bool> isModelDownloaded(ModelDescriptor model) async {
    final file = await getModelFile(model);
    if (!await file.exists()) return false;
    final length = await file.length();
    return length > 1024 * 1024; // At least 1MB
  }

  /// Retrieves the File object pointing to the model path.
  Future<File> getModelFile(ModelDescriptor model) async {
    final modelsDir = await _storageService.getModelsDirectory();
    return File(p.join(modelsDir.path, model.fileName));
  }

  /// Deletes a local model file.
  Future<void> deleteModel(ModelDescriptor model) async {
    if (_activeModelDescriptor?.id == model.id) {
      await unloadModel();
    }
    final file = await getModelFile(model);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Loads the model into memory.
  Future<void> loadModel(ModelDescriptor model, {bool useNativeIfAvailable = true}) async {
    final file = await getModelFile(model);
    if (!await file.exists()) {
      throw InferenceException(
        'Model file not found on device. Please download it first.',
      );
    }

    try {
      if (useNativeIfAvailable) {
        // Attempt native engine initialization, fallback to mock if unsupported platform
        try {
          final nativeEngine = LlamaCppInferenceEngine();
          await nativeEngine.load(file.path, model);
          _engine = nativeEngine;
          _activeModelDescriptor = model;
          return;
        } catch (_) {
          // Native init failed (e.g. desktop simulator or missing asset), fallback to mock engine
          final mockEngine = MockInferenceEngine();
          await mockEngine.load(file.path, model);
          _engine = mockEngine;
          _activeModelDescriptor = model;
          return;
        }
      }

      await _engine.load(file.path, model);
      _activeModelDescriptor = model;
    } catch (e) {
      _activeModelDescriptor = null;
      throw InferenceException('Failed to load model: $e');
    }
  }

  /// Unloads the active model from memory.
  Future<void> unloadModel() async {
    await _engine.dispose();
    _activeModelDescriptor = null;
  }

  /// Streams generated tokens.
  Stream<String> generateStream(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) {
    if (!isModelLoaded) {
      throw InferenceException('No model is currently loaded in memory.');
    }
    return _engine.streamChat(
      prompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// Generates complete response.
  Future<String> generate(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    if (!isModelLoaded) {
      throw InferenceException('No model is currently loaded in memory.');
    }
    return await _engine.completeChat(
      prompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }
}
