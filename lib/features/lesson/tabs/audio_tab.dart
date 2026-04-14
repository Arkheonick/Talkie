import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/notebook_entry.dart';
import '../../../models/vocab_folder.dart';
import '../../../services/notebook_service.dart';
import '../../../services/tts_player_service.dart';
import '../../../services/vocab_folder_service.dart';

class AudioTab extends StatefulWidget {
  final Lesson lesson;
  final TtsPlayerService ttsPlayer;
  final NotebookService notebookService;
  final VocabFolderService folderService;

  const AudioTab({
    super.key,
    required this.lesson,
    required this.ttsPlayer,
    required this.notebookService,
    required this.folderService,
  });

  @override
  State<AudioTab> createState() => _AudioTabState();
}

class _AudioTabState extends State<AudioTab> {
  int _currentLine = -1;
  PlayerState _playerState = PlayerState.idle;
  bool _showTranslations = false;

  final _scrollController = ScrollController();
  final _lineKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _lineKeys.addAll(
      List.generate(widget.lesson.transcript.length, (_) => GlobalKey()),
    );

    widget.ttsPlayer.lineStream.listen((i) {
      if (!mounted) return;
      setState(() => _currentLine = i);
      _scrollToLine(i);
    });

    widget.ttsPlayer.stateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playerState = s);
      if (s == PlayerState.completed) {
        setState(() => _currentLine = -1);
      }
    });
  }

  void _scrollToLine(int index) {
    if (index < 0 || index >= _lineKeys.length) return;
    final ctx = _lineKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.3,
    );
  }

  void _togglePlay() {
    if (_playerState == PlayerState.playing) {
      widget.ttsPlayer.pause();
    } else {
      widget.ttsPlayer.play();
    }
  }

  void _stop() {
    widget.ttsPlayer.stop();
  }

  Future<void> _saveWordFromLine(int lineIndex) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SaveWordSheet(
        lessonId: widget.lesson.id,
        lessonTitle: widget.lesson.title,
        notebookService: widget.notebookService,
        folderService: widget.folderService,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transcript = widget.lesson.transcript;

    return Column(
      children: [
        // Player controls
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              // Play / Pause
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Stop
              GestureDetector(
                onTap: _stop,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: AppTheme.muted, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _playerState == PlayerState.playing
                          ? 'Lecture en cours...'
                          : _playerState == PlayerState.paused
                              ? 'En pause'
                              : _playerState == PlayerState.completed
                                  ? 'Terminé'
                                  : 'Appuie sur ▶ pour écouter',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    Text(
                      '${transcript.length} répliques · ${widget.lesson.durationLabel}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              // Translation toggle
              GestureDetector(
                onTap: () => setState(() => _showTranslations = !_showTranslations),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showTranslations
                        ? AppTheme.primaryLight
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showTranslations ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    '🇫🇷 FR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _showTranslations ? AppTheme.primary : AppTheme.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transcript
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: transcript.length,
            itemBuilder: (context, i) {
              final line = transcript[i];
              final isCurrent = _currentLine == i;
              final isNative = line.speaker != 'guest' &&
                  line.speaker != 'candidate' &&
                  line.speaker != 'customer';

              return GestureDetector(
                key: _lineKeys[i],
                onTap: () => widget.ttsPlayer.seekToLine(i),
                onLongPress: () => _saveWordFromLine(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.primaryLight
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCurrent ? AppTheme.primary : AppTheme.border,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isNative
                                  ? AppTheme.primary.withValues(alpha: 0.1)
                                  : AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _speakerLabel(line.speaker),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isNative ? AppTheme.primary : AppTheme.accent,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            const _PulsingDot(),
                          ],
                          const Spacer(),
                          const Icon(Icons.bookmark_add_outlined,
                              size: 14, color: AppTheme.muted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        line.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppTheme.onSurface,
                          fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                      if (_showTranslations && line.translation != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          line.translation!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.muted,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _speakerLabel(String speaker) {
    switch (speaker) {
      case 'receptionist':
        return 'Réceptionniste';
      case 'interviewer':
        return 'Recruteur';
      case 'barista':
        return 'Barista';
      case 'curator':
        return 'Conservateur';
      case 'guest':
      case 'candidate':
      case 'customer':
        return 'Vous';
      default:
        return speaker[0].toUpperCase() + speaker.substring(1);
    }
  }
}

// ── Save word bottom sheet ─────────────────────────────────────────────────────

class _SaveWordSheet extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final NotebookService notebookService;
  final VocabFolderService folderService;

  const _SaveWordSheet({
    required this.lessonId,
    required this.lessonTitle,
    required this.notebookService,
    required this.folderService,
  });

  @override
  State<_SaveWordSheet> createState() => _SaveWordSheetState();
}

class _SaveWordSheetState extends State<_SaveWordSheet> {
  final _wordCtrl = TextEditingController();
  final _transCtrl = TextEditingController();
  final _defCtrl = TextEditingController();
  String? _selectedFolderId;
  late List<VocabFolder> _folders;

  @override
  void initState() {
    super.initState();
    _folders = widget.folderService.getFoldersForLesson(widget.lessonId);
  }

  Future<void> _createFolder() async {
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
    final folder =
        await widget.folderService.createFolder(widget.lessonId, name.trim());
    setState(() {
      _folders.add(folder);
      _selectedFolderId = folder.id;
    });
  }

  Future<void> _save() async {
    final word = _wordCtrl.text.trim();
    if (word.isEmpty) return;
    final entry = NotebookEntry(
      id: '${widget.lessonId}_audio_${word.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      word: word,
      definition: _defCtrl.text.trim(),
      exampleSentence: '',
      translation: _transCtrl.text.trim(),
      lessonId: widget.lessonId,
      lessonTitle: widget.lessonTitle,
      savedAt: DateTime.now(),
      folderId: _selectedFolderId,
    );
    await widget.notebookService.save(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _transCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sauvegarder un mot',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 16),
          _field(_wordCtrl, 'Mot ou expression *', autofocus: true),
          const SizedBox(height: 10),
          _field(_transCtrl, 'Traduction (FR)'),
          const SizedBox(height: 10),
          _field(_defCtrl, 'Définition (optionnel)', maxLines: 2),
          const SizedBox(height: 16),
          const Text('Dossier',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _folderChip(null, 'Sans dossier'),
              ..._folders.map((f) => _folderChip(f.id, f.name)),
              GestureDetector(
                onTap: _createFolder,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: AppTheme.primary),
                      SizedBox(width: 4),
                      Text('Nouveau dossier',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListenableBuilder(
            listenable: _wordCtrl,
            builder: (_, __) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _wordCtrl.text.isNotEmpty ? _save : null,
                child: const Text('Ajouter au Lexique'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool autofocus = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      autofocus: autofocus,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.muted, fontSize: 13),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _folderChip(String? folderId, String label) {
    final selected = _selectedFolderId == folderId;
    return GestureDetector(
      onTap: () => setState(() => _selectedFolderId = folderId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.muted,
          ),
        ),
      ),
    );
  }
}

// ── Pulsing dot for active line ────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
