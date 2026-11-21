import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/prompt_builder_service.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:local_pdf_ai/features/documents/domain/repositories/document_repository.dart';
import 'package:local_pdf_ai/features/model_manager/data/services/local_model_service.dart';

enum SummaryType {
  detailed('Detailed Summary'),
  short('Executive Summary'),
  keyPoints('Key Points & Findings'),
  entities('Dates, Entities & Amounts');

  final String label;
  const SummaryType(this.label);
}

class DocumentSummaryResult {
  final SummaryType type;
  final String summaryText;
  final List<int> referencedPages;

  const DocumentSummaryResult({
    required this.type,
    required this.summaryText,
    required this.referencedPages,
  });
}

/// Service performing map-reduce and section-wise summarization of PDF documents.
class SummaryService {
  final DocumentRepository _docRepository;
  final LocalModelService _modelService;
  final PromptBuilderService _promptBuilder;

  SummaryService({
    required this._docRepository,
    required this._modelService,
    required this._promptBuilder,
  });

  /// Generates a summary for the given document and summary type.
  /// For large documents, processes section chunks sequentially and then consolidates.
  Future<DocumentSummaryResult> generateSummary({
    required DocumentEntity document,
    SummaryType type = SummaryType.detailed,
    void Function(String stepDescription)? onProgress,
  }) async {
    if (!_modelService.isModelLoaded) {
      throw InferenceException(
        'AI model must be loaded before generating summaries.',
      );
    }

    final chunks = await _docRepository.getChunksForDocument(document.id);
    if (chunks.isEmpty) {
      throw DocumentException('No extracted chunks found for ${document.name}.');
    }

    onProgress?.call('Analyzing document sections...');

    // If small document (<= 6 chunks), summarize directly
    if (chunks.length <= 6) {
      final combinedText = chunks.map((c) => c.content).join('\n\n');
      final prompt = _promptBuilder.buildSummarizationPrompt(
        documentName: document.name,
        sectionText: combinedText,
        pageStart: 1,
        pageEnd: document.pageCount,
        summaryType: type.name,
      );

      onProgress?.call('Generating ${type.label}...');
      final answer = await _modelService.generate(prompt, maxTokens: 600);
      final pages = List<int>.generate(document.pageCount, (i) => i + 1);

      return DocumentSummaryResult(
        type: type,
        summaryText: answer,
        referencedPages: pages,
      );
    }

    // For larger documents: Section Map-Reduce
    // Group chunks into 3-4 sections
    onProgress?.call('Summarizing document chapters in parallel batches...');
    final int sectionSize = (chunks.length / 3).ceil().clamp(1, chunks.length);
    final intermediateSummaries = <String>[];
    final allPages = <int>{};

    for (int i = 0; i < chunks.length; i += sectionSize) {
      final end = (i + sectionSize).clamp(0, chunks.length);
      final sectionChunks = chunks.sublist(i, end);
      final sectionText = sectionChunks.map((c) => c.content).join('\n\n');

      final pageStart = sectionChunks.first.pageNumber;
      final pageEnd = sectionChunks.last.pageNumber;
      for (final sc in sectionChunks) {
        allPages.add(sc.pageNumber);
      }

      final sectionPrompt = _promptBuilder.buildSummarizationPrompt(
        documentName: document.name,
        sectionText: sectionText,
        pageStart: pageStart,
        pageEnd: pageEnd,
        summaryType: 'key_points',
      );

      final sectionSummary = await _modelService.generate(sectionPrompt, maxTokens: 300);
      intermediateSummaries.add('[Section ${intermediateSummaries.length + 1} (Pages $pageStart-$pageEnd)]:\n$sectionSummary');
    }

    // Consolidated Reduce Step
    onProgress?.call('Consolidating final ${type.label}...');
    final consolidatePrompt = '''
You are Local PDF AI Assistant.
The following are section-level summaries from different chapters of "${document.name}":

${intermediateSummaries.join('\n\n')}

Task: Synthesize these chapter summaries into a final, highly coherent ${type.label}.
Ensure all key dates, findings, and page references are preserved.
''';

    final finalSummary = await _modelService.generate(consolidatePrompt, maxTokens: 700);

    final sortedPages = allPages.toList()..sort();
    return DocumentSummaryResult(
      type: type,
      summaryText: finalSummary,
      referencedPages: sortedPages,
    );
  }
}
