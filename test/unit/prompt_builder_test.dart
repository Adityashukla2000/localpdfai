import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/prompt_builder_service.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/retrieval_service.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_chunk_entity.dart';

void main() {
  group('PromptBuilderService Unit Tests', () {
    late PromptBuilderService promptBuilder;

    setUp(() {
      promptBuilder = PromptBuilderService();
    });

    test('Constructs grounded prompt containing chunks and page metadata', () {
      final scoredChunks = [
        const ScoredChunk(
          chunk: DocumentChunkEntity(
            id: 'c1',
            documentId: 'd1',
            chunkIndex: 0,
            pageNumber: 4,
            content: 'The total acquisition price was 12.5 million dollars.',
            charStart: 0,
            charEnd: 54,
          ),
          score: 2.5,
        ),
      ];

      final result = promptBuilder.buildGroundedPrompt(
        question: 'How much was the acquisition?',
        retrievedChunks: scoredChunks,
      );

      expect(result.systemPrompt, contains('SECURITY DEFENSE'));
      expect(result.userPrompt, contains('<document_context>'));
      expect(result.userPrompt, contains('[Page 4]:'));
      expect(result.userPrompt, contains('12.5 million dollars'));
      expect(result.userPrompt, contains('User Question: How much was the acquisition?'));
      expect(result.includedChunks.length, equals(1));
    });

    test('Generates missing evidence notice when retrievedChunks is empty', () {
      final result = promptBuilder.buildGroundedPrompt(
        question: 'What is the secret formula?',
        retrievedChunks: const [],
      );

      expect(result.userPrompt, contains('[NO_EVIDENCE_FOUND]'));
      expect(result.includedChunks, isEmpty);
    });

    test('Builds summarization prompt with requested type', () {
      final prompt = promptBuilder.buildSummarizationPrompt(
        documentName: 'AnnualReport.pdf',
        sectionText: 'Financial summary text goes here.',
        pageStart: 1,
        pageEnd: 10,
        summaryType: 'key_points',
      );

      expect(prompt, contains('AnnualReport.pdf'));
      expect(prompt, contains('Pages 1 to 10'));
      expect(prompt, contains('Extract bullet points'));
    });
  });
}
