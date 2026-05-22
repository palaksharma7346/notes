import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../models/quiz_question.dart';
import 'quiz_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  int? _selected;
  int _score = 0;

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: quizState.when(
        loading: () => const FeatureLoading(message: 'Building your quiz...'),
        error: (error, _) => FeatureError(
          message: error.toString(),
          onRetry: () => ref
              .read(quizProvider(widget.sessionId).notifier)
              .load(force: true),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return FeatureError(
              message:
                  'Hugging Face did not return quiz questions for this session.',
              onRetry: () => ref
                  .read(quizProvider(widget.sessionId).notifier)
                  .load(force: true),
            );
          }
          final safeIndex = _index.clamp(0, questions.length - 1);
          final question = questions[safeIndex];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Row(
                children: [
                  Text(
                    'Question ${safeIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text('Score $_score',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (safeIndex + 1) / questions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 18),
              SoftContainer(
                child: Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < question.options.length; i++) ...[
                _OptionButton(
                  index: i,
                  option: question.options[i],
                  selected: _selected,
                  correctIndex: question.correctIndex,
                  onTap: () => _answer(question, i),
                ),
                const SizedBox(height: 12),
              ],
              if (_selected != null) ...[
                ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  title: const Text(
                    'Explain this answer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  children: [
                    SoftContainer(
                      child: Text(question.explanation),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: safeIndex == questions.length - 1
                      ? 'See Final Score'
                      : 'Next Question →',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => _next(questions.length),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _answer(QuizQuestion question, int optionIndex) {
    if (_selected != null) return;
    setState(() {
      _selected = optionIndex;
      if (optionIndex == question.correctIndex) _score++;
    });
  }

  void _next(int total) {
    if (_index == total - 1) {
      context.pushReplacement(
          '/quiz/${widget.sessionId}/result?score=$_score&total=$total');
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.index,
    required this.option,
    required this.selected,
    required this.correctIndex,
    required this.onTap,
  });

  final int index;
  final String option;
  final int? selected;
  final int correctIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wasAnswered = selected != null;
    final isCorrect = index == correctIndex;
    final isSelected = index == selected;
    final color = !wasAnswered
        ? Colors.white
        : isCorrect
            ? AppColors.success
            : isSelected
                ? AppColors.danger
                : Colors.white;
    final foreground = color == Colors.white ? AppColors.ink : Colors.white;
    final label = String.fromCharCode(65 + index);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: wasAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color == Colors.white
                ? AppColors.accent.withOpacity(0.25)
                : color,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor:
                  foreground.withOpacity(color == Colors.white ? 0.08 : 0.18),
              child: Text(
                label,
                style:
                    TextStyle(color: foreground, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style:
                    TextStyle(color: foreground, fontWeight: FontWeight.w700),
              ),
            ),
            if (wasAnswered && (isCorrect || isSelected))
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: foreground,
              ),
          ],
        ),
      ),
    );
  }
}
