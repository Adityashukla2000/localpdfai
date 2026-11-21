import 'dart:async';
import 'package:llamadart/llamadart.dart';
import '../../../../core/constants/model_registry.dart';
import '../../../../core/errors/exceptions.dart';

/// Abstract engine contract for on-device inference.
abstract class InferenceEngine {
  bool get isLoaded;
  Future<void> load(String modelPath, ModelDescriptor descriptor);
  Stream<String> streamChat(String prompt, {double temperature = 0.3, int maxTokens = 512});
  Future<String> completeChat(String prompt, {double temperature = 0.3, int maxTokens = 512});
  Future<void> dispose();
}

/// Real native on-device llama.cpp inference engine powered by llamadart.
class LlamaCppInferenceEngine implements InferenceEngine {
  LlamaEngine? _engine;
  ChatSession? _session;
  bool _isLoaded = false;

  @override
  bool get isLoaded => _isLoaded;

  @override
  Future<void> load(String modelPath, ModelDescriptor descriptor) async {
    try {
      await dispose();

      _engine = LlamaEngine(LlamaBackend());
      await _engine!.setModel(
        LlamaModel(ModelSource.path(modelPath)),
        params: ModelParams(
          contextSize: descriptor.defaultContextLength,
          gpuLayers: 99, // Offload layers to Metal/Vulkan if supported, or CPU automatically
        ),
      );

      _session = ChatSession(
        _engine!,
        systemPrompt:
            'You are Local PDF AI Assistant. You answer questions strictly and accurately using the provided document excerpt context. '
            'Always cite the relevant page numbers. If the answer cannot be found in the excerpt, clearly state that evidence is missing.',
      );

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      throw InferenceException('Failed to initialize native llama.cpp model: $e');
    }
  }

  @override
  Stream<String> streamChat(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) {
    if (!_isLoaded || _session == null) {
      throw InferenceException('No local AI model is currently loaded in memory.');
    }

    try {
      final params = GenerationParams(
        temp: temperature,
        maxTokens: maxTokens,
      );

      return _session!.create(
        [LlamaTextContent(prompt)],
        params: params,
      ).textDeltas();
    } catch (e) {
      throw InferenceException('Inference error during generation: $e');
    }
  }

  @override
  Future<String> completeChat(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    final buffer = StringBuffer();
    await for (final token in streamChat(prompt, temperature: temperature, maxTokens: maxTokens)) {
      buffer.write(token);
    }
    return buffer.toString();
  }

  @override
  Future<void> dispose() async {
    try {
      if (_engine != null) {
        await _engine!.dispose();
        _engine = null;
      }
      _session = null;
      _isLoaded = false;
    } catch (_) {}
  }
}

/// Lightweight deterministic mock inference engine for testing, simulators,
/// and environments without native GGUF binaries.
class MockInferenceEngine implements InferenceEngine {
  bool _isLoaded = false;
  ModelDescriptor? _descriptor;

  @override
  bool get isLoaded => _isLoaded;
  ModelDescriptor? get loadedDescriptor => _descriptor;

  @override
  Future<void> load(String modelPath, ModelDescriptor descriptor) async {
    _descriptor = descriptor;
    // Simulate brief load latency
    await Future.delayed(const Duration(milliseconds: 250));
    _isLoaded = true;
  }

  @override
  Stream<String> streamChat(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) async* {
    if (!_isLoaded) {
      throw InferenceException('Mock model is not loaded.');
    }

    // Generate grounded response from prompt context
    final response = _synthesizeMockAnswer(prompt);
    final words = response.split(' ');

    for (int i = 0; i < words.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      yield i == 0 ? words[i] : ' ${words[i]}';
    }
  }

  @override
  Future<String> completeChat(
    String prompt, {
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    return _synthesizeMockAnswer(prompt);
  }

  String _synthesizeMockAnswer(String prompt) {
    // Check if prompt contains document evidence
    if (prompt.contains('No matching document sections found') ||
        prompt.contains('NO_EVIDENCE_FOUND')) {
      return 'Based on the provided document excerpts, this information could not be found. Please check your query or verify that the topic is discussed in the document.';
    }

    if (prompt.toLowerCase().contains('summarize') ||
        prompt.toLowerCase().contains('summary')) {
      return '### Summary of Document Content\n\n'
          'Based on the extracted text, the document covers several primary topics:\n\n'
          '1. **Key Findings**: The document outlines strategic initiatives, structured analyses, and key data points.\n'
          '2. **Actionable Details**: Specific sections highlight project requirements, timeline checkpoints, and operational parameters.\n'
          '3. **Conclusion**: The document establishes core guidelines and directives.\n\n'
          '*(Refer to Source Pages indicated in the citations below for full verification.)*';
    }

    return 'Based on the document excerpts provided, here is the answer to your question:\n\n'
        'The document specifically details the subject in the referenced sections. '
        'Key conditions, facts, and relevant guidelines have been identified and matched with high confidence.\n\n'
        '*(See attached citations for exact source page numbers and text excerpts.)*';
  }

  @override
  Future<void> dispose() async {
    _isLoaded = false;
    _descriptor = null;
  }
}
