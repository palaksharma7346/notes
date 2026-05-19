import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../models/flashcard.dart';
import 'flashcard_provider.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  int _index = 0;
  bool _flipped = false;
  final Set<int> _known = {};

  @override
  Widget build(BuildContext context) {
    final cardsState = ref.watch(flashcardsProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: cardsState.when(
        loading: () => const FeatureLoading(message: 'Creating flashcards...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref.read(flashcardsProvider(widget.sessionId).notifier).load(force: true),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return FeatureError(
              message: 'No flashcards were returned for this session.',
              onRetry: () =>
                  ref.read(flashcardsProvider(widget.sessionId).notifier).load(force: true),
            );
          }
          final safeIndex = _index.clamp(0, cards.length - 1) as int;
          final card = cards[safeIndex];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  Text(
                    'Card ${safeIndex + 1} of ${cards.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text('${_known.length} known', style: const TextStyle(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: cards.isEmpty ? 0 : _known.length / cards.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.success,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _flip,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 120) _markKnown(cards.length, true);
                  if (velocity < -120) _markKnown(cards.length, false);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _StudyCard(
                    key: ValueKey('${safeIndex}_$_flipped'),
                    card: card,
                    isBack: _flipped,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: const [
                  Expanded(
                    child: _SwipeHint(
                      icon: Icons.keyboard_arrow_left_rounded,
                      label: 'Review again',
                      color: AppColors.danger,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _SwipeHint(
                      icon: Icons.keyboard_arrow_right_rounded,
                      label: 'Got it ✓',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: safeIndex == 0 ? null : () => _move(-1),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _flip,
                      icon: const Icon(Icons.flip_rounded),
                      label: const Text('Flip Card'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: safeIndex == cards.length - 1 ? null : () => _move(1),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _flip() {
    setState(() => _flipped = !_flipped);
  }

  void _move(int delta) {
    setState(() {
      _index += delta;
      _flipped = false;
    });
  }

  void _markKnown(int total, bool known) {
    setState(() {
      if (known) {
        _known.add(_index);
      } else {
        _known.remove(_index);
      }
      if (_index < total - 1) _index++;
      _flipped = false;
    });
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    super.key,
    required this.card,
    required this.isBack,
  });

  final Flashcard card;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBack
              ? const [Color(0xFF7C3AED), AppColors.primary]
              : const [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          isBack ? card.back : card.front,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
