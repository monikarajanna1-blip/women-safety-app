import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'package:lyra_new/screens/auth_screen.dart';

/// 🔑 Needed for showing SnackBars & navigation from FCM
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

/// =======================================================
/// 🔔 BACKGROUND FCM HANDLER (REQUIRED)
/// =======================================================
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
      try{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
      "📩 Background FCM: ${message.notification?.title}");
}catch(e)
{
  debugPrint("Background Fcm error: $e");
}
    }
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔹 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔹 Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler);

  /// 🔹 Initialize Foreground Task
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'voice_sos_channel',
      channelName: 'Voice SOS',
      channelDescription: 'Listening for emergency voice phrase',
      priority: NotificationPriority.LOW,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  /// 🔹 Firebase Cloud Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  /// Request permission (Android 13+ & iOS)
  NotificationSettings settings =
      await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
      "🔔 Notification permission: ${settings.authorizationStatus}");

  /// Get FCM Token
 /* String? token = await messaging.getToken();
  debugPrint("🔥 FCM TOKEN: $token");*/

  /// 🔹 Foreground message handling
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint(
        "📩 Foreground FCM: ${message.notification?.title}");

    if (message.notification != null &&
        navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!)
          .showSnackBar(
        SnackBar(
          content: Text(
            message.notification!.title ?? "New Alert",
          ),
        ),
      );
    }
  });

  /// 🔹 App opened from notification (terminated)
  FirebaseMessaging.instance
      .getInitialMessage()
      .then((RemoteMessage? message) {
    if (message != null) {
      debugPrint(
          "🚀 Opened app via FCM (terminated)");
    }
  });

  /// 🔹 App opened from notification (background)
  FirebaseMessaging.onMessageOpenedApp
      .listen((RemoteMessage message) {
    debugPrint(
        "🚀 Opened app via FCM (background)");
  });

  runApp(const SafetyApp());
}

/// =======================================================
/// 🚀 APP ROOT
/// =======================================================
class SafetyApp extends StatelessWidget {
  const SafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyra',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3ECFF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF8B5CF6),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        useMaterial3: false,
      ),
      home: const AuthScreen(),
    );
  }
}
