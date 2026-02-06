import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';


class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});
  void _playAudioDialog(BuildContext context, String url) {
  final player = AudioPlayer();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Audio Evidence"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tap play to listen to the recorded audio evidence."),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_fill,
                      color: Colors.green, size: 40),
                  onPressed: () => player.play(UrlSource(url)),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.stop_circle,
                      color: Colors.red, size: 40),
                  onPressed: () => player.stop(),
                ),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              player.stop();
              Navigator.pop(ctx);
            },
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS History"),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_alerts')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(
              child: Text(
                "No SOS alerts yet.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              final isAuto = data['auto'] == true;
              final audioUrl = data['audioUrl'];
              final timestamp = data['timestamp'];
              final latitude = data['latitude'];
              final longitude = data['longitude'];

              String formattedTime = "Unknown time";
              if (timestamp != null) {
                formattedTime = DateFormat('dd MMM yyyy, hh:mm a')
                    .format(timestamp.toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                          data['auto'] == true
                              ? "AI Auto SOS - $formattedTime"
                              : "Manual SOS - $formattedTime",
                        ),

                                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📍 Lat: $latitude, Lon: $longitude"),
                    const SizedBox(height: 5),

                    if (audioUrl != null)
                      Row(
                        children: const [
                          Icon(Icons.mic, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text("Audio Evidence Available",
                              style: TextStyle(color: Colors.green)),
                        ],
                      ),
                  ],
                ),

                  trailing: const Icon(Icons.chevron_right),
                 onTap: () {
                      if (audioUrl != null) {
                        _playAudioDialog(context, audioUrl);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No audio evidence available."),
                          ),
                        );
                      }
                    },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
