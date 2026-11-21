import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer Unit Tests', () {
    test('Cleans control characters and normalizes carriage returns', () {
      const input = 'Hello\x00 World\r\nThis is a test\rwith carriage return.';
      final output = TextNormalizer.normalize(input);
      expect(output, contains('Hello World'));
      expect(output, contains('This is a test\nwith carriage return.'));
      expect(output.contains('\x00'), isFalse);
    });

    test('Merges hyphenated line wraps into full words', () {
      const input = 'This is an impor-\ntant docu-\nmentation file.';
      final output = TextNormalizer.normalize(input);
      expect(output, contains('important'));
      expect(output, contains('documentation'));
    });

    test('Collapses excessive blank lines to standard paragraph breaks', () {
      const input = 'Paragraph 1\n\n\n\n\nParagraph 2';
      final output = TextNormalizer.normalize(input);
      expect(output, equals('Paragraph 1\n\nParagraph 2'));
    });

    test('Handles empty strings gracefully', () {
      expect(TextNormalizer.normalize(''), equals(''));
    });
  });
}
