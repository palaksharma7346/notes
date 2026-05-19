import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../services/gemini_service.dart';
import '../home/home_provider.dart';

StudySession getSessionOrThrow(Ref ref, String sessionId) {
  final session = ref.read(sessionByIdProvider(sessionId));
  if (session == null) {
    throw Exception('This study session could not be found.');
  }
  return session;
}

String notesForSession(StudySession session) {
  return GeminiService.prepareNotesText(
    session.extractedText,
    hasImages: session.imageFiles.isNotEmpty,
  );
}

List<File> imagesForSession(StudySession session) {
  return session.imageFiles
      .map((file) => File(file.path))
      .where((file) => file.existsSync())
      .toList(growable: false);
}

List<Map<String, dynamic>> mapListFromDynamic(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
