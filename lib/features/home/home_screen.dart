import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../models/session.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/upload'),
        child: const Icon(Icons.add_rounded, size: 36),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, Scholar 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Turn notes into summaries, quizzes, flashcards, and exam prep.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 26),
                    const SectionTitle('Recent Sessions'),
                  ],
                ),
              ),
            ),
            if (sessions.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.upload_file_rounded,
                  title: 'Upload your first notes to get started',
                  subtitle: 'PDFs, photos, and scanned handwritten notes all work.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverList.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _SessionCard(session: sessions[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.read(sessionsProvider.notifier).generatedFeatureLabels(session);
    final date = DateFormat('MMM d, yyyy • h:mm a').format(session.createdAt);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/hub/${session.id}'),
      child: SoftContainer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                session.files.any((file) => file.type == NoteFileType.pdf)
                    ? Icons.picture_as_pdf_rounded
                    : Icons.image_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (features.isEmpty)
                        const _FeatureBadge(label: 'Ready')
                      else
                        ...features.map((label) => _FeatureBadge(label: label)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete session',
              onPressed: () => ref.read(sessionsProvider.notifier).deleteSession(session.id),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
