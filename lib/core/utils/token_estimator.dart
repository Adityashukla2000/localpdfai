/// Conservative token count estimator for on-device context budgeting.
class TokenEstimator {
  /// Estimates token count of a given string.
  /// Uses a conservative ratio of ~3.6 - 4.0 characters per token for English
  /// and punctuation, with safety margins to prevent context overflow.
  static int estimate(String text) {
    if (text.isEmpty) return 0;

    // Fast heuristic: words + punctuation
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final charLength = text.length;

    // Characters / 3.8 as safe upper-bound
    final charBased = (charLength / 3.8).ceil();

    // Pick maximum between word-based (words * 1.33) and char-based
    final wordBased = (words * 1.35).ceil();

    return charBased > wordBased ? charBased : wordBased;
  }

  /// Calculates available token budget for context chunks given total window,
  /// system prompt tokens, user question tokens, and generation headroom.
  static int calculateAvailableContextBudget({
    int totalContextWindow = 2048,
    int systemPromptTokens = 250,
    int questionTokens = 80,
    int maxGenerationTokens = 512,
    int safetyMargin = 100,
  }) {
    final used = systemPromptTokens + questionTokens + maxGenerationTokens + safetyMargin;
    final budget = totalContextWindow - used;
    return budget > 200 ? budget : 200;
  }
}
