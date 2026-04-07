import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../models/user_profile.dart';
import '../../../services/gemini_service.dart';
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
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isProcessing ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length) return const _TypingIndicator();
              final msg = _messages[i];
              return _Bubble(role: msg.role, text: msg.text);
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
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String role;
  final String text;
  _Message({required this.role, required this.text});
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
                final scale = 0.6 + (offset * 0.4 * (1 - offset) * 4).clamp(0.0, 0.4);
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
