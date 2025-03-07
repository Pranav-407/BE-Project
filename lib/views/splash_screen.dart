import 'package:be_project_campus_connect/constants/constants.dart';
import 'package:be_project_campus_connect/controllers/splash_screen_controller.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SplashScreenController().navigate(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Transform.scale(
          scaleX: 0.75,
          scaleY: 0.9,
          child: Image.asset(logo),
        ),
      ),
    );
  }
}