import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../app/theme.dart';
import '../../models/cefr_level.dart';
import '../../models/notebook_entry.dart';
import '../../models/user_profile.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/gemini_service.dart';
import '../../services/notebook_service.dart';
import '../../services/tts_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/vocab_folder_service.dart';
import '../../widgets/talkie_orb.dart';

// lessonId used for all words saved from the Discussion screen
const _kDiscussionLessonId = 'discussion';
const _kDiscussionLessonTitle = 'Discussion libre';

class ProfScreen extends StatefulWidget {
  const ProfScreen({super.key});

  @override
  State<ProfScreen> createState() => _ProfScreenState();
}

class _ProfScreenState extends State<ProfScreen> {
  final _gemini = GeminiService();
  final _tts = TtsService();
  final _recorder = AudioRecorderService();
  final _profileService = UserProfileService();
  final _notebookService = NotebookService();
  final _folderService = VocabFolderService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  UserProfile _profile = UserProfile.defaults();
  final List<_Msg> _messages = [];
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _initialized = false;
  DateTime? _recordingStartTime;
  String? _currentTopic;

  static const _topics = [
    'Ma journée',
    'Actualités',
    'Voyage',
    'Cuisine',
    'Culture',
    'Tech',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) _tts.pausePlayback();
    });
    _init();
  }

  Future<void> _init() async {
    await _profileService.init();
    await _notebookService.init();
    await _folderService.init();
    _profile = _profileService.load();
    _gemini.init();
    await _tts.init();
    await _startConversation(_profile.effectiveDiscussionLevel);
  }

  Future<void> _startConversation(CefrLevel level) async {
    _gemini.startFreeConversation(level);
    setState(() => _isProcessing = true);
    String greeting = '';
    try {
      greeting = await _gemini.sendMessage('Hello, I am ready to practise.');
      if (mounted) _addMsg('assistant', greeting);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _initialized = true;
        });
      }
    }
    if (greeting.isNotEmpty && mounted) {
      await _tts.speakAtIndex(_stripVocabForTts(greeting), 0);
    }
  }

  Future<void> _changeLevel(CefrLevel level) async {
    if (_messages.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Changer de niveau ?'),
          content: const Text(
              'La conversation actuelle sera effacée et relancée au nouveau niveau.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await _tts.stop();
    _profile.discussionLevel = level;
    await _profileService.save(_profile);
    setState(() {
      _messages.clear();
      _isProcessing = false;
      _initialized = false;
      _currentTopic = null;
    });
    await _startConversation(level);
  }

  Future<void> _newDiscussion() async {
    await _tts.stop();
    setState(() {
      _messages.clear();
      _isProcessing = false;
      _initialized = false;
      _currentTopic = null;
    });
    await _startConversation(_profile.effectiveDiscussionLevel);
  }

  void _showLevelPicker() {
    final current = _profile.effectiveDiscussionLevel;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SingleChildScrollView(
        child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Niveau de discussion',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Changer le niveau relancera la conversation.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            ...CefrLevel.values.map((lvl) {
              final isSelected = current == lvl;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  if (lvl != current) _changeLevel(lvl);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.primaryLight : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceHigh,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            lvl.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        lvl.labelFr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.onSurface,
                        ),
                      ),
                      if (isSelected) ...[
                        const Spacer(),
                        Icon(PhosphorIcons.check(),
                            color: AppTheme.primary, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      ),
    );
  }

  void _addMsg(String role, String text) {
    setState(() => _messages.add(_Msg(role, text)));
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
    _addMsg('user', text.trim());
    setState(() => _isProcessing = true);
    String? response;
    try {
      response = await _gemini.sendMessage(text.trim());
      if (mounted) _addMsg('assistant', response);
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
    if (!status.isGranted) return;
    await _tts.pausePlayback();
    await _recorder.startRecording();
    _recordingStartTime = DateTime.now();
    setState(() => _isRecording = true);
  }

  void _sendTopic(String topic) {
    setState(() => _currentTopic = topic);
    _send('Let\'s talk about: $topic');
  }

  Future<void> _saveWord({String word = '', String translation = ''}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SaveWordSheet(
        lessonId: _kDiscussionLessonId,
        lessonTitle: _kDiscussionLessonTitle,
        notebookService: _notebookService,
        folderService: _folderService,
        word: word,
        translation: translation,
      ),
    );
  }

  OrbState get _orbState {
    if (_isRecording) return OrbState.listening;
    if (_isTranscribing || _isProcessing) return OrbState.thinking;
    if (_tts.playingIndex.value != -1) return OrbState.speaking;
    return OrbState.idle;
  }

  String get _orbLabel {
    if (_isRecording) return 'EN ÉCOUTE';
    if (_isTranscribing) return 'ANALYSE...';
    if (_isProcessing) return 'RÉFLEXION...';
    if (_tts.playingIndex.value != -1) return 'PROF PARLE';
    return 'EN ATTENTE';
  }

  String get _orbSubLabel {
    if (_isRecording) return 'Relâche pour envoyer';
    if (_isProcessing || _isTranscribing) return '';
    if (_tts.playingIndex.value != -1) return 'Écoute ton professeur';
    return 'Appuie sur l\'orbe pour parler';
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
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(PhosphorIcons.graduationCap(), size: 18, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discussion libre', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                if (_currentTopic != null)
                  Text(_currentTopic!, style: const TextStyle(fontSize: 11, color: AppTheme.muted))
                else
                  const Text('Parle, corrige, enregistre', style: TextStyle(fontSize: 11, color: AppTheme.muted)),
              ],
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _newDiscussion,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(PhosphorIcons.arrowCounterClockwise(), color: AppTheme.primary, size: 18),
            ),
          ),
          GestureDetector(
            onTap: _showLevelPicker,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mon niveau', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_profile.effectiveDiscussionLevel.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      Icon(PhosphorIcons.caretDown(), size: 14, color: AppTheme.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _tts.playingIndex,
        builder: (context, _, __) => Column(
          children: [
            Expanded(flex: 5, child: _buildOrbZone()),
            Expanded(flex: 4, child: _buildTranscript()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrbZone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_messages.isEmpty && _initialized) ...[
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _sendTopic(_topics[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(_topics[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        TalkieOrb(
          state: _orbState,
          size: 130,
          onTap: (_isProcessing || _isTranscribing) ? null : _toggleRecording,
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _orbLabel,
            key: ValueKey(_orbLabel),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.08),
          ),
        ),
        const SizedBox(height: 4),
        Text(_orbSubLabel, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ],
    );
  }

  Widget _buildTranscript() {
    if (_messages.isEmpty && _isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return const _TypingIndicator();
        final m = _messages[i];
        return _Bubble(
          role: m.role,
          text: m.text,
          msgIndex: i,
          ttsService: m.role == 'assistant' ? _tts : null,
          ttsText: m.role == 'assistant' ? _stripVocabForTts(m.text) : '',
          onSaveWord: m.role == 'assistant' ? _saveWord : null,
        );
      },
    );
  }

  Widget _buildControls() {
    final disabled = _isProcessing || _isTranscribing;
    final String hint;
    if (_isRecording) {
      hint = 'Enregistrement...';
    } else if (_isTranscribing) {
      hint = 'Transcription...';
    } else if (_isProcessing) {
      hint = 'Alex réfléchit...';
    } else {
      hint = 'Ou tape en anglais...';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input row
          if (!_isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Listener(
                        onPointerDown: (_) => _tts.pausePlayback(),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          enabled: !disabled,
                          decoration: InputDecoration(
                            hintText: hint,
                            hintStyle: TextStyle(
                              color: _isTranscribing || _isProcessing ? AppTheme.primary : AppTheme.muted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14),
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
                      child: Icon(PhosphorIcons.paperPlaneRight(PhosphorIconsStyle.fill), color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          // Main action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ControlBtn(
                icon: PhosphorIcons.arrowCounterClockwise(),
                label: 'Nouveau',
                onTap: _newDiscussion,
              ),
              GestureDetector(
                onTap: (disabled) ? null : _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [const Color(0xFF7C3AED), const Color(0xFFA855F7)]
                          : disabled
                              ? [AppTheme.border, AppTheme.border]
                              : [const Color(0xFF4338CA), AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: _isRecording ? 0.45 : 0.25),
                        blurRadius: _isRecording ? 20 : 12,
                        spreadRadius: _isRecording ? 2 : 0,
                      ),
                    ],
                  ),
                  child: _isTranscribing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Icon(
                          _isRecording
                              ? PhosphorIcons.stop(PhosphorIconsStyle.fill)
                              : PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),
              _ControlBtn(
                icon: PhosphorIcons.bookmarkSimple(),
                label: 'Sauvegarder',
                onTap: () => _saveWord(word: _textController.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Control button widget ──────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: AppTheme.muted, size: 18),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Message model ──────────────────────────────────────────────────────────────

class _Msg {
  final String role;
  final String text;
  _Msg(this.role, this.text);
}

// ── Segment parsing (vocab blocks) ────────────────────────────────────────────

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
    final parts =
        rest.split(RegExp(r'\s*[|—–-]\s*')).map((p) => p.trim()).toList();
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
    this.msgIndex = -1,
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
        maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.75 : 0.72),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primary : AppTheme.surfaceHigh,
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
        child: bubbleContent,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
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
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 6, bottom: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying ? AppTheme.primary : AppTheme.primaryLight,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isPlaying
                        ? PhosphorIcons.pause(PhosphorIconsStyle.fill)
                        : PhosphorIcons.play(PhosphorIconsStyle.fill),
                    size: 16,
                    color: isPlaying ? Colors.white : AppTheme.primary,
                  ),
                ),
              );
            },
          ),
          bubbleContent,
        ],
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
            : selection
                .textInside(editableTextState.textEditingValue.text);
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ...editableTextState.contextMenuButtonItems,
            if (selected.trim().isNotEmpty)
              ContextMenuButtonItem(
                label: 'Sauvegarder',
                onPressed: () {
                  ContextMenuController.removeAny();
                  onSaveWord?.call(
                      word: selected.trim(), translation: '');
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
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Icon(PhosphorIcons.bookOpen(),
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
              const Divider(height: 1, color: AppTheme.border),
              for (int i = 0; i < entries.length; i++)
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

  const _VocabRow(
      {required this.entry, required this.isLast, this.onSave});

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
                  bottom: BorderSide(
                      color: AppTheme.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (onSave != null)
              GestureDetector(
                onTap: onSave,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Icon(PhosphorIcons.bookmarkSimple(),
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

class _SaveWordSheet extends StatelessWidget {
  final String lessonId;
  final String lessonTitle;
  final NotebookService notebookService;
  final VocabFolderService folderService;
  final String word;
  final String translation;

  const _SaveWordSheet({
    required this.lessonId,
    required this.lessonTitle,
    required this.notebookService,
    required this.folderService,
    required this.word,
    this.translation = '',
  });

  Future<void> _save(BuildContext context, String? folderId) async {
    final entry = NotebookEntry(
      id: '${lessonId}_disc_${word.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      word: word,
      definition: '',
      exampleSentence: '',
      translation: translation,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      savedAt: DateTime.now(),
      folderId: folderId,
    );
    await notebookService.save(entry);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _createFolderAndSave(BuildContext context) async {
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
    final folder = await folderService.createFolder(lessonId, name.trim());
    if (context.mounted) await _save(context, folder.id);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"$word"',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sauvegarder dans...',
            style: TextStyle(fontSize: 13, color: AppTheme.muted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _pickerBtn(
                  icon: PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
                  label: 'Sans dossier',
                  accent: false,
                  onTap: () => _save(context, null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _pickerBtn(
                  icon: PhosphorIcons.folderPlus(),
                  label: '+ Nouveau dossier',
                  accent: true,
                  onTap: () => _createFolderAndSave(context),
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
          color: accent ? AppTheme.primary : AppTheme.surfaceHigh,
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
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
                final offset =
                    ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                final scale = 0.6 +
                    (offset * 0.4 * (1 - offset) * 4).clamp(0.0, 0.4);
                return Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  width: 8 * scale,
                  height: 8 * scale,
                  decoration: BoxDecoration(
                    color: AppTheme.muted
                        .withValues(alpha: 0.5 + scale * 0.5),
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
