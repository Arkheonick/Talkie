import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  /// Notifies which message index is currently being spoken (-1 = none).
  final ValueNotifier<int> playingIndex = ValueNotifier(-1);

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() => playingIndex.value = -1);
    _tts.setErrorHandler((_) => playingIndex.value = -1);
    _tts.setCancelHandler(() => playingIndex.value = -1);

    final voices = await _tts.getVoices as List?;
    if (voices != null) {
      final englishVoice = voices.firstWhere(
        (v) =>
            v is Map &&
            (v['locale'] as String?)?.startsWith('en') == true &&
            (v['name'] as String?)?.toLowerCase().contains('network') == true,
        orElse: () => null,
      );
      if (englishVoice != null && englishVoice is Map) {
        await _tts.setVoice({
          'name': englishVoice['name'] as String,
          'locale': englishVoice['locale'] as String,
        });
      }
    }
  }

  /// Speak a message and track it by index for play/pause UI.
  Future<void> speakAtIndex(String text, int index) async {
    await _tts.stop();
    playingIndex.value = index;
    await _tts.speak(clean(text));
  }

  /// Generic speak without index tracking (used internally).
  Future<void> speak(String text) async {
    playingIndex.value = -1;
    await _tts.stop();
    await _tts.speak(clean(text));
  }

  /// Pause/stop current playback (user-initiated).
  Future<void> pausePlayback() async {
    playingIndex.value = -1;
    await _tts.stop();
  }

  Future<void> stop() async {
    playingIndex.value = -1;
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
    playingIndex.dispose();
  }

  /// Strip markdown symbols that TTS would read aloud literally.
  static String clean(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
  }
}
