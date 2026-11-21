import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_banner.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../documents/domain/models/document_entity.dart';
import '../../../documents/presentation/screens/pdf_viewer_screen.dart';
import '../../domain/models/chat_message_entity.dart';
import '../../domain/models/source_citation.dart';
import '../bloc/document_chat_cubit.dart';

class DocumentChatScreen extends StatefulWidget {
  final DocumentEntity document;

  const DocumentChatScreen({super.key, required this.document});

  @override
  State<DocumentChatScreen> createState() => _DocumentChatScreenState();
}

class _DocumentChatScreenState extends State<DocumentChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQuestions = const [
    'Summarize this document',
    'What are the main findings?',
    'List important dates and amounts',
    'What are the key obligations and terms?',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DocumentChatCubit>().loadChat(widget.document.id);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Grounded On-Device Q&A',
              style: TextStyle(fontSize: 11, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'View Document',
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRouter.pdfViewer,
                arguments: widget.document,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
            onPressed: () => _confirmClearChat(context),
          ),
        ],
      ),
      body: BlocConsumer<DocumentChatCubit, DocumentChatState>(
        listener: (context, state) {
          _scrollToBottom();
        },
        builder: (context, state) {
          return Column(
            children: [
              if (state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onDismiss: () => context.read<DocumentChatCubit>().loadChat(widget.document.id),
                ),

              // Chat Messages List
              Expanded(
                child: state.messages.isEmpty && !state.isGenerating
                    ? _buildEmptyChatPlaceholder()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: state.messages.length + (state.isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < state.messages.length) {
                            return _buildMessageBubble(state.messages[index]);
                          } else {
                            // Active streaming bubble
                            return _buildStreamingBubble(
                              state.streamingText ?? '',
                              state.currentCitations,
                            );
                          }
                        },
                      ),
              ),

              // Suggested Prompts Horizontal Bar
              if (!state.isGenerating) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestedQuestions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      return ActionChip(
                        label: Text(_suggestedQuestions[i], style: const TextStyle(fontSize: 12)),
                        onPressed: () => _sendQuestion(_suggestedQuestions[i]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Input Bar
              _buildInputBar(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyChatPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask anything about this document',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'The assistant reads your on-device extracted chunks and responds with exact source citations and page numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message) {
    final isUser = message.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppColors.primary
                      : Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : null,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            if (!isUser && message.citations.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildCitationsSection(message.citations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(String currentText, List<SourceCitation> citations) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentText.isEmpty ? 'Reading document excerpts...' : 'Generating...',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                    ],
                  ),
                  if (currentText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      currentText,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            if (citations.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildCitationsSection(citations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCitationsSection(List<SourceCitation> citations) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: citations.map((citation) {
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCitationPage(citation.pageNumber),
          child: StatusBadge(
            label: 'Page ${citation.pageNumber}',
            type: StatusType.info,
            icon: Icons.open_in_new_rounded,
            isSmall: true,
          ),
        );
      }).toList(),
    );
  }

  void _openCitationPage(int pageNumber) {
    Navigator.of(context).pushNamed(
      AppRouter.pdfViewer,
      arguments: PdfViewerArgs(
        document: widget.document,
        initialPageNumber: pageNumber,
      ),
    );
  }

  Widget _buildInputBar(DocumentChatState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: state.isGenerating ? null : _sendQuestion,
                decoration: const InputDecoration(
                  hintText: 'Ask a question about this document...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (state.isGenerating)
              IconButton(
                icon: const Icon(Icons.stop_circle_rounded, color: AppColors.error, size: 30),
                tooltip: 'Stop Generation',
                onPressed: () => context.read<DocumentChatCubit>().cancelGeneration(),
              )
            else
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 26),
                tooltip: 'Send Question',
                onPressed: () => _sendQuestion(_inputController.text),
              ),
          ],
        ),
      ),
    );
  }

  void _sendQuestion(String text) {
    if (text.trim().isEmpty) return;
    context.read<DocumentChatCubit>().askQuestion(
          documentId: widget.document.id,
          question: text.trim(),
        );
    _inputController.clear();
    _scrollToBottom();
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will delete all past Q&A for this document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              context.read<DocumentChatCubit>().clearChat(widget.document.id);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
