import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:developer';

class UploadStudents extends StatefulWidget {
  const UploadStudents({super.key});
  @override
  State<UploadStudents> createState() => _UploadStudentsState();
}

class _UploadStudentsState extends State<UploadStudents> {
  bool _isLoading = false;
  String _status = '';
  int _processedCount = 0;
  int _totalCount = 0;

  Future<void> _pickAndProcessFile() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'Picking file...';
        _processedCount = 0;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() => _status = 'Processing file...');
        final bytes = File(result.files.single.path!).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);

        for (var table in excel.tables.keys) {
          final rows = excel.tables[table]?.rows;
          if (rows != null && rows.length > 1) {
            // Skip header row
            _totalCount = rows.length - 1;
            
            for (var i = 1; i < rows.length; i++) {
              final row = rows[i];
              // Check if row has valid UID
              if (row.length >= 3 && row[2]?.value != null) {
                try {
                  // Get values from Excel columns
                  final rollNo = row[0]?.value.toString() ?? 'Not Available';
                  final prnNo = row[1]?.value.toString() ?? 'Not Available';
                  final stesUidNo = row[2]?.value.toString() ?? 'Not Available';
                  final studentName = row[3]?.value.toString() ?? 'Not Available';
                  final permAddress = row[4]?.value.toString() ?? 'Not Available';
                  final studentMobile = row[5]?.value.toString() ?? 'Not Available';
                  final parentMobile = row[6]?.value.toString() ?? 'Not Available';
                  final emailAddress = row[7]?.value.toString() ?? 'Not Available';
                  final alternativeEmail = row[8]?.value.toString() ?? 'Not Available';
                  final parentEmail = row[9]?.value.toString() ?? 'Not Available';
                  final motherMobile = row[10]?.value.toString() ?? 'Not Available';
                  
                  // Format student UID - replace / with -
                  final formattedUID = stesUidNo.replaceAll('/', '-');
                  
                  // Create student data
                  final studentData = {
                    'rollNo': rollNo,
                    'prnNo': prnNo,
                    'stesUidNo': stesUidNo,
                    'name': studentName,
                    'permanentAddress': permAddress,
                    'studentMobile': studentMobile,
                    'parentMobile': parentMobile,
                    'email': emailAddress,
                    'alternativeEmail': alternativeEmail,
                    'parentEmail': parentEmail,
                    'motherMobile': motherMobile,
                    'createdAt': FieldValue.serverTimestamp(),
                  };
                  
                  // Create login data
                  final loginData = {
                    'loginID': stesUidNo,
                    'role': 'student',
                    'password': generateRandomPassword(),
                    'name': studentName,
                  };
                  
                  log('Processing student: $studentName with UID: $formattedUID');
                  
                  // Upload to Firebase - Users collection
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(formattedUID)
                      .set(loginData);
                  
                  // Upload to Firebase - Students collection
                  await FirebaseFirestore.instance
                      .collection('Students')
                      .doc(formattedUID)
                      .set(studentData);
                  
                  _processedCount++;
                  setState(() => _status = 'Processing student $i of $_totalCount: $studentName');
                } catch (e) {
                  log('Error processing row $i: ${e.toString()}');
                  setState(() => _status = 'Error processing row $i: ${e.toString()}');
                }
              }
            }
          }
        }
        setState(() => _status = 'Upload completed successfully! Processed $_processedCount students.');
      } else {
        setState(() => _status = 'No file selected.');
      }
    } catch (e) {
      setState(() => _status = 'Error: ${e.toString()}');
      log('Exception: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Student Data'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Upload Student Data from Excel',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select an Excel file containing student information',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('$_processedCount of $_totalCount students processed'),
              ] else
                ElevatedButton.icon(
                  onPressed: _pickAndProcessFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Select Excel File'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _status.contains('Error')
                      ? Colors.red
                      : _status.contains('completed')
                          ? Colors.green
                          : Colors.black,
                  fontWeight: _status.contains('completed')
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}