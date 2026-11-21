import 'package:equatable/equatable.dart';

/// Source citation linking an answer to a specific document page and text excerpt.
class SourceCitation extends Equatable {
  final int pageNumber;
  final String excerpt;
  final double score;

  const SourceCitation({
    required this.pageNumber,
    required this.excerpt,
    this.score = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'page_number': pageNumber,
      'excerpt': excerpt,
      'score': score,
    };
  }

  factory SourceCitation.fromMap(Map<String, dynamic> map) {
    return SourceCitation(
      pageNumber: map['page_number'] as int,
      excerpt: map['excerpt'] as String,
      score: (map['score'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  List<Object?> get props => [pageNumber, excerpt, score];
}
