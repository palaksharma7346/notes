import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import 'summary_provider.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(summaryProvider(sessionId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            onPressed: summaryState.hasValue
                ? () async {
                    await Clipboard.setData(ClipboardData(text: summaryState.value!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Summary copied')),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.copy_rounded),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: summaryState.hasValue ? () => Share.share(summaryState.value!) : null,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: summaryState.when(
        loading: () => const FeatureLoading(message: 'Generating your summary...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref.read(summaryProvider(sessionId).notifier).load(force: true),
        ),
        data: (summary) {
          final parts = _SummaryParts.from(summary);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              SoftContainer(
                color: AppColors.primary,
                child: Text(
                  parts.overview,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Key Concepts'),
              const SizedBox(height: 10),
              SoftContainer(
                child: Text(
                  parts.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 18),
              SoftContainer(
                color: AppColors.warning.withOpacity(0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Remember This',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(parts.remember),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PopupMenuButton<String>(
                onSelected: (style) => ref
                    .read(summaryProvider(sessionId).notifier)
                    .load(force: true, style: style),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Simple', child: Text('Simple')),
                  PopupMenuItem(value: 'Detailed', child: Text('Detailed')),
                  PopupMenuItem(value: 'Exam-focused', child: Text('Exam-focused')),
                ],
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Regenerate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryParts {
  const _SummaryParts({
    required this.overview,
    required this.body,
    required this.remember,
  });

  final String overview;
  final String body;
  final String remember;

  factory _SummaryParts.from(String raw) {
    final clean = raw.trim();
    final paragraphs = clean.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).toList();
    final overview = paragraphs.isEmpty ? clean : paragraphs.first.trim();

    final rememberIndex = clean.toLowerCase().lastIndexOf('remember');
    final remember = rememberIndex >= 0 ? clean.substring(rememberIndex).trim() : '1. Review the highest-level ideas.\n2. Practice applying each concept.\n3. Revisit anything that still feels fuzzy.';

    var body = clean;
    if (paragraphs.isNotEmpty) {
      body = clean.replaceFirst(paragraphs.first, '').trim();
    }
    if (rememberIndex > 0) {
      body = body.replaceFirst(clean.substring(rememberIndex), '').trim();
    }
    if (body.isEmpty) body = clean;

    return _SummaryParts(overview: overview, body: body, remember: remember);
  }
}
