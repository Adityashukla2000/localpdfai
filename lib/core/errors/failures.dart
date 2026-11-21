import 'package:equatable/equatable.dart';

/// Base class for all domain failures in the application.
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

/// Failures occurring during PDF extraction or document operations.
class DocumentFailure extends Failure {
  const DocumentFailure(super.message, {super.code, super.details});
}

/// Failures occurring during model downloading, checksum verification, or disk limits.
class ModelDownloadFailure extends Failure {
  const ModelDownloadFailure(super.message, {super.code, super.details});
}

/// Failures occurring during LLM inference, initialization, or context overflow.
class InferenceFailure extends Failure {
  const InferenceFailure(super.message, {super.code, super.details});
}

/// Failures related to local SQLite database operations.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code, super.details});
}

/// Failures related to local filesystem and app storage management.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code, super.details});
}

/// Failures related to RAG retrieval and indexing.
class RetrievalFailure extends Failure {
  const RetrievalFailure(super.message, {super.code, super.details});
}
