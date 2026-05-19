import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../models/session.dart';

class SessionStorageService {
  Box<dynamic> get _box => Hive.box<dynamic>(AppConstants.sessionsBox);

  List<StudySession> loadSessions() {
    final sessions = _box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(StudySession.fromJson)
        .where((session) => session.id.isNotEmpty)
        .toList();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sessions;
  }

  Future<void> saveSession(StudySession session) async {
    await _box.put(session.id, session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
