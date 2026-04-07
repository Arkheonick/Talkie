import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../models/lesson.dart';
import '../../../services/tts_player_service.dart';

class AudioTab extends StatefulWidget {
  final Lesson lesson;
  final TtsPlayerService ttsPlayer;

  const AudioTab({super.key, required this.lesson, required this.ttsPlayer});

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
      widget.ttsPlayer.play(); // fire-and-forget: state updates via stream
    }
  }

  void _stop() {
    widget.ttsPlayer.stop();
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
