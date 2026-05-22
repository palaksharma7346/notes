import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import '../../models/concept.dart';
import 'concepts_provider.dart';

class ConceptsScreen extends ConsumerStatefulWidget {
  const ConceptsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ConceptsScreen> createState() => _ConceptsScreenState();
}

class _ConceptsScreenState extends ConsumerState<ConceptsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conceptsState = ref.watch(conceptsProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Explain Concepts')),
      body: conceptsState.when(
        loading: () =>
            const FeatureLoading(message: 'Simplifying tricky concepts...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref
              .read(conceptsProvider(widget.sessionId).notifier)
              .load(force: true),
        ),
        data: (concepts) {
          final filtered = _filtered(concepts);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search concepts',
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching concepts',
                  subtitle: 'Try a different term from your notes.',
                )
              else
                for (final concept in filtered) ...[
                  _ConceptCard(concept: concept),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }

  List<ConceptExplanation> _filtered(List<ConceptExplanation> concepts) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return concepts;
    return concepts.where((concept) {
      return concept.term.toLowerCase().contains(query) ||
          concept.explanation.toLowerCase().contains(query);
    }).toList(growable: false);
  }
}

class _ConceptCard extends StatelessWidget {
  const _ConceptCard({required this.concept});

  final ConceptExplanation concept;

  @override
  Widget build(BuildContext context) {
    return SoftContainer(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(
          concept.term,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _preview(concept.explanation),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              concept.explanation,
              style: const TextStyle(height: 1.55),
            ),
          ),
        ],
      ),
    );
  }

  String _preview(String text) {
    if (text.length <= 110) return text;
    return '${text.substring(0, 110)}...';
  }
}
