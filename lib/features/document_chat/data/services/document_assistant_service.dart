import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:local_pdf_ai/core/errors/exceptions.dart';
import 'package:local_pdf_ai/features/documents/domain/repositories/document_repository.dart';
import 'package:local_pdf_ai/features/model_manager/data/services/local_model_service.dart';
import 'package:local_pdf_ai/features/document_chat/domain/models/chat_message_entity.dart';
import 'package:local_pdf_ai/features/document_chat/domain/models/source_citation.dart';
import 'package:local_pdf_ai/features/document_chat/domain/repositories/chat_history_repository.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/prompt_builder_service.dart';
import 'package:local_pdf_ai/features/document_chat/data/services/retrieval_service.dart';

class AssistantStreamResponse {
  final Stream<String> tokenStream;
  final List<SourceCitation> citations;
  final bool hasEvidence;
  final Future<ChatMessageEntity> completeFuture;

  const AssistantStreamResponse({
    required this.tokenStream,
    required this.citations,
    required this.hasEvidence,
    required this.completeFuture,
  });
}

/// Orchestrates RAG retrieval, prompt generation, LLM execution, citations, and persistence.
class DocumentAssistantService {
  final DocumentRepository _docRepository;
  final RetrievalEngine _retrievalEngine;
  final PromptBuilderService _promptBuilder;
  final LocalModelService _modelService;
  final ChatHistoryRepository _chatRepository;
  final Uuid _uuid = const Uuid();

  DocumentAssistantService({
    required this._docRepository,
    required this._retrievalEngine,
    required this._promptBuilder,
    required this._modelService,
    required this._chatRepository,
  });

  /// Asks a question about a document and returns a streaming response with citations.
  Future<AssistantStreamResponse> askQuestionStream({
    required String documentId,
    required String question,
    double temperature = 0.3,
    int maxTokens = 512,
  }) async {
    // 1. Verify model is loaded
    if (!_modelService.isModelLoaded) {
      throw InferenceException(
        'AI Model is not loaded. Please ensure a model is downloaded and loaded in Model Manager.',
      );
    }

    // 2. Fetch document chunks
    final chunks = await _docRepository.getChunksForDocument(documentId);
    if (chunks.isEmpty) {
      throw DocumentException('No indexed content found for this document.');
    }

    // 3. Save User Message immediately
    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      documentId: documentId,
      sender: MessageSender.user,
      text: question,
      timestamp: DateTime.now(),
    );
    await _chatRepository.saveMessage(userMessage);

    // 4. Retrieve relevant chunks
    final scoredChunks = await _retrievalEngine.retrieve(
      query: question,
      chunks: chunks,
    );

    // 5. Build prompt
    final promptResult = _promptBuilder.buildGroundedPrompt(
      question: question,
      retrievedChunks: scoredChunks,
    );

    // 6. Generate citations
    final citations = promptResult.includedChunks.map((sc) {
      // Create concise excerpt
      var excerpt = sc.chunk.content;
      if (excerpt.length > 200) {
        excerpt = '${excerpt.substring(0, 197)}...';
      }
      return SourceCitation(
        pageNumber: sc.chunk.pageNumber,
        excerpt: excerpt,
        score: sc.score,
      );
    }).toList();

    final hasEvidence = promptResult.includedChunks.isNotEmpty;

    // 7. Start stream
    final tokenStream = _modelService.generateStream(
      promptResult.userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );

    final completer = Completer<ChatMessageEntity>();
    final buffer = StringBuffer();

    final controller = StreamController<String>.broadcast();
    tokenStream.listen(
      (token) {
        buffer.write(token);
        controller.add(token);
      },
      onError: (err) {
        controller.addError(err);
        if (!completer.isCompleted) completer.completeError(err);
      },
      onDone: () async {
        controller.close();
        final fullAnswer = buffer.toString().trim();
        final assistantMsg = ChatMessageEntity(
          id: _uuid.v4(),
          documentId: documentId,
          sender: MessageSender.assistant,
          text: fullAnswer.isNotEmpty
              ? fullAnswer
              : 'No response could be generated.',
          timestamp: DateTime.now(),
          citations: citations,
        );
        await _chatRepository.saveMessage(assistantMsg);
        if (!completer.isCompleted) completer.complete(assistantMsg);
      },
    );

    return AssistantStreamResponse(
      tokenStream: controller.stream,
      citations: citations,
      hasEvidence: hasEvidence,
      completeFuture: completer.future,
    );
  }
}
