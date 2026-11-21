import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/model_registry.dart';

enum AppThemeMode { system, light, dark }

/// Domain model for user settings and AI inference parameters.
class SettingsEntity extends Equatable {
  final String selectedModelId;
  final int maxTokens;
  final double temperature;
  final AppThemeMode themeMode;
  final bool ocrEnabled;

  const SettingsEntity({
    required this.selectedModelId,
    required this.maxTokens,
    required this.temperature,
    required this.themeMode,
    required this.ocrEnabled,
  });

  factory SettingsEntity.defaults() {
    return SettingsEntity(
      selectedModelId: ModelRegistry.defaultModel.id,
      maxTokens: AppConstants.defaultMaxTokens,
      temperature: AppConstants.defaultTemperature,
      themeMode: AppThemeMode.system,
      ocrEnabled: true,
    );
  }

  SettingsEntity copyWith({
    String? selectedModelId,
    int? maxTokens,
    double? temperature,
    AppThemeMode? themeMode,
    bool? ocrEnabled,
  }) {
    return SettingsEntity(
      selectedModelId: selectedModelId ?? this.selectedModelId,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      themeMode: themeMode ?? this.themeMode,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
    );
  }

  @override
  List<Object?> get props => [
        selectedModelId,
        maxTokens,
        temperature,
        themeMode,
        ocrEnabled,
      ];
}
