import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);

    // Prefer a higher-quality voice if available
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

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(_clean(text));
  }

  /// Strip markdown symbols that TTS would read aloud literally.
  static String _clean(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')      // *word* / **word**
        .replaceAll(RegExp(r'_+'), '')        // _word_ / __word__
        .replaceAll(RegExp(r'#+\s*'), '')     // # headers
        .replaceAll('`', '')                  // `code`
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1') // [text](url)
        .replaceAll(RegExp(r'\n{2,}'), '\n') // collapse blank lines
        .trim();
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts.stop();
  }
}
