import 'package:be_project_campus_connect/common%20methods/common_methods.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:developer';

class UploadTeachers extends StatefulWidget {
  const UploadTeachers({super.key});

  @override
  State<UploadTeachers> createState() => _UploadTeachersState();
}

class _UploadTeachersState extends State<UploadTeachers> {
  bool _isLoading = false;
  String _status = '';
  int _processedCount = 0;
  int _totalCount = 0;

  String formatEmployeeId(String employeeId) {
    return employeeId.replaceAll('/', '-');
  }

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
            // Skip first row (header)
            _totalCount = rows.length - 1;
            
            for (var i = 1; i < rows.length; i++) {
              final row = rows[i];
              // Check if row has valid data (at least has an Employee ID and Name)
              if (row.length >= 2 && row[0]?.value != null && row[1]?.value != null) {
                try {
                  // Get values from Excel columns based on new structure
                  // Column A is now Employee ID, Column B is Name of Faculty
                  final employeeId = row[0]?.value.toString() ?? '';
                  final name = row[1]?.value.toString() ?? '';
                  
                  if (name.isNotEmpty && employeeId.isNotEmpty) {
                    // Format employee ID - replace / with -
                    final formattedId = formatEmployeeId(employeeId);
                    
                    // Generate random password
                    final password = generateRandomPassword();
                    
                    // Create teacher data
                    final teacherData = {
                      'name': name,
                      'employeeId': employeeId,
                      'password': password,
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    
                    // Create login data
                    final loginData = {
                      'role': 'teacher',
                      'loginID': employeeId,
                      'password': password,
                      'name': name,
                    };
                    
                    log('Processing teacher: $name with ID: $formattedId');
                    
                    // Upload to Firebase - Teachers collection
                    await FirebaseFirestore.instance
                        .collection('Dummy Teachers')
                        .doc(formattedId)
                        .set(teacherData);
                    // Upload to Firebase - Teachers collection
                    await FirebaseFirestore.instance
                        .collection('Teachers')
                        .doc(formattedId)
                        .set(teacherData);
                    
                    // Upload to Firebase - Users collection
                    await FirebaseFirestore.instance
                        .collection('Dummy Users')
                        .doc(formattedId)
                        .set(loginData);

                    // Upload to Firebase - Users collection
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(formattedId)
                        .set(loginData);
                    
                    _processedCount++;
                    setState(() => _status = 'Processing teacher $i of $_totalCount: $name');
                  }
                } catch (e) {
                  log('Error processing row $i: ${e.toString()}');
                  setState(() => _status = 'Error processing row $i: ${e.toString()}');
                }
              }
            }
          }
        }
        setState(() => _status = 'Upload completed successfully! Processed $_processedCount teachers.');
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
        title: const Text('Upload Teacher Data'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Upload Teacher Data from Excel',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Select an Excel file containing teacher information',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('$_processedCount of $_totalCount teachers processed'),
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