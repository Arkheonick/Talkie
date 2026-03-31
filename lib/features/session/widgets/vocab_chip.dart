import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/vocabulary_entry.dart';

class VocabChip extends StatelessWidget {
  final VocabularyEntry entry;

  const VocabChip({super.key, required this.entry});

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.word,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.onSurface)),
            const SizedBox(height: 4),
            Text(entry.translation,
                style: const TextStyle(color: AppTheme.primary, fontSize: 15)),
            const SizedBox(height: 12),
            Text(entry.definition,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 15, height: 1.4)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${entry.exampleSentence}"',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          entry.word,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
