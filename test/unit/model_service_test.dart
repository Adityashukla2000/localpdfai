import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/constants/model_registry.dart';
import 'package:local_pdf_ai/features/model_manager/data/services/inference_engine.dart';

void main() {
  group('InferenceEngine Unit Tests', () {
    late MockInferenceEngine engine;
    final descriptor = ModelRegistry.defaultModel;

    setUp(() {
      engine = MockInferenceEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('Initializes and loads mock inference engine', () async {
      expect(engine.isLoaded, isFalse);
      await engine.load('/path/to/mock.gguf', descriptor);
      expect(engine.isLoaded, isTrue);
    });

    test('Generates complete answer when prompt contains context', () async {
      await engine.load('/path/to/mock.gguf', descriptor);
      final response = await engine.completeChat(
        'User question with evidence in prompt: <document_context>[Page 1]: Revenue is 50M</document_context>',
      );
      expect(response, contains('document'));
    });

    test('Reports missing evidence when prompt contains NO_EVIDENCE_FOUND', () async {
      await engine.load('/path/to/mock.gguf', descriptor);
      final response = await engine.completeChat(
        '<document_context>[NO_EVIDENCE_FOUND]</document_context> What is the secret?',
      );
      expect(response, contains('could not be found'));
    });

    test('Streams tokens cleanly', () async {
      await engine.load('/path/to/mock.gguf', descriptor);
      final tokens = <String>[];
      await for (final token in engine.streamChat('Summarize this document.')) {
        tokens.add(token);
      }

      expect(tokens, isNotEmpty);
      expect(tokens.join('').length, greaterThan(20));
    });
  });
}
