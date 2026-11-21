import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:local_pdf_ai/core/database/database_service.dart';
import 'package:local_pdf_ai/core/database/tables.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/settings/domain/models/settings_entity.dart';

/// Service managing persistent settings stored in SQLite.
class SettingsService {
  final LocalDatabaseService _dbService;

  SettingsService(this._dbService);

  Future<SettingsEntity> getSettings() async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(DbTables.settings);
      final map = {for (var r in rows) r[DbTables.colSettingKey] as String: r[DbTables.colSettingValue] as String};

      if (map.isEmpty) {
        final defaults = SettingsEntity.defaults();
        await saveSettings(defaults);
        return defaults;
      }

      return SettingsEntity(
        selectedModelId: map['selected_model_id'] ?? SettingsEntity.defaults().selectedModelId,
        maxTokens: int.tryParse(map['max_tokens'] ?? '') ?? SettingsEntity.defaults().maxTokens,
        temperature: double.tryParse(map['temperature'] ?? '') ?? SettingsEntity.defaults().temperature,
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == map['theme_mode'],
          orElse: () => AppThemeMode.system,
        ),
        ocrEnabled: (map['ocr_enabled'] ?? 'true') == 'true',
      );
    } catch (e) {
      throw DatabaseException('Failed to load settings: $e');
    }
  }

  Future<void> saveSettings(SettingsEntity settings) async {
    try {
      final db = await _dbService.database;
      final entries = {
        'selected_model_id': settings.selectedModelId,
        'max_tokens': settings.maxTokens.toString(),
        'temperature': settings.temperature.toString(),
        'theme_mode': settings.themeMode.name,
        'ocr_enabled': settings.ocrEnabled.toString(),
      };

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final entry in entries.entries) {
          batch.insert(
            DbTables.settings,
            {
              DbTables.colSettingKey: entry.key,
              DbTables.colSettingValue: entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      throw DatabaseException('Failed to save settings: $e');
    }
  }
}
