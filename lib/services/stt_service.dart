import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> init() async {
    _isInitialized = await _speech.initialize(
      onError: (error) => null,
      debugLogging: false,
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_isInitialized) await init();
    if (!_isInitialized) return;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  void dispose() {
    _speech.cancel();
  }
}
