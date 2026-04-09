import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/notebook_entry.dart';
import '../../../models/user_profile.dart';
import '../../../services/gemini_service.dart';
import '../../../services/notebook_service.dart';
import '../../../services/tts_service.dart';
import '../../../services/audio_recorder_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatTab extends StatefulWidget {
  final Lesson lesson;
  final UserProfile profile;

  const ChatTab({super.key, required this.lesson, required this.profile});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _gemini = GeminiService();
  final _tts = TtsService();
  final _recorder = AudioRecorderService();
  final _notebook = NotebookService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<_Message> _messages = [];
  final Set<String> _savedWords = {}; // tracks words saved this session
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
    await _notebook.init();
    // Pre-load already-saved words for this lesson
    final saved = _notebook
        .loadAll()
        .where((e) => e.lessonId == widget.lesson.id)
        .map((e) => e.word.toLowerCase())
        .toSet();
    if (mounted) setState(() => _savedWords.addAll(saved));

    _gemini.startLessonChat(widget.lesson, widget.profile.level);
    setState(() => _isProcessing = true);
    try {
      final greeting = await _gemini.sendMessage(
        'Hello, I just finished listening to the lesson.',
      );
      _addMessage('assistant', greeting);
      await _tts.speak(_ttsText(greeting));
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
      await _tts.speak(_ttsText(response));
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

  Future<void> _saveWord(_VocabItem item) async {
    final already = _savedWords.contains(item.english.toLowerCase());
    if (already) return;
    final entry = NotebookEntry(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      word: item.english,
      definition: item.definition,
      exampleSentence: '',
      translation: item.french,
      lessonId: widget.lesson.id,
      lessonTitle: widget.lesson.title,
      savedAt: DateTime.now(),
    );
    await _notebook.save(entry);
    if (!mounted) return;
    setState(() => _savedWords.add(item.english.toLowerCase()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${item.english}" ajouté au Lexique'),
        backgroundColor: AppTheme.accent,
        duration: const Duration(seconds: 2),
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
        // Context banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.primaryLight,
          child: Row(
            children: [
              const Icon(Icons.school_rounded, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.lesson.title} · vocabulaire, grammaire, questions libres',
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
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isProcessing ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return const _TypingIndicator();
              final msg = _messages[i];
              if (msg.role == 'user') {
                return _Bubble(isUser: true, text: msg.text);
              }
              final parsed = _parseMessage(msg.text);
              return _AssistantMessage(
                parsed: parsed,
                savedWords: _savedWords,
                onSave: _saveWord,
              );
            },
          ),
        ),
        // Input bar
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
                  hintText: 'Question, liste de vocab, grammaire...',
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
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

/// Strips [VOCAB]...[/VOCAB] markers and pipes so TTS reads naturally.
String _ttsText(String text) => text
    .replaceAll('[VOCAB]', '')
    .replaceAll('[/VOCAB]', '')
    .replaceAll(' | ', ', ')
    .trim();

class _VocabItem {
  final String english;
  final String french;
  final String definition;
  _VocabItem({required this.english, required this.french, required this.definition});
}

class _ParsedMessage {
  final String preText;
  final List<_VocabItem>? items;
  final String postText;
  _ParsedMessage({required this.preText, this.items, required this.postText});
}

_ParsedMessage _parseMessage(String text) {
  final match = RegExp(r'\[VOCAB\](.*?)\[\/VOCAB\]', dotAll: true).firstMatch(text);
  if (match == null) return _ParsedMessage(preText: text, postText: '');

  final pre = text.substring(0, match.start).trim();
  final post = text.substring(match.end).trim();
  final items = <_VocabItem>[];

  for (final line in match.group(1)!.trim().split('\n')) {
    final m = RegExp(r'^\d+\.\s+(.+?)\s*\|\s*(.+?)(?:\s*\|\s*(.+))?$')
        .firstMatch(line.trim());
    if (m != null) {
      items.add(_VocabItem(
        english: m.group(1)!.trim(),
        french: m.group(2)!.trim(),
        definition: m.group(3)?.trim() ?? '',
      ));
    }
  }
  return _ParsedMessage(preText: pre, items: items.isEmpty ? null : items, postText: post);
}

class _Message {
  final String role;
  final String text;
  _Message({required this.role, required this.text});
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _AssistantMessage extends StatelessWidget {
  final _ParsedMessage parsed;
  final Set<String> savedWords;
  final Future<void> Function(_VocabItem) onSave;

  const _AssistantMessage({
    required this.parsed,
    required this.savedWords,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    if (parsed.items == null) {
      return _Bubble(isUser: false, text: parsed.preText);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parsed.preText.isNotEmpty) _Bubble(isUser: false, text: parsed.preText),
        _VocabListCard(
          items: parsed.items!,
          savedWords: savedWords,
          onSave: onSave,
        ),
        if (parsed.postText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _Bubble(isUser: false, text: parsed.postText),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _VocabListCard extends StatelessWidget {
  final List<_VocabItem> items;
  final Set<String> savedWords;
  final Future<void> Function(_VocabItem) onSave;

  const _VocabListCard({
    required this.items,
    required this.savedWords,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted_rounded,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  '${items.length} expressions · appuie sur 📌 pour mémoriser',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;
            final isSaved = savedWords.contains(item.english.toLowerCase());
            final isLast = idx == items.length - 1;
            return _VocabRow(
              number: idx + 1,
              item: item,
              isSaved: isSaved,
              isLast: isLast,
              onSave: () => onSave(item),
            );
          }),
        ],
      ),
    );
  }
}

class _VocabRow extends StatelessWidget {
  final int number;
  final _VocabItem item;
  final bool isSaved;
  final bool isLast;
  final VoidCallback onSave;

  const _VocabRow({
    required this.number,
    required this.item,
    required this.isSaved,
    required this.isLast,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number badge
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Word + translation + definition
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.english,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.french,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primary,
                      ),
                    ),
                    if (item.definition.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.definition,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Save button
              GestureDetector(
                onTap: isSaved ? null : onSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSaved
                        ? AppTheme.accent.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSaved ? AppTheme.accent : AppTheme.border,
                    ),
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    size: 18,
                    color: isSaved ? AppTheme.accent : AppTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.border, indent: 46),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isUser;
  final String text;
  const _Bubble({required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
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
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser ? Colors.white : AppTheme.onSurface,
          ),
        ),
      ),
    );
  }
}

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
