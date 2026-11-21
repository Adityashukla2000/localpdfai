import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/document_chunk_entity.dart';
import 'pdf_extraction_service.dart';

/// Service responsible for splitting extracted pages into overlapping, page-aware chunks.
class TextChunkingService {
  final Uuid _uuid = const Uuid();

  /// Creates chunks from extracted PDF pages.
  /// Uses sentence/punctuation-aware boundaries when possible.
  List<DocumentChunkEntity> chunkPages({
    required String documentId,
    required List<ExtractedPage> pages,
    int chunkSize = AppConstants.defaultChunkSize,
    int overlap = AppConstants.defaultChunkOverlap,
  }) {
    if (pages.isEmpty) return [];

    final chunks = <DocumentChunkEntity>[];
    int globalChunkIndex = 0;

    for (final page in pages) {
      final text = page.text.trim();
      if (text.isEmpty) continue;

      if (text.length <= chunkSize) {
        chunks.add(DocumentChunkEntity(
          id: _uuid.v4(),
          documentId: documentId,
          chunkIndex: globalChunkIndex++,
          pageNumber: page.pageNumber,
          content: text,
          charStart: 0,
          charEnd: text.length,
        ));
        continue;
      }

      int start = 0;
      while (start < text.length) {
        int end = start + chunkSize;
        if (end >= text.length) {
          end = text.length;
        } else {
          // Attempt to break at the nearest sentence or line boundary within the last 80 chars
          final lookbackStart = (end - 80).clamp(start, end);
          final slice = text.substring(lookbackStart, end);
          final boundaryMatch = RegExp(r'[\.\n\?!;]\s').allMatches(slice);
          if (boundaryMatch.isNotEmpty) {
            final lastMatch = boundaryMatch.last;
            end = lookbackStart + lastMatch.start + 1;
          }
        }

        final chunkContent = text.substring(start, end).trim();
        if (chunkContent.isNotEmpty) {
          chunks.add(DocumentChunkEntity(
            id: _uuid.v4(),
            documentId: documentId,
            chunkIndex: globalChunkIndex++,
            pageNumber: page.pageNumber,
            content: chunkContent,
            charStart: start,
            charEnd: end,
          ));
        }

        if (end >= text.length) break;

        // Slide forward by chunkSize - overlap
        final step = chunkSize - overlap;
        start += step > 0 ? step : chunkSize;
      }
    }

    return chunks;
  }
}
