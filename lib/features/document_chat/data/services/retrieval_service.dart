import 'dart:math';
import 'package:local_pdf_ai/core/constants/app_constants.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_chunk_entity.dart';

/// A document chunk paired with its relevance retrieval score.
class ScoredChunk {
  final DocumentChunkEntity chunk;
  final double score;

  const ScoredChunk({
    required this.chunk,
    required this.score,
  });
}

/// Abstract contract for local retrieval engines (enabling keyword or future vector embeddings).
abstract class RetrievalEngine {
  Future<List<ScoredChunk>> retrieve({
    required String query,
    required List<DocumentChunkEntity> chunks,
    int topK = AppConstants.defaultTopKRetrieval,
    double minScore = AppConstants.minKeywordScore,
  });
}

/// Robust BM25-based keyword retrieval engine with stopword removal and phrase boosting.
class KeywordRetrievalService implements RetrievalEngine {
  static const Set<String> _stopwords = {
    'a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
    'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
    'do', 'does', 'did', 'and', 'or', 'but', 'if', 'then', 'else', 'when',
    'where', 'why', 'how', 'all', 'any', 'both', 'each', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own',
    'same', 'so', 'than', 'too', 'very', 'can', 'will', 'just', 'should',
    'now', 'what', 'which', 'who', 'whom', 'this', 'that', 'these', 'those',
    'from', 'as', 'into', 'about', 'tell', 'me', 'please', 'give', 'list',
  };

  @override
  Future<List<ScoredChunk>> retrieve({
    required String query,
    required List<DocumentChunkEntity> chunks,
    int topK = AppConstants.defaultTopKRetrieval,
    double minScore = AppConstants.minKeywordScore,
  }) async {
    if (chunks.isEmpty) return [];

    final cleanQuery = query.toLowerCase();
    final queryTokens = _tokenize(cleanQuery);
    if (queryTokens.isEmpty) return [];

    final totalChunks = chunks.length;
    final double avgChunkLen = chunks.fold<int>(0, (sum, c) => sum + c.content.length) / totalChunks;

    // 1. Calculate Document Frequency for each query token
    final df = <String, int>{};
    for (final token in queryTokens) {
      int count = 0;
      for (final chunk in chunks) {
        if (chunk.content.toLowerCase().contains(token)) {
          count++;
        }
      }
      df[token] = count;
    }

    // 2. BM25 Parameters
    const k1 = 1.2;
    const b = 0.75;

    final scoredChunks = <ScoredChunk>[];

    for (final chunk in chunks) {
      final chunkText = chunk.content.toLowerCase();
      final chunkLen = chunk.content.length;
      double score = 0.0;

      for (final token in queryTokens) {
        final docFreq = df[token] ?? 0;
        if (docFreq == 0) continue;

        // IDF component
        final idf = log(1.0 + (totalChunks - docFreq + 0.5) / (docFreq + 0.5));

        // TF component (count occurrences in chunk)
        final matches = RegExp(r'\b' + RegExp.escape(token) + r'\b').allMatches(chunkText);
        final tf = matches.length;
        if (tf == 0) continue;

        final tfWeight = (tf * (k1 + 1.0)) / (tf + k1 * (1.0 - b + b * (chunkLen / avgChunkLen)));
        score += idf * tfWeight;
      }

      // Bonus for exact query substring match
      if (cleanQuery.length > 3 && chunkText.contains(cleanQuery)) {
        score += 3.0;
      }

      if (score >= minScore) {
        scoredChunks.add(ScoredChunk(chunk: chunk, score: score));
      }
    }

    // Sort descending by relevance score
    scoredChunks.sort((a, b) => b.score.compareTo(a.score));

    return scoredChunks.take(topK).toList();
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopwords.contains(t))
        .toSet() // Unique terms
        .toList();
  }
}
