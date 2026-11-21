import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/utils/token_estimator.dart';

void main() {
  group('TokenEstimator Unit Tests', () {
    test('Estimates empty string as 0 tokens', () {
      expect(TokenEstimator.estimate(''), equals(0));
    });

    test('Estimates realistic token count for standard English text', () {
      const text = 'This is an example paragraph to test the conservative on-device token estimation utility.';
      final tokens = TokenEstimator.estimate(text);
      expect(tokens, greaterThan(10));
      expect(tokens, lessThan(40));
    });

    test('Calculates available context budget accurately', () {
      final budget = TokenEstimator.calculateAvailableContextBudget(
        totalContextWindow: 2048,
        systemPromptTokens: 250,
        questionTokens: 50,
        maxGenerationTokens: 512,
        safetyMargin: 100,
      );

      expect(budget, equals(2048 - (250 + 50 + 512 + 100)));
    });
  });
}
