/// Utility for cleaning and standardizing extracted PDF text.
class TextNormalizer {
  /// Cleans and normalizes extracted text:
  /// - Merges hyphenated linebreaks ("infor-\nmation" -> "information")
  /// - Collapses multiple spaces and tabs into single space
  /// - Preserves paragraph breaks (double newlines) while removing spurious line breaks
  /// - Strips non-printable ASCII control characters (except \n, \r, \t)
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // 1. Remove non-printable control characters except \t, \n, \r
    var cleaned = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // 2. Unify carriage returns to standard newlines
    cleaned = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 3. Fix hyphenated words broken across lines: e.g. "comput-\ner" -> "computer"
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(\b[a-zA-Z]{2,})-\n([a-zA-Z]{2,}\b)'),
      (match) => '${match.group(1)}${match.group(2)}',
    );

    // 4. Collapse 3+ newlines to standard double newline (paragraph boundary)
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 5. Replace multiple whitespace within lines with a single space
    final lines = cleaned.split('\n');
    final normalizedLines = lines.map((line) {
      return line.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
    });

    return normalizedLines.join('\n').trim();
  }
}
