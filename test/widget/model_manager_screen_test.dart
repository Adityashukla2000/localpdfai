import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_pdf_ai/core/constants/model_registry.dart';
import 'package:local_pdf_ai/features/model_manager/domain/models/model_status.dart';
import 'package:local_pdf_ai/features/model_manager/presentation/bloc/model_manager_cubit.dart';
import 'package:local_pdf_ai/features/model_manager/presentation/screens/model_manager_screen.dart';

class FakeModelManagerCubit extends Cubit<ModelManagerState>
    implements ModelManagerCubit {
  FakeModelManagerCubit(super.initialState);

  @override
  Future<void> loadModels() async {}

  @override
  Future<void> downloadModel(ModelDescriptor model) async {}

  @override
  void cancelDownload() {}

  @override
  Future<void> loadModelIntoMemory(ModelDescriptor model) async {}

  @override
  Future<void> unloadModel() async {}

  @override
  Future<void> deleteModel(ModelDescriptor model) async {}
}

void main() {
  Widget buildTestableWidget(ModelManagerCubit cubit) {
    return MaterialApp(
      home: BlocProvider<ModelManagerCubit>.value(
        value: cubit,
        child: const ModelManagerScreen(),
      ),
    );
  }

  group('ModelManagerScreen Widget Tests', () {
    testWidgets('Renders screen title, offline badge, and model options', (tester) async {
      final defaultModel = ModelRegistry.defaultModel;
      final cubit = FakeModelManagerCubit(
        ModelManagerState(
          models: [
            ModelStatus(
              descriptor: defaultModel,
              state: ModelExecutionState.notDownloaded,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(find.text('Local AI Models'), findsOneWidget);
      expect(find.text('100% On-Device Inference'), findsOneWidget);
      expect(find.text(defaultModel.name), findsOneWidget);
      expect(find.textContaining('Download ('), findsOneWidget);
    });

    testWidgets('Displays active download progress and cancel action', (tester) async {
      final defaultModel = ModelRegistry.defaultModel;
      final cubit = FakeModelManagerCubit(
        ModelManagerState(
          isDownloading: true,
          downloadingModelId: defaultModel.id,
          currentDownloadProgress: 0.45,
          models: [
            ModelStatus(
              descriptor: defaultModel,
              state: ModelExecutionState.downloading,
              downloadProgress: 0.45,
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(find.text(defaultModel.name), findsOneWidget);
      expect(find.byTooltip('Cancel Download'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays action to load model into RAM when ready', (tester) async {
      final defaultModel = ModelRegistry.defaultModel;
      final cubit = FakeModelManagerCubit(
        ModelManagerState(
          models: [
            ModelStatus(
              descriptor: defaultModel,
              state: ModelExecutionState.ready,
              localPath: '/models/qwen.gguf',
            ),
          ],
        ),
      );

      await tester.pumpWidget(buildTestableWidget(cubit));
      await tester.pump();

      expect(find.text(defaultModel.name), findsOneWidget);
      expect(find.text('Load to RAM'), findsOneWidget);
      expect(find.byTooltip('Delete Model'), findsOneWidget);
    });
  });
}
