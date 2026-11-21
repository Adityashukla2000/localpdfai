import 'package:equatable/equatable.dart';

/// Descriptor for a verified on-device GGUF language model.
class ModelDescriptor extends Equatable {
  final String id;
  final String name;
  final String description;
  final String fileName;
  final String downloadUrl;
  final int fileSizeBytes;
  final int minRamMb;
  final String quantization;
  final String license;
  final int defaultContextLength;
  final bool isRecommended;
  final String? sha256;

  const ModelDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.fileName,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.minRamMb,
    required this.quantization,
    required this.license,
    required this.defaultContextLength,
    this.isRecommended = false,
    this.sha256,
  });

  String get formattedSize {
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb < 1000) {
      return '${mb.toStringAsFixed(0)} MB';
    }
    return '${(mb / 1024).toStringAsFixed(2)} GB';
  }

  String get formattedRam {
    return '$minRamMb MB';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        fileName,
        downloadUrl,
        fileSizeBytes,
        minRamMb,
        quantization,
        license,
        defaultContextLength,
        isRecommended,
      ];
}

/// Registry of curated, actively maintained GGUF models suitable for mobile devices.
class ModelRegistry {
  static const List<ModelDescriptor> availableModels = [
    ModelDescriptor(
      id: 'qwen2.5-0.5b-instruct-q4km',
      name: 'Qwen 2.5 0.5B Instruct',
      description:
          'Ultra-compact, remarkably coherent instruction model tailored for mobile PDF Q&A and key point summarization.',
      fileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      fileSizeBytes: 397746176, // ~380 MB
      minRamMb: 700,
      quantization: 'Q4_K_M',
      license: 'Apache-2.0',
      defaultContextLength: 2048,
      isRecommended: true,
    ),
    ModelDescriptor(
      id: 'smollm2-360m-instruct-q4km',
      name: 'SmolLM2 360M Instruct',
      description:
          'Smallest footprint model with instant load times. Ideal for budget Android devices and rapid testing.',
      fileName: 'smollm2-360m-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q4_k_m.gguf',
      fileSizeBytes: 240683008, // ~230 MB
      minRamMb: 450,
      quantization: 'Q4_K_M',
      license: 'Apache-2.0',
      defaultContextLength: 2048,
      isRecommended: false,
    ),
    ModelDescriptor(
      id: 'llama-3.2-1b-instruct-q4km',
      name: 'Llama 3.2 1B Instruct',
      description:
          'Meta Llama 3.2 1B offering superior document reasoning, synthesis, and precise citation formatting.',
      fileName: 'llama-3.2-1b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      fileSizeBytes: 884736000, // ~843 MB
      minRamMb: 1400,
      quantization: 'Q4_K_M',
      license: 'Llama 3.2 Community License',
      defaultContextLength: 4096,
      isRecommended: false,
    ),
  ];

  static ModelDescriptor get defaultModel => availableModels.first;

  static ModelDescriptor? findById(String id) {
    try {
      return availableModels.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
