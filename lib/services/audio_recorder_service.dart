import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _filePath =
        '${dir.path}/talkie_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _filePath!,
    );
  }

  Future<Uint8List?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    await file.delete().catchError((_) => file);
    return bytes;
  }

  bool get isRecording => _filePath != null;

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
