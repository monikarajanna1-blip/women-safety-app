import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioRecordService {
  static final AudioRecorder _recorder = AudioRecorder();

  /// Start recording
  static Future<String?> startRecording() async {
    // Check permission
    bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return null;

    // Path to store audio
    Directory tempDir = await getTemporaryDirectory();
    String path =
        "${tempDir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.m4a";

    // Start Recording
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
      ),
      path: path,
    );

    return path;
  }

  /// Stop and upload to Firebase
  static Future<String?> stopAndUpload(String filePath) async {
    try {
      await _recorder.stop();

      File file = File(filePath);
      if (!file.existsSync()) return null;

      // Upload to Firebase
      final ref = FirebaseStorage.instance
          .ref()
          .child("sos_evidence")
          .child("audio_${DateTime.now().millisecondsSinceEpoch}.m4a");

      await ref.putFile(file);

      return await ref.getDownloadURL();
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
  }
}
