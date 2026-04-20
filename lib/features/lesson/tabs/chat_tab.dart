import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/notebook_entry.dart';
import '../../../models/user_profile.dart';
import '../../../models/vocab_folder.dart';
import '../../../services/audio_recorder_service.dart';
import '../../../services/gemini_service.dart';
import '../../../services/notebook_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/vocab_folder_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatTab extends StatefulWidget {
  final Lesson lesson;
  final UserProfile profile;
  final NotebookService notebookService;
  final VocabFolderService folderService;

  const ChatTab({
    super.key,
    required this.lesson,
    required this.profile,
    required this.notebookService,
    required this.folderService,
  });

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _gemini = GeminiService();
  final _tts = TtsService();
  final _recorder = AudioRecorderService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<_Message> _messages = [];
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _tts.pausePlayback();
    });
    _init();
  }

  Future<void> _init() async {
    _gemini.init();
    await _tts.init();
    _gemini.startLessonChat(widget.lesson, widget.profile.level);
    setState(() => _isProcessing = true);
    try {
      final greeting = await _gemini.sendMessage(
        'Hello, I just finished listening to the lesson.',
      );
      _addMessage('assistant', greeting);
      final ttsText = _stripVocabForTts(greeting);
      if (ttsText.isNotEmpty && mounted) {
        await _tts.speakAtIndex(ttsText, 0);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() => _messages.add(_Message(role: role, text: text)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isProcessing) return;
    _textController.clear();
    _focusNode.unfocus();
    await _tts.stop();
    _addMessage('user', text.trim());
    setState(() => _isProcessing = true);
    String? response;
    try {
      response = await _gemini.sendMessage(text.trim());
      if (mounted) _addMessage('assistant', response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
    if (response != null && mounted) {
      final index = _messages.length - 1;
      final ttsText = _stripVocabForTts(response);
      if (ttsText.isNotEmpty) await _tts.speakAtIndex(ttsText, index);
    }
  }

  static bool _isEmptyTranscription(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty || t.split(' ').length < 2) return true;
    const hallucinations = [
      'english language',
      'language learning',
      'language recording',
      'thank you for watching',
      'please subscribe',
    ];
    return hallucinations.any((h) => t.contains(h));
  }

  static String _stripVocabForTts(String text) {
    return text
        .replaceAll(RegExp(r'\[VOCAB\].*?\[/VOCAB\]', dotAll: true), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing || _isTranscribing) return;
    if (_isRecording) {
      final duration = _recordingStartTime == null
          ? 0
          : DateTime.now().difference(_recordingStartTime!).inMilliseconds;
      setState(() {
        _isRecording = false;
        _isTranscribing = duration >= 1000;
      });
      if (duration >= 1500) {
        final bytes = await _recorder.stopRecording();
        if (bytes != null && bytes.isNotEmpty) {
          final text = await _gemini.transcribeAudio(bytes);
          if (!_isEmptyTranscription(text)) await _send(text);
        }
      } else {
        await _recorder.stopRecording();
      }
      if (mounted) setState(() => _isTranscribing = false);
      return;
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission microphone requise')),
        );
      }
      return;
    }
    await _tts.pausePlayback();
    await _recorder.startRecording();
    _recordingStartTime = DateTime.now();
    setState(() => _isRecording = true);
  }

  // ── Save word ──────────────────────────────────────────────────────────────

  Future<void> _saveWord({String word = '', String translation = ''}) async {
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
        initialWord: word,
        initialTranslation: translation,
      ),
    );
  }

  @override
  void dispose() {
    _gemini.endSession();
    _tts.dispose();
    _recorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isProcessing ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return const _TypingIndicator();
              final msg = _messages[i];
              return _Bubble(
                role: msg.role,
                text: msg.text,
                msgIndex: i,
                ttsService: msg.role == 'assistant' ? _tts : null,
                ttsText: msg.role == 'assistant'
                    ? _stripVocabForTts(msg.text)
                    : '',
                onSaveWord: msg.role == 'assistant' ? _saveWord : null,
              );
            },
          ),
        ),
        _buildInput(),
      ],
    );
  }

  Widget _buildInput() {
    final disabled = _isProcessing || _isTranscribing;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? const Color(0xFFEF4444)
                    : disabled
                        ? AppTheme.border
                        : AppTheme.primary,
              ),
              child: _isTranscribing
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Listener(
                onPointerDown: (_) => _tts.pausePlayback(),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: !disabled && !_isRecording,
                  decoration: const InputDecoration(
                    hintText: 'Pose une question...',
                    hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: disabled ? null : () => _send(_textController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: disabled ? AppTheme.border : AppTheme.accent,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message model ──────────────────────────────────────────────────────────────

class _Message {
  final String role;
  final String text;
  _Message({required this.role, required this.text});
}

// ── Message segment parsing ────────────────────────────────────────────────────

class _TextSeg {
  final String text;
  _TextSeg(this.text);
}

class _VocabSeg {
  final List<_VocabEntry> entries;
  _VocabSeg(this.entries);
}

class _VocabEntry {
  final int number;
  final String word;
  final String translation;
  _VocabEntry(this.number, this.word, this.translation);
}

List<Object> _parseSegments(String text) {
  final result = <Object>[];
  final regex = RegExp(r'\[VOCAB\](.*?)\[/VOCAB\]', dotAll: true);
  int last = 0;
  for (final m in regex.allMatches(text)) {
    if (m.start > last) {
      final t = text.substring(last, m.start).trim();
      if (t.isNotEmpty) result.add(_TextSeg(t));
    }
    final entries = _parseVocabEntries(m.group(1) ?? '');
    if (entries.isNotEmpty) result.add(_VocabSeg(entries));
    last = m.end;
  }
  if (last < text.length) {
    final t = text.substring(last).trim();
    if (t.isNotEmpty) result.add(_TextSeg(t));
  }
  return result.isEmpty ? [_TextSeg(text)] : result;
}

List<_VocabEntry> _parseVocabEntries(String block) {
  final entries = <_VocabEntry>[];
  final lineRe = RegExp(r'^(\d+)[.\)]\s+(.+)');
  for (final line in block.trim().split('\n')) {
    final m = lineRe.firstMatch(line.trim());
    if (m == null) continue;
    final num = int.tryParse(m.group(1)!) ?? (entries.length + 1);
    final rest = m.group(2) ?? '';
    // Support both pipe separator and dash separators
    final parts = rest.split(RegExp(r'\s*[|—–-]\s*')).map((p) => p.trim()).toList();
    if (parts.isEmpty || parts[0].isEmpty) continue;
    entries.add(_VocabEntry(
      num,
      parts[0],
      parts.length > 1 ? parts[1] : '',
    ));
  }
  return entries;
}

// ── Bubble ─────────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String role;
  final String text;
  final int msgIndex;
  final TtsService? ttsService;
  final String ttsText;
  final void Function({String word, String translation})? onSaveWord;

  const _Bubble({
    required this.role,
    required this.text,
    required this.msgIndex,
    this.ttsService,
    this.ttsText = '',
    this.onSaveWord,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    final segments = isUser ? <Object>[_TextSeg(text)] : _parseSegments(text);

    final bubbleContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser ? null : Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final seg in segments)
                  if (seg is _TextSeg)
                    _buildText(context, seg.text, isUser)
                  else if (seg is _VocabSeg)
                    _buildVocabList(context, seg.entries),
              ],
            ),
          ),
        ],
      ),
    );

    if (isUser || ttsService == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: bubbleContent,
        ),
      );
    }

    // Assistant bubble: play/pause button to the left
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: ttsService!.playingIndex,
              builder: (_, playing, __) {
                final isPlaying = playing == msgIndex;
                return GestureDetector(
                  onTap: () {
                    if (isPlaying) {
                      ttsService!.pausePlayback();
                    } else {
                      ttsService!.speakAtIndex(ttsText, msgIndex);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying
                          ? AppTheme.primary
                          : AppTheme.primaryLight,
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isPlaying ? Colors.white : AppTheme.primary,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            bubbleContent,
          ],
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context, String text, bool isUser) {
    if (isUser || onSaveWord == null) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: isUser ? Colors.white : AppTheme.onSurface,
        ),
      );
    }
    // Assistant text: selectable with "Sauvegarder" in context menu
    return SelectableText(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppTheme.onSurface,
      ),
      contextMenuBuilder: (ctx, editableTextState) {
        final selection = editableTextState.textEditingValue.selection;
        final selected = selection.isCollapsed
            ? ''
            : selection.textInside(editableTextState.textEditingValue.text);
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ...editableTextState.contextMenuButtonItems,
            if (selected.trim().isNotEmpty)
              ContextMenuButtonItem(
                label: 'Sauvegarder',
                onPressed: () {
                  ContextMenuController.removeAny();
                  onSaveWord?.call(word: selected.trim(), translation: '');
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildVocabList(BuildContext context, List<_VocabEntry> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 13, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    const Text(
                      'Vocabulaire',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (onSaveWord != null)
                      Text(
                        'Appui long pour sauvegarder',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFD0E4FF)),
              // Entries
              for (int i = 0; i < entries.length; i++) ...[
                _VocabRow(
                  entry: entries[i],
                  isLast: i == entries.length - 1,
                  onSave: onSaveWord == null
                      ? null
                      : () => onSaveWord!(
                            word: entries[i].word,
                            translation: entries[i].translation,
                          ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _VocabRow extends StatelessWidget {
  final _VocabEntry entry;
  final bool isLast;
  final VoidCallback? onSave;

  const _VocabRow({required this.entry, required this.isLast, this.onSave});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFD0E4FF), width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number
            SizedBox(
              width: 22,
              child: Text(
                '${entry.number}.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            // Word + translation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.word,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  if (entry.translation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.translation,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Save bookmark
            if (onSave != null)
              GestureDetector(
                onTap: onSave,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: const Icon(Icons.bookmark_add_outlined,
                      size: 18, color: AppTheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Save word bottom sheet ─────────────────────────────────────────────────────

class _SaveWordSheet extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final NotebookService notebookService;
  final VocabFolderService folderService;
  final String initialWord;
  final String initialTranslation;

  const _SaveWordSheet({
    required this.lessonId,
    required this.lessonTitle,
    required this.notebookService,
    required this.folderService,
    this.initialWord = '',
    this.initialTranslation = '',
  });

  @override
  State<_SaveWordSheet> createState() => _SaveWordSheetState();
}

class _SaveWordSheetState extends State<_SaveWordSheet> {
  late final TextEditingController _wordCtrl;
  late final TextEditingController _transCtrl;
  final _defCtrl = TextEditingController();
  String? _selectedFolderId;
  late List<VocabFolder> _folders;

  @override
  void initState() {
    super.initState();
    _wordCtrl = TextEditingController(text: widget.initialWord);
    _transCtrl = TextEditingController(text: widget.initialTranslation);
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
      id: '${widget.lessonId}_chat_${word.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
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
          _field(_wordCtrl, 'Mot ou expression *', autofocus: widget.initialWord.isEmpty),
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
                onPressed: _wordCtrl.text.trim().isNotEmpty ? _save : null,
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

// ── Typing indicator ───────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                final scale =
                    0.6 + (offset * 0.4 * (1 - offset) * 4).clamp(0.0, 0.4);
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: AppTheme.muted.withValues(alpha: 0.5 + scale * 0.5),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
