import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/notebook_entry.dart';
import '../../../services/notebook_service.dart';

class VocabTab extends StatefulWidget {
  final Lesson lesson;
  final NotebookService notebookService;

  const VocabTab({
    super.key,
    required this.lesson,
    required this.notebookService,
  });

  @override
  State<VocabTab> createState() => _VocabTabState();
}

class _VocabTabState extends State<VocabTab> {
  final Set<String> _saved = {};

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  void _loadSaved() {
    for (final v in widget.lesson.vocabulary) {
      if (widget.notebookService.contains(v.word, widget.lesson.id)) {
        _saved.add(v.word);
      }
    }
  }

  Future<void> _toggleSave(LessonVocabulary v) async {
    if (_saved.contains(v.word)) {
      // Already saved — don't remove from notebook here (use notebook screen)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déjà dans ton carnet.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final entry = NotebookEntry(
      id: '${widget.lesson.id}_${v.word.replaceAll(' ', '_')}',
      word: v.word,
      definition: v.definition,
      exampleSentence: v.exampleSentence,
      translation: v.translation,
      lessonId: widget.lesson.id,
      lessonTitle: widget.lesson.title,
      savedAt: DateTime.now(),
    );

    await widget.notebookService.save(entry);
    setState(() => _saved.add(v.word));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${v.word}" ajouté au carnet !'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.lesson.vocabulary;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vocab.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final v = vocab[i];
        final isSaved = _saved.contains(v.word);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSaved
                  ? AppTheme.accent.withValues(alpha: 0.4)
                  : AppTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.word,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.translation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _toggleSave(v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSaved
                            ? const Color(0xFFD1FAE5)
                            : AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSaved ? AppTheme.accent : AppTheme.border,
                        ),
                      ),
                      child: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isSaved ? AppTheme.accent : AppTheme.muted,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 10),
              Text(
                v.definition,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💬 ',
                      style: TextStyle(fontSize: 13),
                    ),
                    Expanded(
                      child: Text(
                        v.exampleSentence,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.muted,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
