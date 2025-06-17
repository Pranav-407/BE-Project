import 'dart:developer';

import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/teachers/classroom.dart';
import 'package:be_project_campus_connect/views/teachers/view_division.dart';
import 'package:be_project_campus_connect/views/teachers/view_tg_batches.dart';
// import 'package:be_project_campus_connect/views/teachers/view_my_batches.dart';
// import 'package:be_project_campus_connect/views/teachers/view_student_attendance.dart';
// import 'package:be_project_campus_connect/views/teachers/upload_assignment.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    getData();
    log("in init");
  }

  void getData() async {
    await SharedPreferenceData.getSharedPreferenceData();
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log(" In Build ${SharedPreferenceData.loginID}");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logout(context);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    Text(
                      'Welcome, Teacher',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your classes and students',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.green.shade600,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildGridItem(
                      context,
                      title: 'My Division',
                      icon: Icons.school,
                      color: Colors.orange.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ViewDivision(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'My TG Batches',
                      icon: Icons.group,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ViewTgBatches(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'My ClassRooms',
                      icon: Icons.assignment_ind,
                      color: Colors.teal.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const ClassroomScreen(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'My Practical Batches',
                      icon: Icons.upload_file,
                      color: Colors.purple.shade700,
                      onTap: () {
                        // Navigator.of(context).push(MaterialPageRoute(
                        //   builder: (context) => const UploadAssignment(),
                        // ));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
