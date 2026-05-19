import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.sessionId,
    required this.score,
    required this.total,
  });

  final String sessionId;
  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : score / total;
    return Scaffold(
      appBar: AppBar(title: const Text('Final Score')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 190,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 16,
                        color: _scoreColor(percent),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    Text(
                      '$score / $total',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                _message(percent),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Review missed concepts, then try the quiz again when you are ready.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Try Again',
                icon: Icons.replay_rounded,
                onPressed: () => context.go('/quiz/$sessionId'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/hub/$sessionId'),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Back to Hub'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double percent) {
    if (percent >= 0.75) return AppColors.success;
    if (percent >= 0.5) return AppColors.warning;
    return AppColors.danger;
  }

  String _message(double percent) {
    if (percent >= 0.9) return 'Excellent. You own this material.';
    if (percent >= 0.7) return 'Strong work. A little review will lock it in.';
    if (percent >= 0.5) return 'Good start. Revisit the tricky parts.';
    return 'Keep going. This is exactly what practice is for.';
  }
}
