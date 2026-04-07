import 'package:flutter_tts/flutter_tts.dart';

/// Stops all TTS playback on the device.
/// FlutterTts uses a single shared engine on Android — any instance can stop it.
class AppAudio {
  static final _tts = FlutterTts();
  static Future<void> stopAll() => _tts.stop();
}
