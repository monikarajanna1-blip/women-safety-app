import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetySettingsScreen extends StatefulWidget {
  const SafetySettingsScreen({super.key});

  @override
  State<SafetySettingsScreen> createState() => _SafetySettingsScreenState();
}

class _SafetySettingsScreenState extends State<SafetySettingsScreen> {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Settings State
  bool aiAlerts = true;
  bool vibration = true;
  double sensitivity = 0.5;

  String autoSosTime = "Off";
  String fakeCallDelay = "Instant";

  // ---------------- LOAD SETTINGS ----------------
  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('safety')
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    if (!mounted) return;

    setState(() {
      aiAlerts = data['aiAlerts'] ?? true;
      vibration = data['vibration'] ?? true;
      sensitivity = (data['sensitivity'] ?? 0.5).toDouble();
      autoSosTime = data['autoSosTime'] ?? "Off";
      fakeCallDelay = data['fakeCallDelay'] ?? "Instant";
    });
  }

  // ---------------- SAVE SETTINGS ----------------
  Future<void> _saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('safety')
        .set(
      {
        'aiAlerts': aiAlerts,
        'vibration': vibration,
        'sensitivity': sensitivity,
        'autoSosTime': autoSosTime,
        'fakeCallDelay': fakeCallDelay,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved successfully")),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3ECFF),
      appBar: AppBar(
        title: const Text("Safety Settings"),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Alerts & Security"),

            _toggleTile(
              title: "AI Risk Alerts",
              value: aiAlerts,
              onChanged: (v) => setState(() => aiAlerts = v),
            ),

            _dropdownTile(
              label: "Auto SOS Timer",
              value: autoSosTime,
              items: const ["Off", "5 sec", "10 sec", "20 sec"],
              onChanged: (v) => setState(() => autoSosTime = v!),
            ),

            const SizedBox(height: 25),
            _sectionTitle("Voice Trigger Settings"),

            const Text(
              "Voice Sensitivity (Emergency keyword)",
              style: TextStyle(fontSize: 14),
            ),

            Slider(
              min: 0.1,
              max: 1.0,
              divisions: 9,
              value: sensitivity,
              activeColor: const Color(0xFF8B5CF6),
              onChanged: (v) => setState(() => sensitivity = v),
            ),

            const SizedBox(height: 20),

            _toggleTile(
              title: "Vibration Feedback",
              value: vibration,
              onChanged: (v) => setState(() => vibration = v),
            ),

            const SizedBox(height: 25),
            _sectionTitle("Fake Call"),

            _dropdownTile(
              label: "Fake Call Delay",
              value: fakeCallDelay,
              items: const ["Instant", "5 sec", "15 sec", "30 sec"],
              onChanged: (v) => setState(() => fakeCallDelay = v!),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- REUSABLE WIDGETS ----------------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            activeColor: const Color(0xFF8B5CF6),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

