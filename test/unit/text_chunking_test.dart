import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/features/documents/data/services/pdf_extraction_service.dart';
import 'package:local_pdf_ai/features/documents/data/services/text_chunking_service.dart';

void main() {
  group('TextChunkingService Unit Tests', () {
    late TextChunkingService chunkingService;

    setUp(() {
      chunkingService = TextChunkingService();
    });

    test('Produces single chunk when text is smaller than chunkSize', () {
      final pages = [
        const ExtractedPage(pageNumber: 1, text: 'Short introductory paragraph.'),
      ];

      final chunks = chunkingService.chunkPages(
        documentId: 'doc-123',
        pages: pages,
        chunkSize: 100,
        overlap: 20,
      );

      expect(chunks.length, equals(1));
      expect(chunks.first.pageNumber, equals(1));
      expect(chunks.first.content, equals('Short introductory paragraph.'));
      expect(chunks.first.documentId, equals('doc-123'));
    });

    test('Splits long text across multiple overlapping chunks and preserves pages', () {
      final longText = 'Sentence one is about the company strategy. ' * 10;
      final pages = [
        ExtractedPage(pageNumber: 1, text: longText),
        const ExtractedPage(pageNumber: 2, text: 'This is on page two.'),
      ];

      final chunks = chunkingService.chunkPages(
        documentId: 'doc-123',
        pages: pages,
        chunkSize: 150,
        overlap: 30,
      );

      expect(chunks.length, greaterThan(1));
      expect(chunks.any((c) => c.pageNumber == 1), isTrue);
      expect(chunks.any((c) => c.pageNumber == 2), isTrue);
      // Ensure monotonic chunkIndex
      for (int i = 0; i < chunks.length; i++) {
        expect(chunks[i].chunkIndex, equals(i));
      }
    });

    test('Handles empty pages gracefully', () {
      final pages = [
        const ExtractedPage(pageNumber: 1, text: '   '),
        const ExtractedPage(pageNumber: 2, text: ''),
      ];

      final chunks = chunkingService.chunkPages(
        documentId: 'doc-123',
        pages: pages,
      );

      expect(chunks, isEmpty);
    });
  });
}
