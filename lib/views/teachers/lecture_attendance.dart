import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LectureAttendanceScreen extends StatefulWidget {
  final String classroomId;
  final String lectureId;
  final String lectureTopic;
  final DateTime lectureDate;

  const LectureAttendanceScreen({
    super.key,
    required this.classroomId,
    required this.lectureId,
    required this.lectureTopic,
    required this.lectureDate,
  });

  @override
  State<LectureAttendanceScreen> createState() => _LectureAttendanceScreenState();
}

class _LectureAttendanceScreenState extends State<LectureAttendanceScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _students = [];
  Map<String, bool> _attendance = {};
  bool _attendanceExists = false;
  String _attendanceId = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load students from this classroom
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Students')
          .orderBy('name')
          .get();

      final studentsData = studentsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Check if attendance for this lecture already exists
      final attendanceSnapshot = await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Lectures')
          .doc(widget.lectureId)
          .collection('Attendance')
          .get();

      Map<String, bool> attendanceData = {};
      
      if (attendanceSnapshot.docs.isNotEmpty) {
        _attendanceExists = true;
        final attendanceDoc = attendanceSnapshot.docs.first;
        _attendanceId = attendanceDoc.id;
        
        final data = attendanceDoc.data();
        final Map<String, dynamic> presentStudents = data['present'] ?? {};
        
        // Initialize attendance from existing data
        for (var student in studentsData) {
          final studentId = student['id'];
          attendanceData[studentId] = presentStudents[studentId] == true;
        }
      } else {
        // Initialize all students as present by default
        for (var student in studentsData) {
          attendanceData[student['id']] = true;
        }
      }

      setState(() {
        _students = studentsData;
        _attendance = attendanceData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare attendance data
      Map<String, bool> presentStudents = {};
      _attendance.forEach((studentId, isPresent) {
        presentStudents[studentId] = isPresent;
      });

      // Calculate attendance statistics
      int totalStudents = _students.length;
      int presentCount = presentStudents.values.where((present) => present).length;
      double attendancePercentage = totalStudents > 0 
          ? (presentCount / totalStudents) * 100 
          : 0;

      final attendanceData = {
        'date': widget.lectureDate,
        'present': presentStudents,
        'totalStudents': totalStudents,
        'presentCount': presentCount,
        'attendancePercentage': attendancePercentage,
        'updatedAt': DateTime.now(),
      };

      if (_attendanceExists) {
        // Update existing attendance record
        await FirebaseFirestore.instance
            .collection('Dummy Classrooms')
            .doc(widget.classroomId)
            .collection('Lectures')
            .doc(widget.lectureId)
            .collection('Attendance')
            .doc(_attendanceId)
            .update(attendanceData);
      } else {
        // Create new attendance record
        await FirebaseFirestore.instance
            .collection('Dummy Classrooms')
            .doc(widget.classroomId)
            .collection('Lectures')
            .doc(widget.lectureId)
            .collection('Attendance')
            .add(attendanceData);
      }

      // Update lecture with attendance summary
      await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Lectures')
          .doc(widget.lectureId)
          .update({
        'attendancePercentage': attendancePercentage,
        'presentCount': presentCount,
        'totalStudents': totalStudents,
      });

      setState(() {
        _isSaving = false;
        _attendanceExists = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully')),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving attendance: $e')),
      );
    }
  }

  void _toggleAllAttendance(bool value) {
    setState(() {
      for (var student in _students) {
        _attendance[student['id']] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final attendanceDate = DateFormat('EEEE, MMMM d, y').format(widget.lectureDate);
    final presentCount = _attendance.values.where((present) => present).length;
    final attendancePercentage = _students.isNotEmpty 
        ? (presentCount / _students.length) * 100 
        : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Lecture Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lectureTopic,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            attendanceDate,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoCard(
                                title: 'Total',
                                value: '${_students.length}',
                                icon: Icons.people,
                                color: Colors.blue,
                              ),
                              _buildInfoCard(
                                title: 'Present',
                                value: '$presentCount',
                                icon: Icons.check_circle,
                                color: Colors.green,
                              ),
                              _buildInfoCard(
                                title: 'Absent',
                                value: '${_students.length - presentCount}',
                                icon: Icons.cancel,
                                color: Colors.red,
                              ),
                              _buildInfoCard(
                                title: 'Percentage',
                                value: '${attendancePercentage.toStringAsFixed(1)}%',
                                icon: Icons.analytics,
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Quick actions row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _toggleAllAttendance(true),
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                label: const Text('Mark All Present'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => _toggleAllAttendance(false),
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                label: const Text('Mark All Absent'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Students List with attendance checkboxes
                    Expanded(
                      child: _students.isEmpty
                          ? const Center(
                              child: Text(
                                'No students in this classroom',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final studentId = student['id'];
                                final isPresent = _attendance[studentId] ?? true;
                                
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isPresent ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: isPresent
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      child: Text(
                                        student['name'][0].toUpperCase(),
                                        style: TextStyle(
                                          color: isPresent ? Colors.green[700] : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      student['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('Roll No: ${student['rollNo']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Present button
                                        IconButton(
                                          icon: Icon(
                                            Icons.check_circle,
                                            color: isPresent ? Colors.green : Colors.grey[400],
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _attendance[studentId] = true;
                                            });
                                          },
                                        ),
                                        // Absent button
                                        IconButton(
                                          icon: Icon(
                                            Icons.cancel,
                                            color: !isPresent ? Colors.red : Colors.grey[400],
                                            size: 30,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _attendance[studentId] = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Toggle attendance status on tap
                                      setState(() {
                                        _attendance[studentId] = !isPresent;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
      floatingActionButton: !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _saveAttendance,
              icon: const Icon(Icons.save),
              label: const Text('Save Attendance'),
            )
          : null,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}