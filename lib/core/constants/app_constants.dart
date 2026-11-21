/// Central constants for application configuration, chunking, and storage.
class AppConstants {
  static const String appName = 'Local PDF AI';
  static const String appVersion = '1.0.0';
  static const String appTagline = '100% Private, On-Device AI Document Intelligence';

  // Database
  static const String databaseName = 'local_pdf_ai.db';
  static const int databaseVersion = 1;

  // Storage directories
  static const String documentsFolder = 'documents';
  static const String modelsFolder = 'models';
  static const String previewsFolder = 'previews';

  // RAG & Chunking defaults
  static const int defaultChunkSize = 500; // characters
  static const int defaultChunkOverlap = 100; // characters
  static const int defaultTopKRetrieval = 4;
  static const double minKeywordScore = 0.05;

  // Inference defaults
  static const int defaultMaxTokens = 512;
  static const double defaultTemperature = 0.3;
  static const double defaultTopP = 0.85;
  static const int defaultContextWindow = 2048;

  // Supported PDF extensions
  static const List<String> supportedExtensions = ['pdf'];
  static const int maxFileSizeBytes = 50 * 1024 * 1024; // 50MB
}
