import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../services/huggingface_service.dart';
import '../common/feature_provider_utils.dart';
import '../home/home_provider.dart';

final summaryProvider =
    StateNotifierProvider.family<SummaryNotifier, AsyncValue<String>, String>(
        (ref, sessionId) {
  return SummaryNotifier(ref, sessionId);
});

class SummaryNotifier extends StateNotifier<AsyncValue<String>> {
  SummaryNotifier(this.ref, this.sessionId)
      : super(const AsyncValue.loading()) {
    load();
  }

  final Ref ref;
  final String sessionId;

  Future<void> load({bool force = false, String style = 'Detailed'}) async {
    final session = getSessionOrThrow(ref, sessionId);
    final cached = session.generatedContent[FeatureKeys.summary];
    if (!force && cached is String && cached.isNotEmpty) {
      state = AsyncValue.data(cached);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await HuggingFaceService.generateSummary(
        notesForSession(session),
        images: imagesForSession(session),
        style: style,
      );
      await ref.read(sessionsProvider.notifier).updateFeature(
            sessionId,
            FeatureKeys.summary,
            result,
          );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
