import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/features/document_chat/domain/models/chat_message_entity.dart';
import 'package:local_pdf_ai/features/document_chat/domain/models/source_citation.dart';
import 'package:local_pdf_ai/features/document_chat/presentation/bloc/document_chat_cubit.dart';
import 'package:local_pdf_ai/features/document_chat/presentation/screens/document_chat_screen.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';

class FakeDocumentChatCubit extends Cubit<DocumentChatState>
    implements DocumentChatCubit {
  FakeDocumentChatCubit(super.initialState);

  @override
  Future<void> loadChat(String documentId) async {}

  @override
  Future<void> askQuestion({
    required String documentId,
    required String question,
  }) async {}

  @override
  Future<void> clearChat(String documentId) async {}

  @override
  void cancelGeneration() {}
}

void main() {
  final sampleDoc = DocumentEntity(
    id: 'doc_123',
    name: 'Project_Specification.pdf',
    originalPath: '/storage/Project_Specification.pdf',
    storedPath: '/app_storage/Project_Specification.pdf',
    fileSizeBytes: 1024 * 512,
    pageCount: 8,
    importedAt: DateTime.now(),
  );

  Widget buildTestableWidget(DocumentChatCubit cubit) {
    return MaterialApp(
      home: BlocProvider<DocumentChatCubit>.value(
        value: cubit,
        child: DocumentChatScreen(document: sampleDoc),
      ),
    );
  }

  group('DocumentChatScreen Widget Tests', () {
    testWidgets('Renders document name in app bar and suggestion chips when empty',
        (tester) async {
      final cubit = FakeDocumentChatCubit(const DocumentChatState(messages: []));

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(find.text('Project_Specification.pdf'), findsOneWidget);
      expect(find.text('Grounded On-Device Q&A'), findsOneWidget);
      expect(find.text('Summarize this document'), findsOneWidget);
      expect(find.text('What are the main findings?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Renders user and assistant messages with source citation pill',
        (tester) async {
      final messages = [
        ChatMessageEntity(
          id: 'msg_1',
          documentId: sampleDoc.id,
          sender: MessageSender.user,
          text: 'What are the main constraints?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        ChatMessageEntity(
          id: 'msg_2',
          documentId: sampleDoc.id,
          sender: MessageSender.assistant,
          text: 'The main constraints are 100% on-device inference and offline capability.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          citations: const [
            SourceCitation(
              pageNumber: 3,
              excerpt: 'All inference must run 100% on-device with zero cloud telemetry.',
              score: 4.8,
            ),
          ],
        ),
      ];

      final cubit = FakeDocumentChatCubit(DocumentChatState(messages: messages));

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(find.text('What are the main constraints?'), findsOneWidget);
      expect(
        find.text('The main constraints are 100% on-device inference and offline capability.'),
        findsOneWidget,
      );
      expect(find.text('Page 3'), findsOneWidget);
    });

    testWidgets('Displays streaming text when generation is active', (tester) async {
      final cubit = FakeDocumentChatCubit(
        const DocumentChatState(
          isGenerating: true,
          streamingText: 'Synthesizing response from page 1 and page 2...',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(
        find.text('Synthesizing response from page 1 and page 2...'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);
    });
  });
}
