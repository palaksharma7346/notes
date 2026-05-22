import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/concept.dart';
import '../../services/huggingface_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final conceptsProvider = StateNotifierProvider.family<ConceptsNotifier,
    AsyncValue<List<ConceptExplanation>>, String>((ref, sessionId) {
  return ConceptsNotifier(ref, sessionId);
});

class ConceptsNotifier
    extends StateNotifier<AsyncValue<List<ConceptExplanation>>> {
  ConceptsNotifier(this.ref, this.sessionId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached =
        mapListFromDynamic(session.generatedContent[FeatureKeys.concepts]);
    if (!force && cached.isNotEmpty) {
      state = AsyncValue.data(
        cached
            .map((json) => ConceptExplanation.fromJson(json))
            .toList(growable: false),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final raw = await HuggingFaceService.generateConceptExplanations(
        notesForSession(session),
        images: imagesForSession(session),
      );
      await ref
          .read(sessionsProvider.notifier)
          .updateFeature(sessionId, FeatureKeys.concepts, raw);
      state = AsyncValue.data(
        raw
            .map((json) => ConceptExplanation.fromJson(json))
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
