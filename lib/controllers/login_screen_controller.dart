// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:be_project_campus_connect/common_widgets/custom_snackbar.dart';
import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/teachers/home_screen.dart' as teacher;
import 'package:be_project_campus_connect/views/students/home_screen.dart' as student;
import 'package:be_project_campus_connect/views/hod/home_screen.dart' as hod;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreenController extends ChangeNotifier {
  // Controllers
  final TextEditingController loginIDController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  // Getters
  bool get isLoading => _isLoading;

  // Validation methods
  bool _validateFields(BuildContext context) {
    String loginID = loginIDController.text.trim();
    String password = passwordController.text.trim();

    if (loginID.isEmpty || password.isEmpty) {
      context.showCustomSnackBar("All fields are required", isError: true);
      return false;
    }

    return true;
  }

  Future<void> login(BuildContext context) async {
    if (!_validateFields(context)) return;

    try {
      String loginID = loginIDController.text.trim();
      String password = passwordController.text.trim();
      String formattedloginID = loginID.replaceAll('/', '-');

      log(formattedloginID);
      log(password);

      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("Users")
          .doc(formattedloginID)
          .get();

      String pass = documentSnapshot.get('password');
      String role = documentSnapshot.get('role');

      log(pass);

      if (password == pass) {
        await SharedPreferenceData.storeLoginData(
            role: role, isLoggedIn: true, loginID: formattedloginID);
        await SharedPreferenceData.getSharedPreferenceData();
        context.showCustomSnackBar("Login successful!", isError: false);
        if (role == 'teacher') {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => teacher.HomeScreen(),
          ));
        }
        if (role == 'student') {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => student.HomeScreen()));
        }
        if (role == 'hod') {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => hod.HomeScreen()));
        }
      } else {
        context.showCustomSnackBar("Login ID or Password is incorrect",
            isError: true);
      }
    } catch (e) {
      context.showCustomSnackBar(e.toString(), isError: true);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    loginIDController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
