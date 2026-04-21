import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/notebook_entry.dart';
import '../../../models/vocab_folder.dart';
import '../../../services/notebook_service.dart';
import '../../../services/vocab_folder_service.dart';

class VocabTab extends StatefulWidget {
  final Lesson lesson;
  final NotebookService notebookService;
  final VocabFolderService folderService;

  const VocabTab({
    super.key,
    required this.lesson,
    required this.notebookService,
    required this.folderService,
  });

  @override
  State<VocabTab> createState() => _VocabTabState();
}

class _VocabTabState extends State<VocabTab> {
  List<VocabFolder> _folders = [];
  final Set<String> _saved = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _folders = widget.folderService.getFoldersForLesson(widget.lesson.id);
    for (final v in widget.lesson.vocabulary) {
      if (widget.notebookService.contains(v.word, widget.lesson.id)) {
        _saved.add(v.word);
      }
    }
  }

  // ── Save word with folder picker ───────────────────────────────────────────

  Future<void> _saveWord(LessonVocabulary v) async {
    if (_saved.contains(v.word)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Déjà dans le Lexique.'),
            duration: Duration(seconds: 1)),
      );
      return;
    }

    final folderId = await _showFolderPicker();
    if (!mounted) return;

    final entry = NotebookEntry(
      id: '${widget.lesson.id}_${v.word.replaceAll(' ', '_')}',
      word: v.word,
      definition: v.definition,
      exampleSentence: v.exampleSentence,
      translation: v.translation,
      lessonId: widget.lesson.id,
      lessonTitle: widget.lesson.title,
      savedAt: DateTime.now(),
      folderId: folderId,
    );

    await widget.notebookService.save(entry);
    setState(() => _saved.add(v.word));

    if (!mounted) return;
    final folderName = folderId == null
        ? 'Lexique'
        : _folders.firstWhere((f) => f.id == folderId).name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${v.word}" → $folderName'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shows a bottom sheet to pick a folder (or create one).
  /// Returns the chosen folderId, or null (= no folder / root).
  Future<String?> _showFolderPicker() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FolderPickerSheet(
        lessonId: widget.lesson.id,
        folders: _folders,
        folderService: widget.folderService,
        onFoldersChanged: () {
          setState(() {
            _folders =
                widget.folderService.getFoldersForLesson(widget.lesson.id);
          });
        },
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
                    onTap: () => _saveWord(v),
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
                          color:
                              isSaved ? AppTheme.accent : AppTheme.border,
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
                    const Text('💬 ', style: TextStyle(fontSize: 13)),
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

// ── Folder picker bottom sheet ─────────────────────────────────────────────────

class _FolderPickerSheet extends StatefulWidget {
  final String lessonId;
  final List<VocabFolder> folders;
  final VocabFolderService folderService;
  final VoidCallback onFoldersChanged;

  const _FolderPickerSheet({
    required this.lessonId,
    required this.folders,
    required this.folderService,
    required this.onFoldersChanged,
  });

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  Future<void> _createFolder() async {
    final name = await _showNameDialog(context, 'Nouveau dossier', '');
    if (name == null || name.trim().isEmpty) return;
    final folder =
        await widget.folderService.createFolder(widget.lessonId, name.trim());
    widget.onFoldersChanged();
    if (mounted) Navigator.pop(context, folder.id);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sauvegarder dans...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _pickerBtn(
                  icon: Icons.bookmark_rounded,
                  label: 'Sans dossier',
                  accent: false,
                  onTap: () => Navigator.pop(context, null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerBtn(
                  icon: Icons.create_new_folder_rounded,
                  label: '+ Nouveau dossier',
                  accent: true,
                  onTap: _createFolder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pickerBtn({
    required IconData icon,
    required String label,
    required bool accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: accent ? AppTheme.primary : Colors.white,
          border: Border.all(
              color: accent ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: accent ? Colors.white : AppTheme.onSurface),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


Future<String?> _showNameDialog(
    BuildContext context, String title, String initial) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Nom du dossier'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Créer')),
      ],
    ),
  );
}
