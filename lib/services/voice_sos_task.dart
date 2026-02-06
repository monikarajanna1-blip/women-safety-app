import 'dart:isolate';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_sound/flutter_sound.dart';

class VoiceSosTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool sosTriggered = false;
  final List<double> dbHistory = [];
  

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    await _recorder.openRecorder();

    await _recorder.startRecorder(
      codec: Codec.pcm16,
    );

    _recorder.onProgress!.listen((event) {
      if (sosTriggered) return;

      final db = event.decibels;
      if (db == null) return;

      // Normalize dB roughly to 0–1
      final normalized = min(1.0, max(0.0, (db + 60) / 60));

      dbHistory.add(normalized);
      if (dbHistory.length > 5) dbHistory.removeAt(0);

      final avg =
          dbHistory.reduce((a, b) => a + b) / dbHistory.length;

      // 🔴 BACKGROUND DISTRESS TRIGGER
      if (avg > 0.7) {
        sosTriggered = true;
        _sendPort?.send({
          "trigger": true,
          "text": "Background audio distress detected",
          "confidence": avg,
        });
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
