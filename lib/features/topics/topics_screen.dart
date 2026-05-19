import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import 'topics_provider.dart';

class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsState = ref.watch(topicsProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Topic Notes')),
      body: topicsState.when(
        loading: () => const FeatureLoading(message: 'Organizing topic-wise notes...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref.read(topicsProvider(sessionId).notifier).load(force: true),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return FeatureError(
              message: 'No topic notes were returned for this session.',
              onRetry: () => ref.read(topicsProvider(sessionId).notifier).load(force: true),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return SoftContainer(
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  title: Text(
                    topic.topic,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(topic.description),
                  ),
                  children: [
                    for (final subtopic in topic.subtopics) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subtopic.heading,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final point in subtopic.points)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(height: 1.6)),
                              Expanded(
                                child: Text(
                                  point,
                                  style: const TextStyle(height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
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
