import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/notebook_entry.dart';
import '../../models/vocab_folder.dart';
import '../../services/notebook_service.dart';
import '../../services/vocab_folder_service.dart';
import '../notebook/flashcard_screen.dart';

class LexiqueScreen extends StatefulWidget {
  const LexiqueScreen({super.key});

  @override
  State<LexiqueScreen> createState() => _LexiqueScreenState();
}

class _LexiqueScreenState extends State<LexiqueScreen> {
  final _notebookService = NotebookService();
  final _folderService = VocabFolderService();

  List<NotebookEntry> _entries = [];
  List<VocabFolder> _folders = [];
  Map<String, String> _aliases = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notebookService.init();
    await _folderService.init();
    setState(() {
      _entries = _notebookService.loadAll();
      _folders = _folderService.getAllFolders();
      _aliases = _folderService.getAllAliases();
      _loading = false;
    });
  }

  Future<void> _reload() async {
    setState(() {
      _entries = _notebookService.loadAll();
      _folders = _folderService.getAllFolders();
      _aliases = _folderService.getAllAliases();
    });
  }

  // ── Lesson groups ──────────────────────────────────────────────────────────

  Map<String, List<NotebookEntry>> get _byLesson {
    final map = <String, List<NotebookEntry>>{};
    for (final e in _entries) {
      map.putIfAbsent(e.lessonId, () => []).add(e);
    }
    return map;
  }

  String _lessonName(String lessonId, String defaultTitle) =>
      _aliases[lessonId] ?? defaultTitle;

  Future<void> _renameLessonGroup(
      String lessonId, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer le dialogue'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Renommer')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await _folderService.setLessonDisplayName(lessonId, name.trim());
    _reload();
  }

  // ── Folder actions ─────────────────────────────────────────────────────────

  Future<void> _createFolder(String lessonId) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouveau dossier'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom du dossier'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Créer')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await _folderService.createFolder(lessonId, name.trim());
    _reload();
  }

  Future<void> _renameFolder(VocabFolder folder) async {
    final ctrl = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renommer le dossier'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nom'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Renommer')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await _folderService.renameFolder(folder, name.trim());
    _reload();
  }

  Future<void> _deleteFolder(VocabFolder folder) async {
    // Move entries in this folder back to root (folderId = null)
    final affected = _entries.where((e) => e.folderId == folder.id).toList();
    for (final e in affected) {
      e.folderId = null;
      await _notebookService.save(e);
    }
    await _folderService.deleteFolder(folder.id);
    _reload();
  }

  Future<void> _deleteEntry(NotebookEntry entry) async {
    await _notebookService.delete(entry.id);
    _reload();
  }

  Future<void> _toggleMastered(NotebookEntry entry) async {
    await _notebookService.toggleMastered(entry);
    _reload();
  }

  // ── Move entry to folder ───────────────────────────────────────────────────

  Future<void> _moveEntry(NotebookEntry entry, String lessonId) async {
    final lessonFolders =
        _folders.where((f) => f.lessonId == lessonId).toList();
    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoveFolderSheet(
          folders: lessonFolders, currentFolderId: entry.folderId),
    );
    if (!mounted) return;
    // chosen == null means "cancel", chosen == '' means "no folder"
    if (chosen == 'cancel') return;
    entry.folderId = chosen == '' ? null : chosen;
    await _notebookService.save(entry);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _byLesson;
    final toLearn = _entries.where((e) => !e.isMastered).toList();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Text('Lexique'),
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
                    builder: (_) => FlashcardScreen(entries: toLearn)),
              ).then((_) => _load()),
              icon: const Icon(Icons.style_rounded, size: 16),
              label: const Text('Flashcards'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : grouped.isEmpty
              ? _empty()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((lessonEntry) {
                    final lessonId = lessonEntry.key;
                    final lessonEntries = lessonEntry.value;
                    final defaultTitle =
                        lessonEntries.first.lessonTitle.isNotEmpty
                            ? lessonEntries.first.lessonTitle
                            : lessonId;
                    final displayName = _lessonName(lessonId, defaultTitle);
                    final lessonFolders = _folders
                        .where((f) => f.lessonId == lessonId)
                        .toList();
                    return _LessonGroup(
                      lessonId: lessonId,
                      displayName: displayName,
                      entries: lessonEntries,
                      folders: lessonFolders,
                      onRename: () =>
                          _renameLessonGroup(lessonId, displayName),
                      onCreateFolder: () => _createFolder(lessonId),
                      onRenameFolder: _renameFolder,
                      onDeleteFolder: _deleteFolder,
                      onDeleteEntry: _deleteEntry,
                      onToggleMastered: _toggleMastered,
                      onMoveEntry: (e) => _moveEntry(e, lessonId),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📖', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Ton lexique est vide',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface)),
          SizedBox(height: 8),
          Text(
            'Sauvegarde des mots depuis les leçons\nou le chat pour les retrouver ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: AppTheme.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Lesson group (expandable) ──────────────────────────────────────────────────

class _LessonGroup extends StatefulWidget {
  final String lessonId;
  final String displayName;
  final List<NotebookEntry> entries;
  final List<VocabFolder> folders;
  final VoidCallback onRename;
  final VoidCallback onCreateFolder;
  final void Function(VocabFolder) onRenameFolder;
  final void Function(VocabFolder) onDeleteFolder;
  final void Function(NotebookEntry) onDeleteEntry;
  final void Function(NotebookEntry) onToggleMastered;
  final void Function(NotebookEntry) onMoveEntry;

  const _LessonGroup({
    required this.lessonId,
    required this.displayName,
    required this.entries,
    required this.folders,
    required this.onRename,
    required this.onCreateFolder,
    required this.onRenameFolder,
    required this.onDeleteFolder,
    required this.onDeleteEntry,
    required this.onToggleMastered,
    required this.onMoveEntry,
  });

  @override
  State<_LessonGroup> createState() => _LessonGroupState();
}

class _LessonGroupState extends State<_LessonGroup> {
  bool _expanded = true;

  List<NotebookEntry> _entriesInFolder(String? folderId) => widget.entries
      .where((e) => e.folderId == folderId)
      .toList();

  @override
  Widget build(BuildContext context) {
    final unsorted = _entriesInFolder(null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // ── Lesson header ──────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: _expanded
                      ? Radius.zero
                      : const Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder_special_rounded,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  // Rename dialogue
                  GestureDetector(
                    onTap: widget.onRename,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.primary),
                    ),
                  ),
                  // Add folder
                  GestureDetector(
                    onTap: widget.onCreateFolder,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.create_new_folder_outlined,
                          size: 16, color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            // ── Sub-folders ────────────────────────────────────────────
            ...widget.folders.map((folder) {
              final folderEntries = _entriesInFolder(folder.id);
              return _FolderGroup(
                folder: folder,
                entries: folderEntries,
                onRename: () => widget.onRenameFolder(folder),
                onDelete: () => widget.onDeleteFolder(folder),
                onDeleteEntry: widget.onDeleteEntry,
                onToggleMastered: widget.onToggleMastered,
                onMoveEntry: widget.onMoveEntry,
              );
            }),

            // ── Unsorted words ─────────────────────────────────────────
            if (unsorted.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Text(
                  'Sans dossier (${unsorted.length})',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.muted),
                ),
              ),
              ...unsorted.map((e) => _WordTile(
                    entry: e,
                    onDelete: () => widget.onDeleteEntry(e),
                    onToggleMastered: () => widget.onToggleMastered(e),
                    onMove: () => widget.onMoveEntry(e),
                  )),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ── Folder group ───────────────────────────────────────────────────────────────

class _FolderGroup extends StatefulWidget {
  final VocabFolder folder;
  final List<NotebookEntry> entries;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final void Function(NotebookEntry) onDeleteEntry;
  final void Function(NotebookEntry) onToggleMastered;
  final void Function(NotebookEntry) onMoveEntry;

  const _FolderGroup({
    required this.folder,
    required this.entries,
    required this.onRename,
    required this.onDelete,
    required this.onDeleteEntry,
    required this.onToggleMastered,
    required this.onMoveEntry,
  });

  @override
  State<_FolderGroup> createState() => _FolderGroupState();
}

class _FolderGroupState extends State<_FolderGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: AppTheme.border),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.folder_open_rounded
                      : Icons.folder_rounded,
                  size: 16,
                  color: AppTheme.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.folder.name} (${widget.entries.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onRename,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 14, color: AppTheme.muted),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 14, color: AppTheme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.entries.map((e) => _WordTile(
                entry: e,
                onDelete: () => widget.onDeleteEntry(e),
                onToggleMastered: () => widget.onToggleMastered(e),
                onMove: () => widget.onMoveEntry(e),
                indent: true,
              )),
      ],
    );
  }
}

// ── Word tile ──────────────────────────────────────────────────────────────────

class _WordTile extends StatefulWidget {
  final NotebookEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onToggleMastered;
  final VoidCallback onMove;
  final bool indent;

  const _WordTile({
    required this.entry,
    required this.onDelete,
    required this.onToggleMastered,
    required this.onMove,
    this.indent = false,
  });

  @override
  State<_WordTile> createState() => _WordTileState();
}

class _WordTileState extends State<_WordTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final left = widget.indent ? 28.0 : 14.0;
    return Column(
      children: [
        const Divider(height: 1, color: AppTheme.border),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(left, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.word,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: e.isMastered
                              ? AppTheme.muted
                              : AppTheme.onSurface,
                          decoration: e.isMastered
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (e.translation.isNotEmpty)
                        Text(
                          e.translation,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.primary),
                        ),
                    ],
                  ),
                ),
                // Move
                GestureDetector(
                  onTap: widget.onMove,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.drive_file_move_rounded,
                        size: 16, color: AppTheme.muted),
                  ),
                ),
                const SizedBox(width: 4),
                // Delete
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppTheme.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && (e.definition.isNotEmpty || e.exampleSentence.isNotEmpty))
          Padding(
            padding: EdgeInsets.fromLTRB(left, 0, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.definition.isNotEmpty)
                  Text(e.definition,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.onSurface,
                          height: 1.4)),
                if (e.exampleSentence.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('💬 ${e.exampleSentence}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                          fontStyle: FontStyle.italic,
                          height: 1.4)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ── Move folder sheet ──────────────────────────────────────────────────────────

class _MoveFolderSheet extends StatelessWidget {
  final List<VocabFolder> folders;
  final String? currentFolderId;

  const _MoveFolderSheet(
      {required this.folders, required this.currentFolderId});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Déplacer vers...',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 12),
          if (currentFolderId != null)
            _option(context, Icons.bookmark_border_rounded, 'Sans dossier', ''),
          ...folders
              .where((f) => f.id != currentFolderId)
              .map((f) => _option(context, Icons.folder_rounded, f.name, f.id)),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext ctx, IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.muted),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
