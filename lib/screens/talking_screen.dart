import 'dart:async';
import 'package:flutter/material.dart';

class TalkingScreen extends StatefulWidget {
  const TalkingScreen({super.key});

  @override
  State<TalkingScreen> createState() => _TalkingScreenState();
}

class _TalkingScreenState extends State<TalkingScreen> {
  int seconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: seconds);
    final formattedTime =
        "${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, color: Colors.white, size: 90),
          const SizedBox(height: 20),
          Text(formattedTime, style: const TextStyle(color: Colors.white, fontSize: 32)),
          const SizedBox(height: 50),
          FloatingActionButton(
            backgroundColor: Colors.red,
            child: const Icon(Icons.call_end, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
