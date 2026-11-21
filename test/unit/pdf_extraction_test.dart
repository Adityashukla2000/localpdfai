import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/documents/data/services/pdf_extraction_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  late PdfExtractionService extractionService;
  late Directory tempDir;

  setUp(() async {
    extractionService = PdfExtractionService();
    tempDir = await Directory.systemTemp.createTemp('pdf_extract_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PdfExtractionService Unit Tests', () {
    test('Throws DocumentException when file does not exist', () async {
      final nonExistent = File('${tempDir.path}/missing.pdf');
      expect(
        () => extractionService.extractText(nonExistent),
        throwsA(isA<DocumentException>()),
      );
    });

    test('Throws DocumentException when file is 0 bytes', () async {
      final emptyFile = File('${tempDir.path}/empty.pdf');
      await emptyFile.writeAsBytes([]);

      expect(
        () => extractionService.extractText(emptyFile),
        throwsA(isA<DocumentException>()),
      );
    });

    test('Successfully extracts pages and detects selectable text from a valid PDF', () async {
      final testFile = File('${tempDir.path}/sample.pdf');

      // Create a 2-page PDF document
      final document = PdfDocument();
      
      // Page 1
      final page1 = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      page1.graphics.drawString(
        'First Page Content: Clean Architecture in Flutter with On-Device AI models.',
        font,
        bounds: const Rect.fromLTWH(20, 20, 400, 50),
      );

      // Page 2
      final page2 = document.pages.add();
      page2.graphics.drawString(
        'Second Page Content: Retrieval Augmented Generation with offline embeddings.',
        font,
        bounds: const Rect.fromLTWH(20, 20, 400, 50),
      );

      final bytes = await document.save();
      document.dispose();
      await testFile.writeAsBytes(bytes);

      int progressUpdates = 0;
      final result = await extractionService.extractText(
        testFile,
        onProgress: (current, total) {
          progressUpdates++;
          expect(current, inInclusiveRange(1, total));
        },
      );

      expect(result.pageCount, 2);
      expect(result.pages.length, 2);
      expect(result.pages[0].pageNumber, 1);
      expect(result.pages[0].text, contains('Clean Architecture'));
      expect(result.pages[1].pageNumber, 2);
      expect(result.pages[1].text, contains('Retrieval Augmented Generation'));
      expect(result.hasSelectableText, isTrue);
      expect(result.totalCharacters, greaterThan(20));
      expect(progressUpdates, 2);
    });
  });
}
