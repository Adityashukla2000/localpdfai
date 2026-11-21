import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/retrieval_service.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_chunk_entity.dart';

void main() {
  group('KeywordRetrievalService Unit Tests', () {
    late KeywordRetrievalService service;
    late List<DocumentChunkEntity> testChunks;

    setUp(() {
      service = KeywordRetrievalService();
      testChunks = const [
        DocumentChunkEntity(
          id: 'chunk-1',
          documentId: 'doc-1',
          chunkIndex: 0,
          pageNumber: 1,
          content: 'The fiscal year 2024 revenue reached 50 million dollars with strong growth.',
          charStart: 0,
          charEnd: 75,
        ),
        DocumentChunkEntity(
          id: 'chunk-2',
          documentId: 'doc-1',
          chunkIndex: 1,
          pageNumber: 2,
          content: 'Employee headcount increased in the engineering and product management teams.',
          charStart: 76,
          charEnd: 155,
        ),
        DocumentChunkEntity(
          id: 'chunk-3',
          documentId: 'doc-1',
          chunkIndex: 2,
          pageNumber: 3,
          content: 'Risk factors include supply chain delays and foreign currency exchange fluctuations.',
          charStart: 156,
          charEnd: 240,
        ),
      ];
    });

    test('Retrieves and ranks relevant chunk for query', () async {
      final results = await service.retrieve(
        query: 'What was the fiscal revenue?',
        chunks: testChunks,
      );

      expect(results, isNotEmpty);
      expect(results.first.chunk.id, equals('chunk-1'));
      expect(results.first.chunk.pageNumber, equals(1));
      expect(results.first.score, greaterThan(0.05));
    });

    test('Ranks supply chain risk chunk highest for risk query', () async {
      final results = await service.retrieve(
        query: 'supply chain risk delays',
        chunks: testChunks,
      );

      expect(results, isNotEmpty);
      expect(results.first.chunk.id, equals('chunk-3'));
      expect(results.first.chunk.pageNumber, equals(3));
    });

    test('Returns empty list when query keywords do not match any chunk', () async {
      final results = await service.retrieve(
        query: 'quantum cryptography spacecraft satellite',
        chunks: testChunks,
      );

      expect(results, isEmpty);
    });
  });
}
