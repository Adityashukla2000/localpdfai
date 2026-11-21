import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_pdf_ai/app/router.dart';
import 'package:local_pdf_ai/app/theme/app_colors.dart';
import 'package:local_pdf_ai/core/widgets/error_banner.dart';
import 'package:local_pdf_ai/core/widgets/glass_card.dart';
import 'package:local_pdf_ai/core/widgets/status_badge.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:local_pdf_ai/features/documents/presentation/screens/pdf_viewer_screen.dart';
import 'package:local_pdf_ai/features/summarization/data/services/summary_service.dart';
import 'package:local_pdf_ai/features/summarization/presentation/bloc/summarization_cubit.dart';

class SummaryScreen extends StatefulWidget {
  final DocumentEntity document;

  const SummaryScreen({super.key, required this.document});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  SummaryType _selectedType = SummaryType.detailed;

  @override
  void initState() {
    super.initState();
    _triggerSummary();
  }

  void _triggerSummary() {
    context.read<SummarizationCubit>().generateSummary(
          document: widget.document,
          type: _selectedType,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(widget.document.name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate',
            onPressed: _triggerSummary,
          ),
        ],
      ),
      body: BlocBuilder<SummarizationCubit, SummarizationState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Type Selector
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SummaryType.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = SummaryType.values[index];
                    final isSelected = type == _selectedType;
                    return ChoiceChip(
                      label: Text(type.label, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: state.isLoading
                          ? null
                          : (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedType = type;
                                });
                                _triggerSummary();
                              }
                            },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              if (state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: _triggerSummary,
                ),

              if (state.isLoading) ...[
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        state.currentStep ?? 'Analyzing document...',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Map-reduce pipeline is processing chunks and synthesizing findings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ] else if (state.result != null) ...[
                // Summary Result View
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(
                            label: state.result!.type.label,
                            type: StatusType.info,
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy to Clipboard',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: state.result!.summaryText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Summary copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        state.result!.summaryText,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      if (state.result!.referencedPages.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Referenced Document Pages:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: state.result!.referencedPages.map((pageNum) {
                            return ActionChip(
                              label: Text('Page $pageNum', style: const TextStyle(fontSize: 11)),
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRouter.pdfViewer,
                                  arguments: PdfViewerArgs(
                                    document: widget.document,
                                    initialPageNumber: pageNum,
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
