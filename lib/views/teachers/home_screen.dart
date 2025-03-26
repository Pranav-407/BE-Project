import 'dart:developer';

import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/teachers/view_tg_batches.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    getData();
    log("in init");
  }

  void getData()async{
    await SharedPreferenceData.getSharedPreferenceData();
  }

  @override
  Widget build(BuildContext context) {
    log(" In Build ${SharedPreferenceData.loginID}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Homepage'),
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
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const ViewTgBatches(),
                ));
              },
              child: Text('Show my TG batches'),
            ),
          ],
        )
      ),
    );
  }
}

