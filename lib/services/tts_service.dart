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
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _tts.stop();
  }
}
