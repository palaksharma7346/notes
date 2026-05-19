import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import 'questions_provider.dart';

class QuestionsScreen extends ConsumerWidget {
  const QuestionsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsState = ref.watch(questionsProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Questions')),
      body: questionsState.when(
        loading: () => const FeatureLoading(message: 'Drafting exam questions...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref.read(questionsProvider(sessionId).notifier).load(force: true),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return FeatureError(
              message: 'No exam questions were returned for this session.',
              onRetry: () => ref.read(questionsProvider(sessionId).notifier).load(force: true),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = questions[index];
              return SoftContainer(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  title: Text(
                    '${index + 1}. ${item.question}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(item.answer),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
