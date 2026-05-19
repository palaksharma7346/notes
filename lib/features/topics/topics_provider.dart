import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/topic_note.dart';
import '../../services/gemini_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final topicsProvider = StateNotifierProvider.family<TopicsNotifier,
    AsyncValue<List<TopicNote>>, String>((ref, sessionId) {
  return TopicsNotifier(ref, sessionId);
});

class TopicsNotifier extends StateNotifier<AsyncValue<List<TopicNote>>> {
  TopicsNotifier(this.ref, this.sessionId) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached = mapListFromDynamic(session.generatedContent[FeatureKeys.topics]);
    if (!force && cached.isNotEmpty) {
      state = AsyncValue.data(
        cached.map((json) => TopicNote.fromJson(json)).toList(growable: false),
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final raw = await GeminiService.generateTopicNotes(
        notesForSession(session),
        images: imagesForSession(session),
      );
      await ref.read(sessionsProvider.notifier).updateFeature(sessionId, FeatureKeys.topics, raw);
      state = AsyncValue.data(
        raw.map((json) => TopicNote.fromJson(json)).toList(growable: false),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
