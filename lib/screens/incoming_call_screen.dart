import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool isOngoing = false;
  int callSeconds = 0;
  Timer? timer;
  AudioPlayer audioPlayer = AudioPlayer();

  String callerName = "Dad";
  String callerNumber = "";
  String ringtone = "Default";

  @override
  void initState() {
    super.initState();
    _loadCallerData();
  }

  Future<void> _loadCallerData() async {
    final prefs = await SharedPreferences.getInstance();

    callerName = prefs.getString('fakeCallerName') ?? "Dad";
    callerNumber = prefs.getString('fakeCallerNumber') ?? "";
    ringtone = prefs.getString('fakeCallRingtone') ?? "Default";

    _startRingtone();
    _vibratePhone();
  }

  Future<void> _startRingtone() async {
    String file = "audio/ringtone_default.mp3";

    if (ringtone == "Police") file = "audio/ringtone_police.mp3";
    if (ringtone == "Soft") file = "audio/ringtone_soft.mp3";

    await audioPlayer.play(AssetSource(file), volume: 1.0);
    audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _vibratePhone() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], intensities: [50, 255]);
    }
  }

  void _stopRingtone() {
    audioPlayer.stop();
    Vibration.cancel();
  }

  void _acceptCall() {
    setState(() => isOngoing = true);
    _stopRingtone();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => callSeconds++);
    });
  }

  void _endCall() {
    _stopRingtone();
    timer?.cancel();
    Navigator.pop(context);
  }

  String _formatTime(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return "$m:$sec";
  }

  @override
  void dispose() {
    _stopRingtone();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B5CF6), // Lyra purple glow
      body: Stack(
        children: [
          // Soft Purple Background Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.9),
                  const Color(0xFFB794F4).withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Caller Photo Placeholder
              CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, size: 80, color: Colors.white),
              ),

              const SizedBox(height: 25),

              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isOngoing
                    ? "Call in progress • ${_formatTime(callSeconds)}"
                    : "Incoming Call...",
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),

              const SizedBox(height: 120),

              // Action Buttons
              isOngoing ? _ongoingUI() : _incomingUI(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _incomingUI() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline
        GestureDetector(
          onTap: _endCall,
          child: Column(
            children: const [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.red,
                child: Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
              SizedBox(height: 8),
              Text("Decline", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),

        // Accept
        GestureDetector(
          onTap: _acceptCall,
          child: Column(
            children: const [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.green,
                child: Icon(Icons.call, color: Colors.white, size: 30),
              ),
              SizedBox(height: 8),
              Text("Answer", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ongoingUI() {
    return Column(
      children: [
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _endCall,
          child: Column(
            children: const [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.red,
                child: Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
              SizedBox(height: 8),
              Text("End Call", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
