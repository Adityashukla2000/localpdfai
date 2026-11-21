import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';

class PickedDocument {
  final File file;
  final String name;
  final int sizeBytes;

  const PickedDocument({
    required this.file,
    required this.name,
    required this.sizeBytes,
  });
}

/// Service wrapping system file picker with format and size validations.
class DocumentPickerService {
  Future<PickedDocument?> pickPdfDocument() async {
    try {
      final platformFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: AppConstants.supportedExtensions,
      );

      if (platformFile == null) {
        return null; // User cancelled
      }
      final filePath = platformFile.path;

      if (filePath == null || filePath.isEmpty) {
        throw DocumentException('Failed to retrieve file path from picker.');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw DocumentException('Selected file does not exist on disk.');
      }

      final sizeBytes = await file.length();
      if (sizeBytes == 0) {
        throw DocumentException('The selected PDF file is empty (0 bytes).');
      }

      if (sizeBytes > AppConstants.maxFileSizeBytes) {
        final mb = (AppConstants.maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0);
        throw DocumentException(
          'File exceeds maximum allowed size of $mb MB.',
        );
      }

      return PickedDocument(
        file: file,
        name: platformFile.name,
        sizeBytes: sizeBytes,
      );
    } catch (e) {
      if (e is DocumentException) rethrow;
      throw DocumentException('Failed to pick document: $e');
    }
  }
}
