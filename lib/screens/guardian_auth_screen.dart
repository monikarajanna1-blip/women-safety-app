import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class GuardianAuthScreen extends StatefulWidget {
  const GuardianAuthScreen({super.key});

  @override
  State<GuardianAuthScreen> createState() => _GuardianAuthScreenState();
}

class _GuardianAuthScreenState extends State<GuardianAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> _handleGuardianAuth() async {
    setState(() => isLoading = true);

    try {
      final email = _email.text.trim().toLowerCase();
      final password = _password.text.trim();

      // 1️⃣ Check guardian invite
      final inviteSnap = await FirebaseFirestore.instance
          .collection('guardian_invites')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (inviteSnap.docs.isEmpty) {
        throw Exception("You are not invited as a guardian");
      }

      final inviteDoc = inviteSnap.docs.first;
      final linkedUserId = inviteDoc['userId'];

      UserCredential cred;

      // 2️⃣ Login or Signup
      if (isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final guardianUid = cred.user!.uid;

      // 3️⃣ Get FCM token
      final fcmToken = await FirebaseMessaging.instance.getToken();

      // 4️⃣ Save guardian profile
      await FirebaseFirestore.instance
          .collection('guardians')
          .doc(guardianUid)
          .set({
        'uid': guardianUid,
        'email': email,
        'linkedUserId': linkedUserId,
        'role': 'guardian',
        'fcmToken': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 5️⃣ Mark invite accepted
      await inviteDoc.reference.update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? "Guardian Login" : "Guardian Signup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: isLoading ? null : _handleGuardianAuth,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text(isLogin ? "Login as Guardian" : "Create Guardian Account"),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                setState(() => isLogin = !isLogin);
              },
              child: Text(
                isLogin
                    ? "Create Guardian Account"
                    : "Already have an account? Login",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
