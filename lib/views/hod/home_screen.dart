import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:be_project_campus_connect/setup%20initial%20database/download_students_login.dart';
import 'package:be_project_campus_connect/views/hod/assign_ct_and_tg.dart';
import 'package:be_project_campus_connect/views/hod/display_divisions.dart';
import 'package:be_project_campus_connect/views/hod/pending_fees_students.dart';
import 'package:be_project_campus_connect/views/hod/upload_fees.dart';
import 'package:be_project_campus_connect/views/hod/view_tg_batches.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Dashboard'),
        backgroundColor: Colors.indigo,
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
            colors: [Colors.indigo.shade50, Colors.white],
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
                      'Welcome, HOD',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your department efficiently',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.indigo.shade600,
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
                      title: 'Display Division Wise Data',
                      icon: Icons.bar_chart,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DivisionWiseView(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'Upload Pending Fees Students List',
                      icon: Icons.upload_file,
                      color: Colors.green.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const UploadFeeExcel(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'Display Fees Data',
                      icon: Icons.payments,
                      color: Colors.orange.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const PendingFeesScreen(),
                        ));
                      },
                    ),
                    // _buildGridItem(
                    //   context,
                    //   title: '',
                    //   icon: Icons.group_add,
                    //   color: Colors.purple.shade700,
                    //   onTap: () {
                    //     Navigator.of(context).push(MaterialPageRoute(
                    //       builder: (context) => const UploadTgBatches(),
                    //     ));
                    //   },
                    // ),
                    _buildGridItem(
                      context,
                      title: 'View TG Batches',
                      icon: Icons.groups,
                      color: Colors.red.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const BatchWiseView(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'Assign CT And TG',
                      icon: Icons.person_add,
                      color: Colors.teal.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const TeacherAssignmentScreen(),
                        ));
                      },
                    ),
                    _buildGridItem(
                      context,
                      title: 'Download Login credentials',
                      icon: Icons.person,
                      color: Colors.blue.shade700,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DownloadCredentials(),
                        ));
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
}