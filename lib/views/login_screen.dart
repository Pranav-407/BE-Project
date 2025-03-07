import 'package:be_project_campus_connect/common_widgets/custom_button.dart';
import 'package:be_project_campus_connect/common_widgets/custom_textfield.dart';
import 'package:be_project_campus_connect/constants/constants.dart';
import 'package:be_project_campus_connect/controllers/login_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  final LoginScreenController _controller = LoginScreenController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: SizedBox(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 85,
                  ),
                  Transform.scale(
                    scaleX: 0.7,
                    scaleY: 0.8,
                    child: Image.asset(logo),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    "Welcome Back!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[800],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 30),
                        Text(
                          "Login to your account to continue",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          placeholder: 'Enter Login ID',
                          controller: _controller.loginIDController,
                          prefixIcon: Icons.person_outline,
                          label: 'Login ID',
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          placeholder: 'Password',
                          controller: _controller.passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          label: 'Enter Password',
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.teal[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.teal[400]!,
                                Colors.teal[700]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CustomButton(text: "Login", onPressed: () => _controller.login(context)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 35,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}