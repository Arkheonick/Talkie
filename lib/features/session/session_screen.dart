import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../models/theme_topic.dart';
import '../../models/session.dart';
import '../../services/gemini_service.dart';
import '../../services/tts_service.dart';
import '../../services/audio_recorder_service.dart';
import '../summary/summary_screen.dart';
import 'widgets/message_bubble.dart';
import 'widgets/vocab_chip.dart';

class SessionScreen extends StatefulWidget {
  final ThemeTopic topic;

  const SessionScreen({super.key, required this.topic});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final GeminiService _gemini = GeminiService();
  final TtsService _tts = TtsService();
  final AudioRecorderService _recorder = AudioRecorderService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late Session _session;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      topicId: widget.topic.id,
      topicTitle: widget.topic.title,
    );
    _initServices();
  }

  Future<void> _initServices() async {
    _gemini.init();
    _gemini.startSession(widget.topic.id, widget.topic.title);
    await _tts.init();
    setState(() => _isProcessing = true);
    try {
      final greeting = await _gemini.sendMessage('Hello, I am ready to start.');
      _addMessage('assistant', greeting);
      await _tts.speak(greeting);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() => _session.messages.add(ChatMessage(role: role, text: text)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendText(String text) async {
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing || _isTranscribing) return;

    if (_isRecording) {
      // Stop recording → transcribe via Gemini
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });

      final audioBytes = await _recorder.stopRecording();
      if (audioBytes != null && audioBytes.isNotEmpty) {
        final transcription = await _gemini.transcribeAudio(audioBytes);
        if (transcription.isNotEmpty) {
          _textController.text = transcription;
          // Auto-send the transcription
          await _sendText(transcription);
        }
      }

      if (mounted) setState(() => _isTranscribing = false);
      return;
    }

    // Start recording
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    await _tts.stop();
    await _recorder.startRecording();
    setState(() => _isRecording = true);
  }

  Future<void> _endSession() async {
    await _tts.stop();
    if (_isRecording) {
      await _recorder.stopRecording();
      setState(() => _isRecording = false);
    }

    setState(() => _isProcessing = true);
    final vocab = await _gemini.extractVocabulary(_session.messages);
    _gemini.endSession();

    setState(() {
      _session.vocabulary.addAll(vocab);
      _session.endedAt = DateTime.now();
      _isProcessing = false;
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SummaryScreen(session: _session)),
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _tts.dispose();
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.topic.emoji),
            const SizedBox(width: 8),
            Flexible(
              child: Text(widget.topic.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: (_isProcessing || _isTranscribing) ? null : _endSession,
            child: const Text('End',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_session.vocabulary.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _session.vocabulary.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) =>
                    VocabChip(entry: _session.vocabulary[i]),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _session.messages.length,
              itemBuilder: (context, index) {
                final msg = _session.messages[index];
                return MessageBubble(role: msg.role, text: msg.text);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final String statusText;
    if (_isRecording) {
      statusText = '🔴 Recording... tap to stop & send';
    } else if (_isTranscribing) {
      statusText = 'Transcribing with Gemini...';
    } else if (_isProcessing) {
      statusText = 'Alex is thinking...';
    } else {
      statusText = 'Tap mic to speak, or type below';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              statusText,
              style: TextStyle(
                color: _isRecording
                    ? const Color(0xFFEF4444)
                    : AppTheme.muted,
                fontSize: 12,
                fontWeight: _isRecording
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Row(
            children: [
              // Mic / record button
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
                        : (_isTranscribing || _isProcessing)
                            ? AppTheme.border
                            : AppTheme.primary,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              spreadRadius: 3,
                            )
                          ]
                        : [],
                  ),
                  child: (_isTranscribing)
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // Text input
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
                    enabled: !_isProcessing && !_isRecording && !_isTranscribing,
                    decoration: const InputDecoration(
                      hintText: 'Or type here...',
                      hintStyle:
                          TextStyle(color: AppTheme.muted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendText,
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: (_isProcessing || _isRecording || _isTranscribing)
                    ? null
                    : () => _sendText(_textController.text),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_isProcessing || _isRecording || _isTranscribing)
                        ? AppTheme.border
                        : AppTheme.accent,
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
