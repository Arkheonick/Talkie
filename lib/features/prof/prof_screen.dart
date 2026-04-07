import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../models/user_profile.dart';
import '../../services/gemini_service.dart';
import '../../services/tts_service.dart';
import '../../services/audio_recorder_service.dart';
import '../../services/user_profile_service.dart';

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
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  UserProfile _profile = UserProfile.defaults();
  final List<_Msg> _messages = [];
  bool _isProcessing = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _initialized = false;

  // Free conversation topics
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
    _init();
  }

  Future<void> _init() async {
    await _profileService.init();
    _profile = _profileService.load();
    _gemini.init();
    await _tts.init();
    _gemini.startFreeConversation(_profile.level);
    setState(() => _isProcessing = true);
    try {
      final greeting = await _gemini.sendMessage('Hello, I am ready to practise.');
      _addMsg('assistant', greeting);
      await _tts.speak(greeting);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _initialized = true;
        });
      }
    }
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
    try {
      final response = await _gemini.sendMessage(text.trim());
      _addMsg('assistant', response);
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
    if (!status.isGranted) return;
    await _tts.stop();
    await _recorder.startRecording();
    setState(() => _isRecording = true);
  }

  void _sendTopic(String topic) {
    _send('Let\'s talk about: $topic');
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
              child: const Center(
                child: Text('🎓', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discussion — Alex',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  'Niveau ${_profile.level.code} · Conversation libre',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick topics
          if (_initialized && _messages.length < 3)
            Container(
              height: 44,
              color: Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _sendTopic(_topics[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _topics[i],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Messages
          Expanded(
            child: _messages.isEmpty && _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isProcessing ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length) {
                        return const _TypingBubble();
                      }
                      final m = _messages[i];
                      return _Bubble(role: m.role, text: m.text);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final disabled = _isProcessing || _isTranscribing;
    final String hint;
    if (_isRecording) {
      hint = '🔴 Enregistrement...';
    } else if (_isTranscribing) {
      hint = 'Transcription...';
    } else if (_isProcessing) {
      hint = 'Alex réfléchit...';
    } else {
      hint = 'Parle ou tape en anglais';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: _isRecording ? const Color(0xFFEF4444) : AppTheme.muted,
                fontWeight: _isRecording ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? const Color(0xFFEF4444)
                        : disabled
                            ? AppTheme.border
                            : AppTheme.primary,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 3,
                            )
                          ]
                        : [],
                  ),
                  child: _isTranscribing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 24,
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
                      hintText: 'Ou tape ici...',
                      hintStyle: TextStyle(color: AppTheme.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                  width: 48,
                  height: 48,
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
        ],
      ),
    );
  }
}

class _Msg {
  final String role;
  final String text;
  _Msg(this.role, this.text);
}

class _Bubble extends StatelessWidget {
  final String role;
  final String text;
  const _Bubble({required this.role, required this.text});

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

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              child: Text('...', style: TextStyle(color: AppTheme.muted, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
