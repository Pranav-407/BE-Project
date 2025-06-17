import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStudentsScreen extends StatefulWidget {
  final String classroomId;

  const AddStudentsScreen({
    super.key,
    required this.classroomId,
  });

  @override
  State<AddStudentsScreen> createState() => _AddStudentsScreenState();
}

class _AddStudentsScreenState extends State<AddStudentsScreen> {
  
  bool isLoading = false;
  Map<String, List<Map<String, dynamic>>> studentsByDivision = {};
  Set<String> selectedStudents = {};
  List<String> divisions = ['SE1', 'SE2', 'SE3', 'SE4', 'SE5'];

  @override
  void initState() {
    super.initState();
    _fetchAllStudents();
  }

  Future<void> _fetchAllStudents() async {
    setState(() {
      isLoading = true;
      studentsByDivision.clear();
    });

    try {
      // Get existing students to avoid duplicates
      final existingStudents = await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Students')
          .get();

      final existingStudentIds = existingStudents.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toSet();

      // Initialize divisions map
      for (final division in divisions) {
        studentsByDivision[division] = [];
      }

      // Fetch all students
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .get();

      for (final doc in querySnapshot.docs) {
        if (!existingStudentIds.contains(doc.id)) {
          final data = doc.data();
          final division = data['division'] as String?;
          
          if (division != null && divisions.contains(division)) {
            studentsByDivision[division]?.add({
              'studentUID': doc.id,
              'name': data['name'] ?? 'N/A',
              'rollNo': data['rollNo'] ?? 'N/A',
              'email': data['email'] ?? '',
              'division': division,
            });
          }
        }
      }

      // Sort students by roll number within each division
      for (final division in studentsByDivision.keys) {
        studentsByDivision[division]?.sort((a, b) =>
            (a['rollNo'] ?? '').compareTo(b['rollNo'] ?? ''));
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching students: $e')),
        );
      }
    }
  }

  Future<void> _addSelectedStudents() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final classroomRef = FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId);

      final classroomDoc = await classroomRef.get();
      if (!classroomDoc.exists) {
        throw Exception('Classroom not found');
      }
      final classroomData = classroomDoc.data();

      // Prepare classroom info to add to student's myClassrooms array
      final classroomInfo = {
        'classroomId': widget.classroomId,
        'className': classroomData?['className'] ?? '',
        'subject': classroomData?['subject'] ?? '',
        'teacherId': SharedPreferenceData.loginID,
        'enrolledAt': DateTime.now().toIso8601String(),
      };

      for (final division in studentsByDivision.keys) {
        final students = studentsByDivision[division] ?? [];
        for (final student in students) {
          final studentId = student['studentUID'] as String;
          if (selectedStudents.contains(studentId)) {
            // Add student to classroom
            final studentRef = classroomRef
                .collection('Students')
                .doc(studentId);
                
            batch.set(studentRef, {
              'studentId': studentId,
              'name': student['name'],
              'rollNo': student['rollNo'],
              'email': student['email'],
              'division': student['division'],
              'addedAt': FieldValue.serverTimestamp(),
            });

            // Add classroom to student's myClassrooms array
            final studentDocRef = FirebaseFirestore.instance
                .collection('Students')
                .doc(studentId);

            batch.update(studentDocRef, {
              'myClassrooms': FieldValue.arrayUnion([classroomInfo])
            });
          }
        }
      }

      batch.update(classroomRef, {
        'studentCount': FieldValue.increment(selectedStudents.length),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Students added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error adding students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding students: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Students'),
      ),
      body: Column(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (studentsByDivision.isEmpty)
            const Center(child: Text('No students found'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: divisions.length,
                itemBuilder: (context, index) {
                  final division = divisions[index];
                  final students = studentsByDivision[division] ?? [];
                  
                  if (students.isEmpty) return const SizedBox.shrink();
                  
                  return ExpansionTile(
                    title: Text('Division $division'),
                    subtitle: Text('${students.length} students'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Text(
                              '${students.length} students found',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  final divisionStudentIds = students
                                      .map((s) => s['studentUID'] as String)
                                      .toSet();
                                  
                                  if (divisionStudentIds.every(
                                      (id) => selectedStudents.contains(id))) {
                                    selectedStudents
                                        .removeAll(divisionStudentIds);
                                  } else {
                                    selectedStudents.addAll(divisionStudentIds);
                                  }
                                });
                              },
                              icon: Icon(
                                students.every((s) => selectedStudents
                                        .contains(s['studentUID']))
                                    ? Icons.deselect
                                    : Icons.select_all,
                              ),
                              label: Text(
                                students.every((s) => selectedStudents
                                        .contains(s['studentUID']))
                                    ? 'Deselect All'
                                    : 'Select All',
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: students.length,
                        itemBuilder: (context, studentIndex) {
                          final student = students[studentIndex];
                          final studentId = student['studentUID'] as String;
                          final isSelected = selectedStudents.contains(studentId);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedStudents.add(studentId);
                                } else {
                                  selectedStudents.remove(studentId);
                                }
                              });
                            },
                            title: Text(student['name'] ?? 'N/A'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Roll No: ${student['rollNo'] ?? 'N/A'}'),
                                Text(student['email'] ?? 'N/A'),
                              ],
                            ),
                            isThreeLine: true,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: selectedStudents.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _addSelectedStudents,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Add Selected Students (${selectedStudents.length})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

}