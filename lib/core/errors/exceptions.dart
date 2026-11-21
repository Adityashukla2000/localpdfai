/// Base class for all data-level exceptions.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class DocumentException extends AppException {
  DocumentException(super.message, {super.code, super.details});
}

class ModelDownloadException extends AppException {
  ModelDownloadException(super.message, {super.code, super.details});
}

class InferenceException extends AppException {
  InferenceException(super.message, {super.code, super.details});
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.details});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.details});
}

class RetrievalException extends AppException {
  RetrievalException(super.message, {super.code, super.details});
}
