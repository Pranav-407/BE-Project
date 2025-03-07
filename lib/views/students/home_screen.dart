import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Homepage'),
        actions: [
          // Add logout button to the app bar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Students Home Page.'
        )
      ),
    );
  }
}

