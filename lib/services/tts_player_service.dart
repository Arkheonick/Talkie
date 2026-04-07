import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/lesson.dart';

enum PlayerState { idle, playing, paused, completed }

class TtsPlayerService {
  final FlutterTts _tts = FlutterTts();

  PlayerState _state = PlayerState.idle;
  List<TranscriptLine> _lines = [];
  int _currentIndex = -1;
  bool _stopRequested = false;

  final _stateController = StreamController<PlayerState>.broadcast();
  final _lineController = StreamController<int>.broadcast();

  Stream<PlayerState> get stateStream => _stateController.stream;
  Stream<int> get lineStream => _lineController.stream;

  PlayerState get state => _state;
  int get currentIndex => _currentIndex;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> loadLesson(List<TranscriptLine> lines) async {
    await stop();
    _lines = lines;
    _currentIndex = -1;
  }

  Future<void> play() async {
    if (_lines.isEmpty) return;
    if (_state == PlayerState.paused) {
      await _resume();
      return;
    }
    _stopRequested = false;
    _setState(PlayerState.playing);

    final start = _currentIndex < 0 ? 0 : _currentIndex;
    for (var i = start; i < _lines.length; i++) {
      if (_stopRequested) break;
      _currentIndex = i;
      _lineController.add(i);
      await _tts.speak(_cleanForTts(_lines[i].text));
      if (_stopRequested) break;
    }

    if (!_stopRequested) {
      _currentIndex = -1;
      _setState(PlayerState.completed);
    }
  }

  Future<void> pause() async {
    if (_state != PlayerState.playing) return;
    _stopRequested = true;
    await _tts.stop();
    _setState(PlayerState.paused);
  }

  Future<void> _resume() async {
    _stopRequested = false;
    _setState(PlayerState.playing);
    for (var i = _currentIndex; i < _lines.length; i++) {
      if (_stopRequested) break;
      _currentIndex = i;
      _lineController.add(i);
      await _tts.speak(_cleanForTts(_lines[i].text));
      if (_stopRequested) break;
    }
    if (!_stopRequested) {
      _currentIndex = -1;
      _setState(PlayerState.completed);
    }
  }

  static String _cleanForTts(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll('`', '')
        .trim();
  }

  Future<void> stop() async {
    _stopRequested = true;
    await _tts.stop();
    _currentIndex = -1;
    _setState(PlayerState.idle);
  }

  Future<void> seekToLine(int index) async {
    final wasPlaying = _state == PlayerState.playing;
    await stop();
    _currentIndex = index;
    if (wasPlaying) {
      _stopRequested = false;
      await play();
    }
  }

  void _setState(PlayerState s) {
    _state = s;
    _stateController.add(s);
  }

  Future<void> dispose() async {
    await stop();
    await _stateController.close();
    await _lineController.close();
  }
}
