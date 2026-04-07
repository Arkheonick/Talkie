import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/notebook_entry.dart';
import '../../services/notebook_service.dart';
import 'flashcard_screen.dart';

class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  final _notebookService = NotebookService();
  List<NotebookEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notebookService.init();
    setState(() {
      _entries = _notebookService.loadAll();
      _loading = false;
    });
  }

  Future<void> _delete(NotebookEntry entry) async {
    await _notebookService.delete(entry.id);
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
  }

  Future<void> _toggleMastered(NotebookEntry entry) async {
    await _notebookService.toggleMastered(entry);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final toLearn = _entries.where((e) => !e.isMastered).toList();
    final mastered = _entries.where((e) => e.isMastered).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Text('Mon Carnet'),
            const SizedBox(width: 8),
            if (_entries.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_entries.length}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (toLearn.isNotEmpty)
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlashcardScreen(entries: toLearn),
                ),
              ).then((_) => _load()),
              icon: const Icon(Icons.style_rounded, size: 16),
              label: const Text('Flashcards'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _EmptyState()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (toLearn.isNotEmpty) ...[
                      _SectionLabel(
                        label: 'À apprendre (${toLearn.length})',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 10),
                      ...toLearn.map((e) => _EntryCard(
                            entry: e,
                            onDelete: () => _delete(e),
                            onToggleMastered: () => _toggleMastered(e),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (mastered.isNotEmpty) ...[
                      _SectionLabel(
                        label: 'Maîtrisé (${mastered.length})',
                        color: AppTheme.accent,
                      ),
                      const SizedBox(height: 10),
                      ...mastered.map((e) => _EntryCard(
                            entry: e,
                            onDelete: () => _delete(e),
                            onToggleMastered: () => _toggleMastered(e),
                          )),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _EntryCard extends StatefulWidget {
  final NotebookEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onToggleMastered;

  const _EntryCard({
    required this.entry,
    required this.onDelete,
    required this.onToggleMastered,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: e.isMastered
                ? AppTheme.accent.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.word,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          e.translation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mastered toggle
                  GestureDetector(
                    onTap: widget.onToggleMastered,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: e.isMastered
                            ? const Color(0xFFD1FAE5)
                            : AppTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: e.isMastered ? AppTheme.accent : AppTheme.border,
                        ),
                      ),
                      child: Icon(
                        e.isMastered
                            ? Icons.check_rounded
                            : Icons.check_rounded,
                        color: e.isMastered ? AppTheme.accent : AppTheme.border,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Delete
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.muted, size: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1, color: AppTheme.border),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.definition,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💬 ${e.exampleSentence}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.muted,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'De : ${e.lessonTitle}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Ton carnet est vide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sauvegarde des mots depuis les leçons\npour les retrouver ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
