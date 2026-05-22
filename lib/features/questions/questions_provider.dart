import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/exam_question.dart';
import '../../services/huggingface_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final questionsProvider = StateNotifierProvider.family<QuestionsNotifier,
    AsyncValue<List<ExamQuestion>>, String>((ref, sessionId) {
  return QuestionsNotifier(ref, sessionId);
});

class QuestionsNotifier extends StateNotifier<AsyncValue<List<ExamQuestion>>> {
  QuestionsNotifier(this.ref, this.sessionId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached =
        mapListFromDynamic(session.generatedContent[FeatureKeys.questions]);
    if (!force && cached.isNotEmpty) {
      state = AsyncValue.data(
        cached
            .map((json) => ExamQuestion.fromJson(json))
            .toList(growable: false),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final raw = await HuggingFaceService.generateExamQuestions(
        notesForSession(session),
        images: imagesForSession(session),
      );
      await ref
          .read(sessionsProvider.notifier)
          .updateFeature(sessionId, FeatureKeys.questions, raw);
      state = AsyncValue.data(
        raw.map((json) => ExamQuestion.fromJson(json)).toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
