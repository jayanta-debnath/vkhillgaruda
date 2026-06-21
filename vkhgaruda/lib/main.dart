import 'dart:io' show exit;
import 'package:flutter/foundation.dart' hide Summary;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vkhgaruda/home/landing.dart';
import 'package:vkhgaruda/nitya_seva/nitya_seva.dart';
import 'firebase_options.dart';
import 'package:vkhpackages/vkhpackages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _configureRealtimeDatabasePersistence();
  } catch (e) {
    print("✗ Firebase initialization failed: $e");
    // Exit the app if Firebase initialization fails
    if (!kIsWeb) {
      exit(1);
    }
    return;
  }

  runApp(MyApp());
}

void _configureRealtimeDatabasePersistence() {
  if (kIsWeb) {
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      } catch (e) {
        debugPrint("Could not enable Firebase Database persistence: $e");
      }
      return;
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return;
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Widget home = const Landing(title: "Hare Krishna");
  final Widget test = NityaSeva(title: "testing");

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garuda',
      theme: themeGaruda,
      home: home,
    );
  }
}
