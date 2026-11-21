import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/constants/app_constants.dart';
import 'package:local_pdf_ai/core/constants/model_registry.dart';
import 'package:local_pdf_ai/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:local_pdf_ai/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:local_pdf_ai/features/documents/presentation/bloc/documents_cubit.dart';
import 'package:local_pdf_ai/features/model_manager/domain/models/model_status.dart';

class FakeDashboardCubit extends Cubit<DashboardState> implements DashboardCubit {
  FakeDashboardCubit(super.initialState);

  @override
  Future<void> loadDashboard() async {}
}

class FakeDocumentsCubit extends Cubit<DocumentsState> implements DocumentsCubit {
  FakeDocumentsCubit(super.initialState);

  @override
  Future<void> loadDocuments() async {}

  @override
  Future<void> importDocument() async {}

  @override
  Future<void> deleteDocument(String id) async {}
}

void main() {
  Widget buildTestableWidget({
    required DashboardCubit dashboardCubit,
    required DocumentsCubit documentsCubit,
  }) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<DocumentsCubit>.value(value: documentsCubit),
        ],
        child: const DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders app title, actions, and empty documents state', (tester) async {
      final dashCubit = FakeDashboardCubit(
        DashboardState(
          activeModelStatus: ModelStatus(
            descriptor: ModelRegistry.defaultModel,
            state: ModelExecutionState.notDownloaded,
          ),
        ),
      );
      final docCubit = FakeDocumentsCubit(const DocumentsState(documents: []));

      await tester.pumpWidget(
        buildTestableWidget(
          dashboardCubit: dashCubit,
          documentsCubit: docCubit,
        ),
      );
      await tester.pump();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('No Documents Imported'), findsOneWidget);
      expect(find.text('Import First PDF'), findsOneWidget);
      expect(find.text('Not Downloaded'), findsOneWidget);
    });

    testWidgets('Renders imported document in recent documents list', (tester) async {
      final sampleDoc = DocumentEntity(
        id: 'doc_1',
        name: 'annual_report.pdf',
        originalPath: '/storage/annual_report.pdf',
        storedPath: '/app_storage/annual_report.pdf',
        fileSizeBytes: 1024 * 1024 * 3,
        pageCount: 22,
        importedAt: DateTime.now(),
        status: DocumentProcessingStatus.indexed,
        extractedCharacterCount: 15400,
        hasSelectableText: true,
      );

      final dashCubit = FakeDashboardCubit(
        DashboardState(
          activeModelStatus: ModelStatus(
            descriptor: ModelRegistry.defaultModel,
            state: ModelExecutionState.ready,
            localPath: '/models/qwen.gguf',
          ),
          recentDocuments: [sampleDoc],
        ),
      );
      final docCubit = FakeDocumentsCubit(
        DocumentsState(documents: [sampleDoc]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          dashboardCubit: dashCubit,
          documentsCubit: docCubit,
        ),
      );
      await tester.pump();

      expect(find.text('annual_report.pdf'), findsOneWidget);
      expect(find.textContaining('22 pages'), findsOneWidget);
      expect(find.text('Ready Offline'), findsOneWidget);
    });

    testWidgets('Displays active document import progress card', (tester) async {
      final dashCubit = FakeDashboardCubit(
        DashboardState(
          activeModelStatus: ModelStatus(
            descriptor: ModelRegistry.defaultModel,
            state: ModelExecutionState.notDownloaded,
          ),
        ),
      );
      final docCubit = FakeDocumentsCubit(
        const DocumentsState(
          isImporting: true,
          processingStatusText: 'Extracting text from page 4 of 12...',
          importProgress: 0.33,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          dashboardCubit: dashCubit,
          documentsCubit: docCubit,
        ),
      );
      await tester.pump();

      expect(find.text('Extracting text from page 4 of 12...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
