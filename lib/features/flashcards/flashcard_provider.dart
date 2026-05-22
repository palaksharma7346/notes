import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/flashcard.dart';
import '../../services/huggingface_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final flashcardsProvider = StateNotifierProvider.family<FlashcardsNotifier,
    AsyncValue<List<Flashcard>>, String>((ref, sessionId) {
  return FlashcardsNotifier(ref, sessionId);
});

class FlashcardsNotifier extends StateNotifier<AsyncValue<List<Flashcard>>> {
  FlashcardsNotifier(this.ref, this.sessionId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached =
        mapListFromDynamic(session.generatedContent[FeatureKeys.flashcards]);
    if (!force && cached.isNotEmpty) {
      state = AsyncValue.data(
        cached.map((json) => Flashcard.fromJson(json)).toList(growable: false),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final raw = await HuggingFaceService.generateFlashcards(
        notesForSession(session),
        images: imagesForSession(session),
      );
      await ref
          .read(sessionsProvider.notifier)
          .updateFeature(sessionId, FeatureKeys.flashcards, raw);
      state = AsyncValue.data(
        raw.map((json) => Flashcard.fromJson(json)).toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
