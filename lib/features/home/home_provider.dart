import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/session.dart';
import '../../services/session_storage_service.dart';

final sessionStorageProvider = Provider<SessionStorageService>((ref) {
  return SessionStorageService();
});

final sessionsProvider = StateNotifierProvider<SessionsNotifier, List<StudySession>>((ref) {
  return SessionsNotifier(ref.read(sessionStorageProvider));
});

final sessionByIdProvider = Provider.family<StudySession?, String>((ref, id) {
  final sessions = ref.watch(sessionsProvider);
  for (final session in sessions) {
    if (session.id == id) return session;
  }
  return null;
});

class SessionsNotifier extends StateNotifier<List<StudySession>> {
  SessionsNotifier(this._storage) : super(const []) {
    load();
  }

  final SessionStorageService _storage;

  void load() {
    state = _storage.loadSessions();
  }

  Future<void> upsertSession(StudySession session) async {
    await _storage.saveSession(session);
    final next = [
      session,
      ...state.where((item) => item.id != session.id),
    ];
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = next;
  }

  Future<void> updateFeature(String sessionId, String featureKey, dynamic value) async {
    final session = byId(sessionId);
    if (session == null) return;
    final generated = Map<String, dynamic>.from(session.generatedContent)
      ..[featureKey] = value;
    await upsertSession(session.copyWith(generatedContent: generated));
  }

  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    state = state.where((session) => session.id != id).toList(growable: false);
  }

  StudySession? byId(String id) {
    for (final session in state) {
      if (session.id == id) return session;
    }
    return null;
  }

  List<String> generatedFeatureLabels(StudySession session) {
    final labels = <String>[];
    if (session.hasFeature(FeatureKeys.summary)) labels.add('Summary');
    if (session.hasFeature(FeatureKeys.quiz)) labels.add('Quiz');
    if (session.hasFeature(FeatureKeys.flashcards)) labels.add('Cards');
    if (session.hasFeature(FeatureKeys.questions)) labels.add('Q&A');
    if (session.hasFeature(FeatureKeys.topics)) labels.add('Topics');
    if (session.hasFeature(FeatureKeys.concepts)) labels.add('Concepts');
    return labels;
  }
}
