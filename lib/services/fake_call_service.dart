import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/incoming_call_screen.dart';

class FakeCallService {
  static Future<void> triggerFakeCall(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final delay = prefs.getInt('fakeCallDelay') ?? 0;

    Future.delayed(Duration(seconds: delay), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const IncomingCallScreen(),
        ),
      );
    });
  }
}
