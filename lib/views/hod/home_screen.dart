import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Homepage'),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const DivisionWiseView(),
                // ));
              },
              child: Text('Show Division wise data'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const UploadFeeExcel(),
                // ));
              },
              child: Text('Upload Fees data'),
            ),

            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const PendingFeesScreen(),
                // ));
              },
              child: Text('Display Fees data'),
            ),

            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const UploadTgBatches(),
                // ));
              },
              child: Text('Upload TG Batches'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const BatchWiseView(),
                // ));
              },
              child: Text('View TG Batches'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (context) => const TeacherGuardianScreen(),
                // ));
              },
              child: Text('Assign TG '),
            ),
          ],
        ),
      ),
    );
  }
}
