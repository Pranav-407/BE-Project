import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:be_project_campus_connect/views/teachers/home_screen.dart' as teacher;
import 'package:be_project_campus_connect/views/students/home_screen.dart' as student;
import 'package:be_project_campus_connect/views/hod/home_screen.dart' as hod;

class SplashScreenController {
  void navigate(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () async {
      await SharedPreferenceData.getSharedPreferenceData();
      if (SharedPreferenceData.isLoggedIn) {
        if (SharedPreferenceData.role == 'teacher') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => teacher.HomeScreen(),
          ));
        }
        if (SharedPreferenceData.role == 'student') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => student.HomeScreen()));
        }
        if (SharedPreferenceData.role == 'hod') {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => hod.HomeScreen()));
        }
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ));
      }  
    });
  }
}