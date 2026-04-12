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

  @override
  void initState() {
    super.initState();
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
      await _tts.speak(greeting);
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
    try {
      final response = await _gemini.sendMessage(text.trim());
      _addMessage('assistant', response);
      await _tts.speak(response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing || _isTranscribing) return;
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });
      final bytes = await _recorder.stopRecording();
      if (bytes != null && bytes.isNotEmpty) {
        final text = await _gemini.transcribeAudio(bytes);
        if (text.isNotEmpty) await _send(text);
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
    await _tts.stop();
    await _recorder.startRecording();
    setState(() => _isRecording = true);
  }

  // ── Save word from chat ────────────────────────────────────────────────────

  Future<void> _saveWordFromMessage(String messageText) async {
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.primaryLight,
          child: Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alex discute de : ${widget.lesson.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                onSaveWord: msg.role == 'assistant'
                    ? () => _saveWordFromMessage(msg.text)
                    : null,
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

// ── Bubble with optional save button ─────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String role;
  final String text;
  final VoidCallback? onSaveWord;

  const _Bubble({required this.role, required this.text, this.onSaveWord});

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ),
            // Save word button on AI messages
            if (!isUser && onSaveWord != null)
              GestureDetector(
                onTap: onSaveWord,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bookmark_add_outlined,
                          size: 14, color: AppTheme.muted),
                      SizedBox(width: 4),
                      Text(
                        'Sauvegarder un mot',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
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
    final folder = await widget.folderService
        .createFolder(widget.lessonId, name.trim());
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.primary, style: BorderStyle.solid),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _wordCtrl.text.isNotEmpty ? _save : null,
              child: const Text('Ajouter au Lexique'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool autofocus = false, int maxLines = 1}) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (_, __) => TextField(
        controller: ctrl,
        autofocus: autofocus,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
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
