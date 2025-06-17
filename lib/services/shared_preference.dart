import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceData {
  static String userName= "";
  static String loginID = "";
  static String role = "";
  static bool isLoggedIn = false;
  
  static Future<void> storeLoginData(
      {required bool isLoggedIn, required String loginID,required String role,required String userName}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    /// SET DATA
    sharedPreferences.setBool("isLoggedIn", isLoggedIn);
    sharedPreferences.setString("userName", userName);
    sharedPreferences.setString("loginID", loginID);
    sharedPreferences.setString("role", role);
    log("Login Data Stored Successfully to Shared Pref");

  }
  
  static Future<void> getSharedPreferenceData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    isLoggedIn = sharedPreferences.getBool("isLoggedIn") ?? false;
    userName = sharedPreferences.getString("userName") ?? "";
    loginID = sharedPreferences.getString("loginID") ?? "";
    role = sharedPreferences.getString("role") ?? "";
    log("IN Shared Pref");
    log("isLoggedIn :$isLoggedIn");
    log("loginID :$loginID");
    log("role :$role");
    log("userName :$userName");
  }

  static Future<void> clearLoginData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    // Reset the stored values
    await sharedPreferences.setBool("isLoggedIn", false);
    await sharedPreferences.setString("loginID", "");
    await sharedPreferences.setString("userName", "");
    await sharedPreferences.setString("role", "");
    
    // Also reset the static variables
    isLoggedIn = false;
    loginID = "";
    role = "";
    userName = "";
    
    log("Login Data Cleared Successfully from Shared Pref");
  }
}
