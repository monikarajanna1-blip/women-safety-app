import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';

class GlobalAlert {
  static bool shown = false;

  /// ------------------------------------------------------------
  /// IN-APP POPUP (only works when app is open)
  /// ------------------------------------------------------------
  static void showHighRiskAlert() {
    if (shown) return;
    shown = true;

    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) return;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text("⚠️ High Danger"),
        content: const Text(
            "Lyra detected signs of danger.\nStay alert and move to a safer place."),
        actions: [
          TextButton(
            onPressed: () {
              shown = false;
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  /// ------------------------------------------------------------
  /// BACKGROUND GUARDIAN WARNING (works even if app is closed)
  /// ------------------------------------------------------------
  static Future<void> sendGuardianWarning() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection("guardian_alerts").add({
        "userId": user.uid,
        "type": "warning",
        "message": "Lyra detected moderate danger.",
        "timestamp": DateTime.now(),
      });

      print("⚠️ Guardian warning stored in Firestore");
    } catch (e) {
      print("Guardian warning error: $e");
    }
  }
}

