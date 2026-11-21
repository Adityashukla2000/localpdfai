import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../documents/domain/models/document_entity.dart';
import '../../../documents/presentation/bloc/documents_cubit.dart';
import '../../../model_manager/domain/models/model_status.dart';
import '../bloc/dashboard_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
    context.read<DocumentsCubit>().loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Model Manager',
            icon: const Icon(Icons.memory_rounded),
            onPressed: () {
              final dashCubit = context.read<DashboardCubit>();
              Navigator.of(context).pushNamed(AppRouter.modelManager).then((_) {
                if (!mounted) return;
                dashCubit.loadDashboard();
              });
            },
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              final dashCubit = context.read<DashboardCubit>();
              final docCubit = context.read<DocumentsCubit>();
              Navigator.of(context).pushNamed(AppRouter.settings).then((_) {
                if (!mounted) return;
                dashCubit.loadDashboard();
                docCubit.loadDocuments();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleImport(context),
        icon: const Icon(Icons.note_add_rounded),
        label: const Text('Import PDF'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final dashCubit = context.read<DashboardCubit>();
          final docCubit = context.read<DocumentsCubit>();
          await dashCubit.loadDashboard();
          if (!mounted) return;
          await docCubit.loadDocuments();
        },
        child: BlocConsumer<DocumentsCubit, DocumentsState>(
          listener: (context, docState) {
            if (docState.recentlyImportedDoc != null && !docState.isImporting) {
              context.read<DashboardCubit>().loadDashboard();
            }
          },
          builder: (context, docState) {
            return BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, dashState) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    if (dashState.errorMessage != null)
                      ErrorBanner(
                        message: dashState.errorMessage!,
                        onRetry: () => context.read<DashboardCubit>().loadDashboard(),
                      ),
                    if (docState.errorMessage != null)
                      ErrorBanner(
                        message: docState.errorMessage!,
                        onDismiss: () => context.read<DocumentsCubit>().loadDocuments(),
                      ),

                    // Model Status Hero Card
                    _buildModelStatusCard(context, dashState.activeModelStatus),
                    const SizedBox(height: 16),

                    // Active Import Progress Card
                    if (docState.isImporting) ...[
                      _buildImportingCard(docState),
                      const SizedBox(height: 16),
                    ],

                    // Storage Overview Banner
                    if (dashState.storageStats != null) ...[
                      _buildStorageBar(context, dashState),
                      const SizedBox(height: 20),
                    ],

                    // Recent Documents Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Documents',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                        ),
                        if (docState.documents.isNotEmpty)
                          Text(
                            '${docState.documents.length} files',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Documents List or Empty State
                    if (dashState.isLoading && docState.documents.isEmpty) ...[
                      const LoadingSkeleton(width: double.infinity, height: 80),
                      const SizedBox(height: 8),
                      const LoadingSkeleton(width: double.infinity, height: 80),
                    ] else if (docState.documents.isEmpty) ...[
                      EmptyStateView(
                        icon: Icons.picture_as_pdf_outlined,
                        title: 'No Documents Imported',
                        description:
                            'Import a PDF file to begin asking questions and generating offline summaries.',
                        actionLabel: 'Import First PDF',
                        onAction: () => _handleImport(context),
                      ),
                    ] else ...[
                      ...docState.documents.map((doc) => _buildDocumentTile(context, doc)),
                      const SizedBox(height: 80), // Bottom FAB padding
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildModelStatusCard(BuildContext context, ModelStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = status.state == ModelExecutionState.loaded ||
        status.state == ModelExecutionState.ready;

    StatusType badgeType = StatusType.neutral;
    String badgeText = 'Not Downloaded';
    IconData badgeIcon = Icons.cloud_download_outlined;

    if (status.state == ModelExecutionState.loaded) {
      badgeType = StatusType.success;
      badgeText = 'Loaded in RAM';
      badgeIcon = Icons.bolt_rounded;
    } else if (status.state == ModelExecutionState.ready) {
      badgeType = StatusType.info;
      badgeText = 'Ready Offline';
      badgeIcon = Icons.check_circle_outline_rounded;
    } else if (status.state == ModelExecutionState.downloading) {
      badgeType = StatusType.warning;
      badgeText = 'Downloading';
      badgeIcon = Icons.sync_rounded;
    }

    return GlassCard(
      onTap: () {
        final dashCubit = context.read<DashboardCubit>();
        Navigator.of(context).pushNamed(AppRouter.modelManager).then((_) {
          if (!mounted) return;
          dashCubit.loadDashboard();
        });
      },
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    color: isReady ? AppColors.secondary : AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Local AI Engine',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              StatusBadge(
                label: badgeText,
                type: badgeType,
                icon: badgeIcon,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            status.descriptor.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '100% on-device private inference (${status.descriptor.quantization}, ${status.descriptor.formattedSize}). No data leaves this device.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportingCard(DocumentsState docState) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  docState.processingStatusText ?? 'Processing PDF...',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: docState.importProgress > 0 ? docState.importProgress : null,
            backgroundColor: Colors.white10,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBar(BuildContext context, DashboardState state) {
    final stats = state.storageStats!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStorageStatItem('Documents', stats.formattedDocumentsSize, Icons.folder_outlined),
          Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
          _buildStorageStatItem('AI Models', stats.formattedModelsSize, Icons.memory_outlined),
          Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
          _buildStorageStatItem('Total Local', stats.formattedTotalUsed, Icons.storage_rounded),
        ],
      ),
    );
  }

  Widget _buildStorageStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentTile(BuildContext context, DocumentEntity doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        onTap: () {
          final docCubit = context.read<DocumentsCubit>();
          final dashCubit = context.read<DashboardCubit>();
          Navigator.of(context).pushNamed(
            AppRouter.documentDetails,
            arguments: doc,
          ).then((_) {
            if (!mounted) return;
            docCubit.loadDocuments();
            dashCubit.loadDashboard();
          });
        },
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${doc.pageCount} pages • ${doc.formattedFileSize}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      if (!doc.hasSelectableText)
                        const StatusBadge(
                          label: 'OCR',
                          type: StatusType.warning,
                          isSmall: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _handleImport(BuildContext context) {
    context.read<DocumentsCubit>().importDocument();
  }
}
