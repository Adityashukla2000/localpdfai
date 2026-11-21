import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:local_pdf_ai/core/constants/app_constants.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';

/// Storage statistics snapshot for settings and dashboard.
class StorageUsageStats {
  final int documentsSizeBytes;
  final int modelsSizeBytes;
  final int databaseSizeBytes;
  final int totalUsedBytes;

  const StorageUsageStats({
    required this.documentsSizeBytes,
    required this.modelsSizeBytes,
    required this.databaseSizeBytes,
    required this.totalUsedBytes,
  });

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String get formattedDocumentsSize => formatBytes(documentsSizeBytes);
  String get formattedModelsSize => formatBytes(modelsSizeBytes);
  String get formattedDatabaseSize => formatBytes(databaseSizeBytes);
  String get formattedTotalUsed => formatBytes(totalUsedBytes);
}

/// Service managing app-controlled filesystem directories and storage usage.
class StorageManagementService {
  Directory? _appSupportDir;

  Future<Directory> get appSupportDirectory async {
    _appSupportDir ??= await getApplicationSupportDirectory();
    return _appSupportDir!;
  }

  /// Get or create the dedicated documents folder.
  Future<Directory> getDocumentsDirectory() async {
    final base = await appSupportDirectory;
    final dir = Directory(p.join(base.path, AppConstants.documentsFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Get or create the dedicated models folder.
  Future<Directory> getModelsDirectory() async {
    final base = await appSupportDirectory;
    final dir = Directory(p.join(base.path, AppConstants.modelsFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy imported file into app-controlled storage to prevent URI revocation.
  Future<File> copyDocumentToAppStorage(File sourceFile, String targetFileName) async {
    try {
      final docDir = await getDocumentsDirectory();
      final destinationPath = p.join(docDir.path, targetFileName);
      return await sourceFile.copy(destinationPath);
    } catch (e) {
      throw StorageException('Failed to copy document to app storage: $e');
    }
  }

  /// Delete a specific file safely.
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw StorageException('Failed to delete file at $filePath: $e');
    }
  }

  /// Calculates disk space used by documents, models, and local databases.
  Future<StorageUsageStats> getStorageUsage() async {
    try {
      final docDir = await getDocumentsDirectory();
      final modelDir = await getModelsDirectory();

      final docSize = await _calculateDirectorySize(docDir);
      final modelSize = await _calculateDirectorySize(modelDir);

      int dbSize = 0;
      final dbBase = await getDatabasesPath();
      final dbFile = File(p.join(dbBase, AppConstants.databaseName));
      if (await dbFile.exists()) {
        dbSize = await dbFile.length();
      }

      return StorageUsageStats(
        documentsSizeBytes: docSize,
        modelsSizeBytes: modelSize,
        databaseSizeBytes: dbSize,
        totalUsedBytes: docSize + modelSize + dbSize,
      );
    } catch (e) {
      throw StorageException('Failed to calculate storage usage: $e');
    }
  }

  /// Clears all files in documents directory.
  Future<void> clearAllDocuments() async {
    try {
      final docDir = await getDocumentsDirectory();
      if (await docDir.exists()) {
        await for (final entity in docDir.list()) {
          await entity.delete(recursive: true);
        }
      }
    } catch (e) {
      throw StorageException('Failed to clear documents storage: $e');
    }
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
