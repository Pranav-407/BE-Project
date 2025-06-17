import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  Map<String, dynamic>? _classroomData;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Future<void> _verifyAndJoinClassroom() async {
  //   final code = _codeController.text.trim().toUpperCase();

  //   if (code.isEmpty) {
  //     setState(() {
  //       _errorMessage = 'Please enter a classroom code';
  //     });
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //     _isSuccess = false;
  //     _classroomData = null;
  //   });

  //   try {
  //     // First, get student details
  //     final studentDoc = await FirebaseFirestore.instance
  //         .collection('Dummy Students')
  //         .doc(SharedPreferenceData.loginID)
  //         .get();

  //     if (!studentDoc.exists) {
  //       setState(() {
  //         _isLoading = false;
  //         _errorMessage = 'Student profile not found. Please contact support.';
  //       });
  //       return;
  //     }

  //     final studentData = studentDoc.data() ?? {};

  //     // Search for classroom with matching code
  //     final querySnapshot = await FirebaseFirestore.instance
  //         .collection('Dummy Classrooms')
  //         .where('classCode', isEqualTo: code)
  //         .limit(1)
  //         .get();

  //     if (querySnapshot.docs.isEmpty) {
  //       setState(() {
  //         _isLoading = false;
  //         _errorMessage = 'Invalid classroom code. Please check and try again.';
  //       });
  //       return;
  //     }

  //     final classroomDoc = querySnapshot.docs.first;
  //     final classroomId = classroomDoc.id;
  //     final classroomData = classroomDoc.data();

  //     // Check if student is already enrolled
  //     final studentEnrollmentQuery = await FirebaseFirestore.instance
  //         .collection('Dummy Classrooms')
  //         .doc(classroomId)
  //         .collection('Students')
  //         .doc(SharedPreferenceData.loginID)
  //         .get();

  //     if (studentEnrollmentQuery.exists) {
  //       setState(() {
  //         _isLoading = false;
  //         _errorMessage = 'You are already enrolled in this classroom.';
  //       });
  //       return;
  //     }

  //     // Use a batch to ensure all operations succeed or fail together
  //     final batch = FirebaseFirestore.instance.batch();

  //     // 1. Add student to classroom's Students subcollection
  //     final studentRef = FirebaseFirestore.instance
  //         .collection('Dummy Classrooms')
  //         .doc(classroomId)
  //         .collection('Students')
  //         .doc(SharedPreferenceData.loginID);

  //     batch.set(studentRef, {
  //       'studentId': SharedPreferenceData.loginID,
  //       'name': SharedPreferenceData.userName,
  //       'rollNo': studentData['rollNo'] ?? 'N/A',
  //       'email': studentData['email'] ?? 'N/A',
  //       'division': studentData['division'] ?? 'N/A',
  //       'addedAt': FieldValue.serverTimestamp(),
  //     });

  //     // Commit all operations
  //     await batch.commit();

  //     setState(() {
  //       _isLoading = false;
  //       _isSuccess = true;
  //       _classroomData = {
  //         'className': classroomData['className'] ?? '',
  //         'subject': classroomData['subject'] ?? '',
  //         'classroomId': classroomId,
  //       };
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //       _errorMessage = 'Error: $e';
  //     });
  //   }
  // }

  Future<void> _verifyAndJoinClassroom() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a classroom code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
      _classroomData = null;
    });

    try {
      // First, get student details
      final studentDoc = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .doc(SharedPreferenceData.loginID)
          .get();

      if (!studentDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Student profile not found. Please contact support.';
        });
        return;
      }

      final studentData = studentDoc.data() ?? {};

      // Search for classroom with matching code
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .where('classCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid classroom code. Please check and try again.';
        });
        return;
      }

      final classroomDoc = querySnapshot.docs.first;
      final classroomId = classroomDoc.id;
      final classroomData = classroomDoc.data();

      // Check if student is already enrolled
      final studentEnrollmentQuery = await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(classroomId)
          .collection('Students')
          .doc(SharedPreferenceData.loginID)
          .get();

      if (studentEnrollmentQuery.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'You are already enrolled in this classroom.';
        });
        return;
      }

      // Use a batch to ensure all operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();

      // 1. Add student to classroom's Students subcollection
      final studentRef = FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(classroomId)
          .collection('Students')
          .doc(SharedPreferenceData.loginID);

      batch.set(studentRef, {
        'studentId': SharedPreferenceData.loginID,
        'name': SharedPreferenceData.userName,
        'rollNo': studentData['rollNo'] ?? 'N/A',
        'email': studentData['email'] ?? 'N/A',
        'division': studentData['division'] ?? 'N/A',
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update student count in classroom document - THIS IS THE KEY PART
      final classroomRef = FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(classroomId);

      batch.update(classroomRef, {
        'studentCount': FieldValue.increment(1),
      });

      // 3. If you need to track classrooms in the student's document, use this
      // Only do this if you've confirmed the 'Students' collection exists
      // Otherwise comment this part out
      try {
        // Check if student document exists first
        final studentMainDoc = await FirebaseFirestore.instance
            .collection('Dummy Students')
            .doc(SharedPreferenceData.loginID)
            .get();

        if (studentMainDoc.exists) {
          final studentDocRef = FirebaseFirestore.instance
              .collection('Dummy Students')
              .doc(SharedPreferenceData.loginID);

          final classroomInfo = {
            'classroomId': classroomId,
            'className': classroomData['className'] ?? '',
            'subject': classroomData['subject'] ?? '',
            'teacherId': classroomData['owner'] ?? '',
            'enrolledAt': DateTime.now().toIso8601String(),
          };

          batch.update(studentDocRef, {
            'myClassrooms': FieldValue.arrayUnion([classroomInfo])
          });
        }
      } catch (e) {
        // Silently handle this error - we'll still add the student to the classroom
        // but won't update their document if it doesn't exist
        print('Note: Failed to update student document: $e');
      }

      // Commit all operations
      await batch.commit();

      setState(() {
        _isLoading = false;
        _isSuccess = true;
        _classroomData = {
          'className': classroomData['className'] ?? '',
          'subject': classroomData['subject'] ?? '',
          'classroomId': classroomId,
        };
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Join Classroom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 20),

                  // Join Classroom Icon
                  Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.deepPurple.shade400,
                  ).animate().scale(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),

                  SizedBox(height: 20),

                  // Title and Subtitle
                  Text(
                    'Join a Classroom',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Enter the 6-character classroom code provided by your teacher',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple.shade600,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Code Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'Classroom Code',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple.shade700,
                            ),
                          ),

                          SizedBox(height: 15),

                          TextFormField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Colors.deepPurple.shade800,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'XXXXXX',
                              hintStyle: TextStyle(
                                letterSpacing: 5,
                                color: Colors.grey.shade400,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // Info Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.shade100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'The code is case-insensitive and should be 6 characters long',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Join Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndJoinClassroom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login),
                              SizedBox(width: 10),
                              Text(
                                'Join Classroom',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                  ),

                  SizedBox(height: 20),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(
                          begin: 0.3,
                          end: 0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),

                  // Success Message
                  if (_isSuccess && _classroomData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.green.shade200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Successfully Joined!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'You have successfully joined:',
                            style: TextStyle(
                              color: Colors.green.shade600,
                            ),
                          ),
                          SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.class_,
                                      color: Colors.deepPurple.shade400,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _classroomData!['className'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.subject,
                                      color: Colors.deepPurple.shade400,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _classroomData!['subject'],
                                        style: TextStyle(
                                          color: Colors.deepPurple.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Return to Home'),
                          ),
                        ],
                      ),
                    ).animate().scale(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
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
