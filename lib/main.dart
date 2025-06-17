import 'package:be_project_campus_connect/setup%20initial%20database/download_students_login.dart';
import 'package:be_project_campus_connect/views/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDkMVUo_Mt_cbX4CvVvjYBEGNRGvrPtYLU",
      appId: "1:604640031007:android:e881df4c66151308e3402a",
      messagingSenderId: "604640031007",
      projectId: "super-xdemo",
      storageBucket: "super-xdemo.appspot.com",
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen()
    );
  }
}
