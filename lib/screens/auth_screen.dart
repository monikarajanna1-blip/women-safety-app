import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lyra_new/screens/guardian_auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widget/shared_widgets.dart';
import 'home_screen.dart';
import '../backend/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoading = true;
  bool showLogin = true;

  @override
  void initState() {
    super.initState();
    _listenAuthState();
    registerGuardianDeviceSilently();
  }

  // ================= AUTH STATE =================
  void _listenAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => isLoading = false);
      }
    });
  }

  void toggleView() {
    setState(() => showLogin = !showLogin);
  }

  Future<void> _setLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }

  // ================= SAVE USER TOKEN =================
  Future<void> saveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= GUARDIAN REGISTRATION =================
  Future<void> registerGuardianDevice() async {
    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) {
      _showSnack("Failed to get guardian token");
      return;
    }

    await FirebaseFirestore.instance.collection('guardians').add({
      'userId': 'YEsYooSNRFaePkZzes33TH', // protected user UID
      'name': 'Guardian',
      'fcmToken': token,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _showSnack("Guardian device registered");
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9BB4D6), Color(0xFFC7B7E2)],
              ),
            ),
          ),

          // LIGHT STREAK
          Positioned.fill(
            child: CustomPaint(painter: _LightStreakPainter()),
          ),

          // CARD
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassCard(
                    child: showLogin
                        ? LoginPage(
                            toggleView: toggleView,
                            setLogin: _setLogin,
                            saveFcmToken: saveFcmToken,
                          )
                        : SignupPage(
                            toggleView: toggleView,
                            setLogin: _setLogin,
                            saveFcmToken: saveFcmToken,
                          ),
                  ),

                  const SizedBox(height: 20),

                  OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GuardianAuthScreen(),
              ),
            );
          },
          child: const Text("Guardian Login"),
        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> registerGuardianDeviceSilently() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('guardians').add({
      'userId': 'YEsYooSNRFaePkZzes33TH', // protected user UID
      'fcmToken': token,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Guardian registration failed: $e');
  }
}

}

// ================= GLASS CARD =================
class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ================= LOGIN =================
class LoginPage extends StatefulWidget {
  final VoidCallback toggleView;
  final Future<void> Function() setLogin;
  final Future<void> Function() saveFcmToken;

  const LoginPage({
    super.key,
    required this.toggleView,
    required this.setLogin,
    required this.saveFcmToken,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthService();
    final result = await auth.login(_email.text.trim(), _pass.text.trim());

    if (result == null) {
      await widget.setLogin();
      await widget.saveFcmToken();
    } else {
      _show(result);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text("Login", style: TextStyle(fontSize: 24)),

          const SizedBox(height: 24),

          StyledInputField(
            hintText: "Email",
            icon: Icons.email,
            controller: _email,
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),

          const SizedBox(height: 16),

          StyledInputField(
            hintText: "Password",
            icon: Icons.lock,
            controller: _pass,
            obscureText: _obscure,
            validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (_email.text.isEmpty) {
                  _show("Enter email first");
                  return;
                }
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: _email.text.trim());
                _show("Password reset email sent");
              },
              child: const Text("Forgot password?"),
            ),
          ),

          const SizedBox(height: 20),

          GradientButton(
            text: "LOGIN",
            onPressed: _login,
            startColor: const Color(0xFF7B6CF6),
            endColor: const Color(0xFF9B8CFF),
          ),

          TextButton(
            onPressed: widget.toggleView,
            child: const Text("Create account"),
          ),
        ],
      ),
    );
  }

}

// ================= SIGNUP =================
class SignupPage extends StatefulWidget {
  final VoidCallback toggleView;
  final Future<void> Function() setLogin;
  final Future<void> Function() saveFcmToken;

  const SignupPage({
    super.key,
    required this.toggleView,
    required this.setLogin,
    required this.saveFcmToken,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthService();
    final result = await auth.signup(_email.text.trim(), _pass.text.trim());

    if (result == null) {
      await widget.setLogin();
      await widget.saveFcmToken();
    } else {
      _show(result);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text("Create Account", style: TextStyle(fontSize: 24)),

          const SizedBox(height: 24),

          StyledInputField(
            hintText: "Email",
            icon: Icons.email,
            controller: _email,
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),

          const SizedBox(height: 16),

          StyledInputField(
            hintText: "Password",
            icon: Icons.lock,
            controller: _pass,
            obscureText: _obscure,
            validator: (v) => v!.length < 6 ? "Min 6 chars" : null,
          ),

          const SizedBox(height: 16),

          StyledInputField(
            hintText: "Confirm Password",
            icon: Icons.lock,
            controller: _confirm,
            obscureText: _obscure,
            validator: (v) => v != _pass.text ? "Passwords mismatch" : null,
          ),

          const SizedBox(height: 24),

          GradientButton(
            text: "SIGN UP",
            onPressed: _signup,
            startColor: const Color(0xFF7B6CF6),
            endColor: const Color(0xFF9B8CFF),
          ),

          TextButton(
            onPressed: widget.toggleView,
            child: const Text("Already have account?"),
          ),
        ],
      ),
    );
  }
}

// ================= PAINTER =================
class _LightStreakPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.08), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(0, size.height * 0.7)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
