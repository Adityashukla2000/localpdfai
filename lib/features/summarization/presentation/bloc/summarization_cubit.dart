import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_pdf_ai/features/documents/domain/models/document_entity.dart';
import 'package:local_pdf_ai/features/summarization/data/services/summary_service.dart';

class SummarizationState extends Equatable {
  final bool isLoading;
  final String? currentStep;
  final DocumentSummaryResult? result;
  final String? errorMessage;

  const SummarizationState({
    this.isLoading = false,
    this.currentStep,
    this.result,
    this.errorMessage,
  });

  SummarizationState copyWith({
    bool? isLoading,
    String? currentStep,
    DocumentSummaryResult? result,
    String? errorMessage,
  }) {
    return SummarizationState(
      isLoading: isLoading ?? this.isLoading,
      currentStep: currentStep ?? this.currentStep,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, currentStep, result, errorMessage];
}

class SummarizationCubit extends Cubit<SummarizationState> {
  final SummaryService _summaryService;

  SummarizationCubit({required this._summaryService})
      : super(const SummarizationState());

  Future<void> generateSummary({
    required DocumentEntity document,
    SummaryType type = SummaryType.detailed,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      currentStep: 'Preparing document context...',
      errorMessage: null,
      result: null,
    ));

    try {
      final summary = await _summaryService.generateSummary(
        document: document,
        type: type,
        onProgress: (step) {
          emit(state.copyWith(currentStep: step));
        },
      );

      emit(state.copyWith(
        isLoading: false,
        currentStep: null,
        result: summary,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        currentStep: null,
        errorMessage: e.toString(),
      ));
    }
  }
}
