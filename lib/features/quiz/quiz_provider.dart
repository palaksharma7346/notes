import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/quiz_question.dart';
import '../../services/huggingface_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final quizProvider = StateNotifierProvider.family<QuizNotifier,
    AsyncValue<List<QuizQuestion>>, String>((ref, sessionId) {
  return QuizNotifier(ref, sessionId);
});

class QuizNotifier extends StateNotifier<AsyncValue<List<QuizQuestion>>> {
  QuizNotifier(this.ref, this.sessionId) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached =
        mapListFromDynamic(session.generatedContent[FeatureKeys.quiz]);
    if (!force && cached.isNotEmpty) {
      state = AsyncValue.data(
        cached
            .map((json) => QuizQuestion.fromJson(json))
            .toList(growable: false),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final raw = await HuggingFaceService.generateQuiz(
        notesForSession(session),
        images: imagesForSession(session),
      );
      await ref
          .read(sessionsProvider.notifier)
          .updateFeature(sessionId, FeatureKeys.quiz, raw);
      state = AsyncValue.data(
        raw.map((json) => QuizQuestion.fromJson(json)).toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
