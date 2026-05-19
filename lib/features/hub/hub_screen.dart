import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../home/home_provider.dart';

class HubScreen extends ConsumerWidget {
  const HubScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionByIdProvider(sessionId));
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study Hub')),
        body: FeatureError(
          message: 'This session is no longer available.',
          onRetry: () => context.go('/home'),
        ),
      );
    }

    final features = [
      _FeatureCardData('📝', 'Summary', 'Key points at a glance', '/summary/$sessionId'),
      _FeatureCardData('🧠', 'Quiz', 'Test your knowledge', '/quiz/$sessionId'),
      _FeatureCardData('🃏', 'Flashcards', 'Active recall practice', '/flashcards/$sessionId'),
      _FeatureCardData('❓', 'Exam Questions', 'Likely exam questions', '/questions/$sessionId'),
      _FeatureCardData('📚', 'Topic Notes', 'Organized by topic', '/topics/$sessionId'),
      _FeatureCardData('💡', 'Explain Concepts', 'Simplified explanations', '/concepts/$sessionId'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Hub'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              session.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${session.files.length} file${session.files.length == 1 ? '' : 's'} ready for AI study tools',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final feature = features[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push(feature.route),
                  child: SoftContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(feature.icon, style: const TextStyle(fontSize: 34)),
                        const Spacer(),
                        Text(
                          feature.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          feature.description,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData(this.icon, this.name, this.description, this.route);

  final String icon;
  final String name;
  final String description;
  final String route;
}
