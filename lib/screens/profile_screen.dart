import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyPhraseController = TextEditingController();

  bool allowEmergencyPhrase = false;
  bool isProfileSaved = false;

  bool isNameEditable = true;
  bool isPhoneEditable = true;
  bool isPhraseEditable = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // ================= LOAD PROFILE =================
  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        allowEmergencyPhrase = data['emergencyPhraseEnabled'] ?? false;
        emergencyPhraseController.text = data['emergencyPhrase'] ?? '';

        isProfileSaved = true;
        isNameEditable = false;
        isPhoneEditable = false;
        isPhraseEditable = false;
      });
    }
  }

  // ================= SAVE PROFILE =================
  Future<void> saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().length != 10) {
      _snack("Enter name and valid 10-digit phone");
      return;
    }

    if (allowEmergencyPhrase &&
        emergencyPhraseController.text.trim().length < 3) {
      _snack("Secret phrase too short");
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': nameController.text.trim(),
      'phone': phoneController.text.trim(),
      'emergencyPhraseEnabled': allowEmergencyPhrase,
      'emergencyPhrase':
          allowEmergencyPhrase ? emergencyPhraseController.text.trim() : '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      isProfileSaved = true;
      isNameEditable = false;
      isPhoneEditable = false;
      isPhraseEditable = false;
    });

    FocusScope.of(context).unfocus();
    _snack("Profile saved");
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3ECFF),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF8B5CF6),
                child: Icon(Icons.person, color: Colors.white, size: 45),
              ),

              const SizedBox(height: 25),

              // 🔹 Name
              glassField(
                controller: nameController,
                label: "Full Name",
                editable: isNameEditable,
                showEditIcon: isProfileSaved,
                onEdit: () {
                  setState(() => isNameEditable = true);
                },
              ),

              const SizedBox(height: 15),

              // 🔹 Phone
              glassField(
                controller: phoneController,
                label: "Phone Number",
                editable: isPhoneEditable,
                keyboard: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                showEditIcon: isProfileSaved,
                onEdit: () {
                  setState(() => isPhoneEditable = true);
                },
              ),

              const SizedBox(height: 20),

              // 🔹 Toggle (ALWAYS editable)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Enable Secret Safety Phrase"),
                  Switch(
                    value: allowEmergencyPhrase,
                    activeColor: const Color(0xFF8B5CF6),
                    onChanged: (value) {
                      setState(() => allowEmergencyPhrase = value);
                    },
                  ),
                ],
              ),

              if (allowEmergencyPhrase) const SizedBox(height: 10),

              // 🔹 Secret Phrase WITH EDIT ICON
              if (allowEmergencyPhrase)
                glassField(
                  controller: emergencyPhraseController,
                  label: "Secret Phrase",
                  editable: isPhraseEditable,
                  showEditIcon: isProfileSaved,
                  onEdit: () {
                    setState(() => isPhraseEditable = true);
                  },
                ),

              const SizedBox(height: 30),

              // 🔹 Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: saveProfile,
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= GLASS FIELD =================
  Widget glassField({
    required TextEditingController controller,
    required String label,
    required bool editable,
    required bool showEditIcon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    required VoidCallback onEdit,
  }) {
    return GlassBox(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !editable,
              keyboardType: keyboard,
              inputFormatters: inputFormatters,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
          if (showEditIcon)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF8B5CF6)),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ================= GLASS BOX =================
class GlassBox extends StatelessWidget {
  final Widget child;

  const GlassBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}

