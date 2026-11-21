import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_pdf_ai/app/router.dart';
import 'package:local_pdf_ai/app/theme/app_colors.dart';
import 'package:local_pdf_ai/core/constants/app_constants.dart';
import 'package:local_pdf_ai/core/constants/model_registry.dart';
import 'package:local_pdf_ai/core/widgets/glass_card.dart';
import 'package:local_pdf_ai/features/settings/domain/models/settings_entity.dart';
import 'package:local_pdf_ai/features/settings/presentation/bloc/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.noticeMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.noticeMessage!)),
            );
          }
        },
        builder: (context, state) {
          final settings = state.settings;
          final currentModel = ModelRegistry.findById(settings.selectedModelId) ??
              ModelRegistry.defaultModel;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // AI Model Selection Section
              _buildSectionHeader('Local AI Model'),
              GlassCard(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.modelManager);
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentModel.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${currentModel.quantization} • ${currentModel.formattedSize} • Tap to manage models',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Generation Parameters
              _buildSectionHeader('Inference Parameters'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Creativity (Temperature)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text(settings.temperature.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: settings.temperature,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: settings.temperature.toStringAsFixed(1),
                      onChanged: (val) {
                        context.read<SettingsCubit>().updateSettings(
                              settings.copyWith(temperature: val),
                            );
                      },
                    ),
                    const Text(
                      'Lower temperature (0.2 - 0.4) produces more factual, strictly grounded document answers.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Max Output Tokens', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${settings.maxTokens}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: settings.maxTokens.toDouble(),
                      min: 128,
                      max: 1024,
                      divisions: 7,
                      label: '${settings.maxTokens}',
                      onChanged: (val) {
                        context.read<SettingsCubit>().updateSettings(
                              settings.copyWith(maxTokens: val.toInt()),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Appearance & Theme
              _buildSectionHeader('Appearance'),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SegmentedButton<AppThemeMode>(
                      segments: const [
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded),
                        ),
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded),
                        ),
                        ButtonSegment<AppThemeMode>(
                          value: AppThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selectedSet) {
                        if (selectedSet.isNotEmpty) {
                          context.read<SettingsCubit>().updateSettings(
                                settings.copyWith(themeMode: selectedSet.first),
                              );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Storage & Privacy
              _buildSectionHeader('Storage & Offline Privacy'),
              if (state.storageStats != null) ...[
                GlassCard(
                  child: Column(
                    children: [
                      _buildStorageRow('Documents Storage', state.storageStats!.formattedDocumentsSize),
                      const Divider(height: 16),
                      _buildStorageRow('AI Models Storage', state.storageStats!.formattedModelsSize),
                      const Divider(height: 16),
                      _buildStorageRow('SQLite Database', state.storageStats!.formattedDatabaseSize),
                      const Divider(height: 16),
                      _buildStorageRow('Total App Data', state.storageStats!.formattedTotalUsed, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Danger Zone / Clear Data
              _buildSectionHeader('Data Management'),
              GlassCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.error),
                      title: const Text('Clear All Chat History'),
                      subtitle: const Text('Deletes all saved questions and answers across all documents', style: TextStyle(fontSize: 12)),
                      onTap: () => _confirmClearChat(context),
                    ),
                    const Divider(height: 8),
                    ListTile(
                      leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                      title: const Text('Delete All Local Documents'),
                      subtitle: const Text('Removes all imported PDFs and extracted chunk embeddings', style: TextStyle(fontSize: 12)),
                      onTap: () => _confirmDeleteDocuments(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Privacy Declaration
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}\n'
                    '100% on-device local inference. Your documents, extracted text, and chat history are never transmitted over the internet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _buildStorageRow(String title, String size, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(size, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Clear All Chat History?'),
        content: const Text('This will delete all past Q&A history across all documents.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dCtx).pop();
              context.read<SettingsCubit>().clearAllChatHistory();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDocuments(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete All Documents?'),
        content: const Text('This will permanently delete all imported PDF files and all chunks from device storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dCtx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dCtx).pop();
              context.read<SettingsCubit>().clearAllDocuments();
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
