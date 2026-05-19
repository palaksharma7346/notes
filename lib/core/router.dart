import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/concepts/concepts_screen.dart';
import '../features/flashcards/flashcard_screen.dart';
import '../features/home/home_screen.dart';
import '../features/hub/hub_screen.dart';
import '../features/processing/processing_screen.dart';
import '../features/questions/questions_screen.dart';
import '../features/quiz/quiz_result_screen.dart';
import '../features/quiz/quiz_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/summary/summary_screen.dart';
import '../features/topics/topics_screen.dart';
import '../features/upload/upload_screen.dart';
import '../models/session.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/processing',
        builder: (context, state) {
          final files = state.extra is List<NoteFile>
              ? state.extra! as List<NoteFile>
              : <NoteFile>[];
          return ProcessingScreen(files: files);
        },
      ),
      GoRoute(
        path: '/hub/:sessionId',
        builder: (context, state) => HubScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/summary/:sessionId',
        builder: (context, state) => SummaryScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:sessionId',
        builder: (context, state) => QuizScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:sessionId/result',
        builder: (context, state) => QuizResultScreen(
          sessionId: state.pathParameters['sessionId']!,
          score: int.tryParse(state.uri.queryParameters['score'] ?? '') ?? 0,
          total: int.tryParse(state.uri.queryParameters['total'] ?? '') ?? 10,
        ),
      ),
      GoRoute(
        path: '/flashcards/:sessionId',
        builder: (context, state) => FlashcardScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/questions/:sessionId',
        builder: (context, state) => QuestionsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/topics/:sessionId',
        builder: (context, state) => TopicsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: '/concepts/:sessionId',
        builder: (context, state) => ConceptsScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
    ],
  );
});
