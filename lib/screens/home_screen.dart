import 'package:flutter/material.dart';
import 'package:lyra_new/screens/sos_history.dart';
import 'dart:async';
import 'ai_screen.dart';
import 'guardian_screen.dart';
import 'voice_sos_screen.dart';
import 'tracking_screen.dart';
import 'profile_screen.dart';
import 'safety_settings_screen.dart';
import 'about_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Backend imports
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

// OSM MAP imports
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  LatLng? userLocation;
  bool loadingMap = true;
  String sosStatus = "";
  bool riskPopupShown = false;

  // ------------------ INIT ----------------------
  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  // ------------------ LOCATION ------------------
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => loadingMap = false);
        return;
      }

      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => loadingMap = false);
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        userLocation = LatLng(pos.latitude, pos.longitude);
        loadingMap = false;
      });
    } catch (e) {
      setState(() => loadingMap = false);
    }
  }

  // ------------------ SOS BACKEND ------------------
  Future<void> _sendSos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError("User not logged in.");
        return;
      }

      if (!await Permission.location.request().isGranted) {
        _showError("Location permission denied");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lat = position.latitude;
      double lon = position.longitude;

      await FirebaseFirestore.instance.collection('sos_alerts').add({
        'userId': user.uid,
        'latitude': lat,
        'longitude': lon,
        'status': "active",
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSuccessPopup(lat, lon);

    } catch (e) {
      _showError(e.toString());
    }
  }

  // ------------------- POPUPS --------------------
  void _showSuccessPopup(double lat, double lon) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "SOS Sent!",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Your SOS alert was sent.\n\n"
            "📍 Latitude: $lat\n"
            "📍 Longitude: $lon",
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"))
          ],
        );
      },
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  // ------------------- BUILD ----------------------
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF3ECFF),

      appBar: AppBar(
        title: const Text("Lyra"),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),

      drawer: _buildDrawer(),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              _glassWelcomeCard(width),

              const SizedBox(height: 20),

              _glassMapCard(width),

              const SizedBox(height: 120), // room for bottom bar
            ],
          ),
        ),
      ),

      // ⭐ FINAL PERFECT POSITION BOTTOM NAV ⭐
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _glassBottomNavigation(),
      ),
    );
  }

  // ----------------------------------------------------------
  // GLASS WELCOME CARD
  // ----------------------------------------------------------
  Widget _glassWelcomeCard(double width) {
    return Container(
      width: width * 1.5,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          SizedBox(height: 10),
          Text(
            "Welcome to Lyra",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            "Your safety companion.\nStay protected, stay empowered.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // GLASS MAP CARD
  // ----------------------------------------------------------
  Widget _glassMapCard(double width) {
    return Container(
      width: width * 10,
      height: 280,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: loadingMap
            ? const Center(child: CircularProgressIndicator())
            : userLocation == null
                ? const Center(
                    child: Text("Map unavailable",
                        style: TextStyle(color: Colors.white)))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: userLocation!,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_pin,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  // ----------------------------------------------------------
  // GLASS BOTTOM NAVIGATION BAR
  // ----------------------------------------------------------
  Widget _glassBottomNavigation() {
    return Container(
      height: 95,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.shield, "Guardian", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => GuardianScreen()));
          }),

          _navItem(Icons.mic, "Voice SOS", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VoiceSosScreen()));
          }),

          // CENTER SOS BUTTON
          GestureDetector(
            onTap: () {
              _sendSos();
            },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 28),
            ),
          ),

          _navItem(Icons.auto_awesome, "AI", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AIPredictionScreen()));
          }),

          _navItem(Icons.location_on, "Tracking", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TrackingScreen()));
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // DRAWER
  // ----------------------------------------------------------
  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurpleAccent),
            child: const Text(
              "Lyra Menu",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text("Safety Settings"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SafetySettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.red),
            title: const Text("SOS History"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SosHistoryScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("App Info"),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title:
                const Text("Logout", style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
