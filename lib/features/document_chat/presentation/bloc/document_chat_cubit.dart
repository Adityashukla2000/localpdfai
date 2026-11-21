import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/document_assistant_service.dart';
import '../../domain/models/chat_message_entity.dart';
import '../../domain/models/source_citation.dart';
import '../../domain/repositories/chat_history_repository.dart';

class DocumentChatState extends Equatable {
  final bool isLoading;
  final bool isGenerating;
  final List<ChatMessageEntity> messages;
  final List<SourceCitation> currentCitations;
  final String? streamingText;
  final String? errorMessage;

  const DocumentChatState({
    this.isLoading = false,
    this.isGenerating = false,
    this.messages = const [],
    this.currentCitations = const [],
    this.streamingText,
    this.errorMessage,
  });

  DocumentChatState copyWith({
    bool? isLoading,
    bool? isGenerating,
    List<ChatMessageEntity>? messages,
    List<SourceCitation>? currentCitations,
    String? streamingText,
    String? errorMessage,
  }) {
    return DocumentChatState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      messages: messages ?? this.messages,
      currentCitations: currentCitations ?? this.currentCitations,
      streamingText: streamingText,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isGenerating,
        messages,
        currentCitations,
        streamingText,
        errorMessage,
      ];
}

class DocumentChatCubit extends Cubit<DocumentChatState> {
  final DocumentAssistantService _assistantService;
  final ChatHistoryRepository _chatRepository;
  StreamSubscription<String>? _streamSub;
  final Uuid _uuid = const Uuid();

  DocumentChatCubit({
    required this._assistantService,
    required this._chatRepository,
  })  : super(const DocumentChatState());

  Future<void> loadChat(String documentId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final history = await _chatRepository.getMessagesForDocument(documentId);
      emit(state.copyWith(isLoading: false, messages: history));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to load chat history: $e'));
    }
  }

  Future<void> askQuestion({
    required String documentId,
    required String question,
  }) async {
    if (question.trim().isEmpty || state.isGenerating) return;

    final trimmed = question.trim();

    // 1. Optimistically display user message
    final userMsg = ChatMessageEntity(
      id: _uuid.v4(),
      documentId: documentId,
      sender: MessageSender.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    final updated = List<ChatMessageEntity>.from(state.messages)..add(userMsg);
    emit(state.copyWith(
      messages: updated,
      isGenerating: true,
      streamingText: '',
      currentCitations: [],
      errorMessage: null,
    ));

    try {
      final response = await _assistantService.askQuestionStream(
        documentId: documentId,
        question: trimmed,
      );

      emit(state.copyWith(currentCitations: response.citations));

      final buffer = StringBuffer();
      _streamSub?.cancel();
      _streamSub = response.tokenStream.listen(
        (token) {
          buffer.write(token);
          emit(state.copyWith(streamingText: buffer.toString()));
        },
        onError: (err) {
          emit(state.copyWith(
            isGenerating: false,
            streamingText: null,
            errorMessage: 'Inference error: $err',
          ));
        },
        onDone: () async {
          final completedMsg = await response.completeFuture;
          final finalMessages = List<ChatMessageEntity>.from(state.messages)
            ..add(completedMsg);

          emit(state.copyWith(
            isGenerating: false,
            streamingText: null,
            messages: finalMessages,
            currentCitations: response.citations,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isGenerating: false,
        streamingText: null,
        errorMessage: e.toString(),
      ));
    }
  }

  void cancelGeneration() {
    _streamSub?.cancel();
    _streamSub = null;
    emit(state.copyWith(isGenerating: false, streamingText: null));
  }

  Future<void> clearChat(String documentId) async {
    try {
      await _chatRepository.clearMessagesForDocument(documentId);
      emit(state.copyWith(messages: const [], currentCitations: const []));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to clear chat: $e'));
    }
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}
