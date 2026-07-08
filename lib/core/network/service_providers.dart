import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_analysis/data/providers/local_template_llm_provider.dart';
import '../../features/ai_analysis/domain/providers/llm_provider.dart';

final llmProviderProvider = Provider<LLMProvider>((ref) {
  // Basculer vers NoopLLMProvider() pour désactiver les templates.
  return LocalTemplateLLMProvider();
});
