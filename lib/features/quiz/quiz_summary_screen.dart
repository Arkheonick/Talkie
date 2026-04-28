import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/quiz_session.dart';

class QuizSummaryScreen extends StatelessWidget {
  final QuizSession session;

  const QuizSummaryScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final accuracy = (session.overallAccuracy * 100).round();
    final tierReached = session.currentTier;
    final isCompleted = tierReached >= 20;

    final accuracyColor = accuracy < 50
        ? Colors.red.shade400
        : accuracy < 70
            ? Colors.orange.shade400
            : accuracy < 90
                ? AppTheme.primary
                : Colors.green.shade500;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          '${session.themeEmoji} ${session.themeLabel}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // Trophy or star
              Text(
                isCompleted ? '🏆' : '⭐',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                isCompleted ? 'Quiz complété !' : 'Bilan du quiz',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isCompleted
                    ? 'Tu as atteint le tier maximum. Impressionnant !'
                    : 'Tu as progressé jusqu\'au tier $tierReached.',
                style: TextStyle(color: AppTheme.muted, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Tier atteint',
                      value: '$tierReached / 20',
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Précision',
                      value: '$accuracy %',
                      icon: Icons.track_changes_rounded,
                      color: accuracyColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Bonnes réponses',
                      value: '${session.totalCorrect}',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green.shade500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Questions répondues',
                      value: '${session.totalAnswered}',
                      icon: Icons.quiz_outlined,
                      color: AppTheme.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Choisir un nouveau thème'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}
