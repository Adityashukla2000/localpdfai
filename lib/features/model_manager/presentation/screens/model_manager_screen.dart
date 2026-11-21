import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/model_status.dart';
import '../bloc/model_manager_cubit.dart';

class ModelManagerScreen extends StatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  State<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends State<ModelManagerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ModelManagerCubit>().loadModels();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local AI Models'),
      ),
      body: BlocBuilder<ModelManagerCubit, ModelManagerState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Offline Info Card
              GlassCard(
                padding: const EdgeInsets.all(14),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFFEEF2FF), const Color(0xFFF1F5F9)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '100% On-Device Inference',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Models execute locally via GGUF/llama.cpp. Zero data transmitted. No API key needed.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (state.operationNotice != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.operationNotice!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (state.errorMessage != null) ...[
                ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: () => context.read<ModelManagerCubit>().loadModels(),
                ),
                const SizedBox(height: 8),
              ],

              // Active Download Progress Widget
              if (state.isDownloading) ...[
                _buildActiveDownloadCard(context, state),
                const SizedBox(height: 16),
              ],

              Text(
                'Available Mobile GGUF Models',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              ...state.models.map((m) => _buildModelTile(context, state, m)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveDownloadCard(BuildContext context, ModelManagerState state) {
    return GlassCard(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Downloading Model...',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                onPressed: () => context.read<ModelManagerCubit>().cancelDownload(),
                tooltip: 'Cancel Download',
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: state.currentDownloadProgress > 0 ? state.currentDownloadProgress : null,
            backgroundColor: Colors.white12,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(state.downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(state.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                '${(state.currentDownloadProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelTile(
    BuildContext context,
    ModelManagerState state,
    ModelStatus status,
  ) {
    final descriptor = status.descriptor;
    final isDownloaded = status.state == ModelExecutionState.ready ||
        status.state == ModelExecutionState.loaded;
    final isLoaded = status.state == ModelExecutionState.loaded;

    StatusType badgeType = StatusType.neutral;
    String badgeText = 'Not Downloaded';
    if (isLoaded) {
      badgeType = StatusType.success;
      badgeText = 'Loaded';
    } else if (isDownloaded) {
      badgeType = StatusType.info;
      badgeText = 'Downloaded';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        descriptor.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (descriptor.isRecommended)
                        const StatusBadge(
                          label: 'Recommended',
                          type: StatusType.success,
                          isSmall: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  label: badgeText,
                  type: badgeType,
                  isSmall: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              descriptor.description,
              style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoTag('Size: ${descriptor.formattedSize}'),
                _buildInfoTag('RAM Req: ~${descriptor.formattedRam}'),
                _buildInfoTag('Quant: ${descriptor.quantization}'),
                _buildInfoTag('Context: ${descriptor.defaultContextLength} tokens'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (!isDownloaded && !state.isDownloading) ...[
                    ElevatedButton.icon(
                      onPressed: () => context.read<ModelManagerCubit>().downloadModel(descriptor),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text('Download (${descriptor.formattedSize})'),
                    ),
                  ] else if (isDownloaded) ...[
                    if (!isLoaded) ...[
                      OutlinedButton.icon(
                        onPressed: () =>
                            context.read<ModelManagerCubit>().loadModelIntoMemory(descriptor),
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Load to RAM'),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: () => context.read<ModelManagerCubit>().unloadModel(),
                        icon: const Icon(Icons.power_settings_new_rounded, size: 16),
                        label: const Text('Unload'),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete Model',
                      onPressed: () => context.read<ModelManagerCubit>().deleteModel(descriptor),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }
}
