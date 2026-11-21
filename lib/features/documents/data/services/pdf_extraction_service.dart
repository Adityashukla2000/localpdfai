import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/text_normalizer.dart';

/// Extracted page model.
class ExtractedPage {
  final int pageNumber;
  final String text;

  const ExtractedPage({
    required this.pageNumber,
    required this.text,
  });
}

/// Complete extraction result with metadata.
class PdfExtractionResult {
  final int pageCount;
  final List<ExtractedPage> pages;
  final int totalCharacters;
  final bool hasSelectableText;

  const PdfExtractionResult({
    required this.pageCount,
    required this.pages,
    required this.totalCharacters,
    required this.hasSelectableText,
  });
}

/// Service for extracting text from PDF files page-by-page.
class PdfExtractionService {
  /// Extracts text page by page with progress callback.
  /// Handles password-protection, corrupted files, and scanned detection.
  Future<PdfExtractionResult> extractText(
    File pdfFile, {
    void Function(int currentPage, int totalPages)? onProgress,
  }) async {
    if (!await pdfFile.exists()) {
      throw DocumentException('PDF file not found at path: ${pdfFile.path}');
    }

    PdfDocument? document;
    try {
      final bytes = await pdfFile.readAsBytes();
      if (bytes.isEmpty) {
        throw DocumentException('PDF file is empty (0 bytes).');
      }

      try {
        document = PdfDocument(inputBytes: bytes);
      } catch (e) {
        final err = e.toString().toLowerCase();
        if (err.contains('password') || err.contains('encrypted')) {
          throw DocumentException(
            'The PDF is password protected. Password-protected documents are not supported.',
            code: 'PASSWORD_PROTECTED',
          );
        }
        throw DocumentException('Corrupted or invalid PDF document: $e');
      }

      final pageCount = document.pages.count;
      if (pageCount == 0) {
        throw DocumentException('PDF contains no readable pages.');
      }

      final pages = <ExtractedPage>[];
      int totalChars = 0;
      final extractor = PdfTextExtractor(document);

      for (int i = 0; i < pageCount; i++) {
        final pageNum = i + 1;
        onProgress?.call(pageNum, pageCount);

        // Extract single page text
        String rawPageText = '';
        try {
          rawPageText = extractor.extractText(
            startPageIndex: i,
            endPageIndex: i,
          );
        } catch (_) {
          rawPageText = '';
        }

        final normalized = TextNormalizer.normalize(rawPageText);
        totalChars += normalized.length;
        pages.add(ExtractedPage(pageNumber: pageNum, text: normalized));
      }

      // Check if document has selectable text or is likely a scanned image PDF
      final hasSelectableText = totalChars > 20;

      return PdfExtractionResult(
        pageCount: pageCount,
        pages: pages,
        totalCharacters: totalChars,
        hasSelectableText: hasSelectableText,
      );
    } catch (e) {
      if (e is DocumentException) rethrow;
      throw DocumentException('Failed to extract text from PDF: $e');
    } finally {
      document?.dispose();
    }
  }
}
