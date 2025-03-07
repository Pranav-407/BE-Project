import 'dart:math';

import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/login_screen.dart';
import 'package:flutter/material.dart';

void logout(BuildContext context) async {
  await SharedPreferenceData.clearLoginData();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (context) => LoginScreen(),
    ),
    (route) => false,
  );
}

String generateRandomPassword({int length = 8}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }