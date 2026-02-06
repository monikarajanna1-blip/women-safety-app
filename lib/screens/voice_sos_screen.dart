import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:lyra_new/utils/sos_manager.dart';
import 'package:lyra_new/services/voice_ai_services.dart';

class VoiceSosScreen extends StatefulWidget {
  const VoiceSosScreen({super.key});

  @override
  State<VoiceSosScreen> createState() => _VoiceSosScreenState();
}

class _VoiceSosScreenState extends State<VoiceSosScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final VoiceAIService voiceAI = VoiceAIService();

  bool isListening = false;
  bool sosTriggered = false;

  String recognizedText = "Tap start and speak your secret phrase";
  String secretPhrase = "";

  @override
  void initState() {
    super.initState();
    _loadSecretPhrase();
    voiceAI.loadModels();
  }

  // ================= LOAD SECRET PHRASE =================
  Future<void> _loadSecretPhrase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      secretPhrase =
          (doc.data()?['emergencyPhrase'] ?? "").toString();
    }
  }

  // ================= START LISTENING =================
  Future<void> startListening() async {
    if (secretPhrase.isEmpty) {
      _showError("No secret phrase set in Profile");
      return;
    }

    if (!await Permission.microphone.request().isGranted) {
      _showError("Microphone permission denied");
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      _showError("Speech recognition not available");
      return;
    }

    sosTriggered = false;

    setState(() => isListening = true);

    _speech.listen(
      listenMode: stt.ListenMode.dictation,
      onResult: (result) async {
        if (sosTriggered) return;

        final text = result.recognizedWords.toLowerCase();
        debugPrint("VOICE HEARD: $text");

        setState(() {
          recognizedText = text;
        });

        // ================= NLP =================
        final nlpScore = voiceAI.runNLP(text);
        debugPrint("NLP SCORE: $nlpScore");

        final phraseMatched =
            text.contains(secretPhrase.toLowerCase());

        if (phraseMatched || nlpScore > 0.75) {
          sosTriggered = true;
          await _speech.stop();
          setState(() => isListening = false);
          _sendSosFromVoice(text);
        }
      },
    );
  }

  // ================= STOP LISTENING =================
  Future<void> stopListening() async {
    await _speech.stop();
    setState(() => isListening = false);
  }

  // ================= SEND SOS =================
  Future<void> _sendSosFromVoice(String detectedText) async {
    try {
      if (!await Permission.location.request().isGranted) {
        _showError("Location permission denied");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await SosManager.triggerSOS(
        source: "voice",
        detectedPhrase: detectedText,
        audioUrl: null,
      );

      if (!mounted) return;
      _showSuccessPopup(pos.latitude, pos.longitude);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice SOS (Foreground + NLP)"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_none,
              size: 80,
              color: isListening ? Colors.red : Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                recognizedText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: isListening ? stopListening : startListening,
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(
                isListening ? "Stop Listening" : "Start Voice SOS",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isListening ? Colors.red : Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= POPUPS =================
  void _showSuccessPopup(double lat, double lon) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🚨 Voice SOS Sent"),
        content: Text(
          "Distress detected.\n\n"
          "📍 Latitude: $lat\n"
          "📍 Longitude: $lon",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text("Error", style: TextStyle(color: Colors.red)),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
