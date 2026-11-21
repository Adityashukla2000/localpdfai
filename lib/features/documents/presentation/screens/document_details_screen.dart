import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/document_chunk_entity.dart';
import '../../domain/models/document_entity.dart';
import '../../domain/repositories/document_repository.dart';
import '../bloc/documents_cubit.dart';

class DocumentDetailsScreen extends StatefulWidget {
  final DocumentEntity document;

  const DocumentDetailsScreen({super.key, required this.document});

  @override
  State<DocumentDetailsScreen> createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  List<DocumentChunkEntity> _chunks = [];
  bool _isLoadingChunks = true;

  @override
  void initState() {
    super.initState();
    _fetchChunks();
  }

  Future<void> _fetchChunks() async {
    final repo = context.read<DocumentRepository>();
    final chunks = await repo.getChunksForDocument(widget.document.id);
    if (mounted) {
      setState(() {
        _chunks = chunks;
        _isLoadingChunks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final dateStr = DateFormat.yMMMd().add_jm().format(doc.importedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Document',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Imported $dateStr',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetaItem('Pages', '${doc.pageCount}'),
                    _buildMetaItem('Size', doc.formattedFileSize),
                    _buildMetaItem('Characters', '${doc.extractedCharacterCount}'),
                    _buildMetaItem(
                      'Text Mode',
                      doc.hasSelectableText ? 'Native' : 'OCR',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.documentChat,
                      arguments: doc,
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Chat with AI'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.pdfViewer,
                      arguments: doc,
                    );
                  },
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('View PDF'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.summary,
                arguments: doc,
              );
            },
            icon: const Icon(Icons.summarize_outlined, size: 18),
            label: const Text('Generate Document Summary'),
          ),
          const SizedBox(height: 24),

          // Extracted Chunks Preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indexed Text Chunks (${_chunks.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (_isLoadingChunks)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_chunks.isEmpty && !_isLoadingChunks)
            const Text(
              'No chunks found for this document.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            ..._chunks.take(8).map((chunk) => _buildChunkCard(chunk)),

          if (_chunks.length > 8)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '+ ${_chunks.length - 8} additional indexed chunks in database',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildChunkCard(DocumentChunkEntity chunk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  label: 'Page ${chunk.pageNumber}',
                  type: StatusType.info,
                  isSmall: true,
                ),
                Text(
                  'Chunk #${chunk.chunkIndex + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              chunk.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text(
          'Are you sure you want to delete "${widget.document.name}"? '
          'All associated chunks and chat history will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<DocumentsCubit>().deleteDocument(widget.document.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
