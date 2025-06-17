// ignore_for_file: use_build_context_synchronously
import 'package:be_project_campus_connect/views/teachers/add_students.dart';
import 'package:be_project_campus_connect/views/teachers/lecture_attendance.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;
  final String className;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.className,
  });

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUploading = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Students'),
            Tab(icon: Icon(Icons.class_), text: 'Lectures'),
            Tab(icon: Icon(Icons.book), text: 'Resources'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => {},
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildLecturesTab(),
          _buildResourcesTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLecturesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Lectures')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final lectures = snapshot.data?.docs ?? [];

        if (lectures.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.class_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No lectures added yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addLecture,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lecture'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final lecture = lectures[index].data() as Map<String, dynamic>;
            final lectureId = lectures[index].id;
            final topic = lecture['topic'] ?? 'No Topic';
            final lectureDate = lecture['date'].toDate();

            // Get attendance data if available
            final int presentCount = lecture['presentCount'] ?? 0;
            final int totalStudents = lecture['totalStudents'] ?? 0;
            final double attendancePercentage =
                lecture['attendancePercentage'] ?? 0.0;
            final bool hasAttendance =
                lecture.containsKey('attendancePercentage');

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Navigate to attendance screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LectureAttendanceScreen(
                        classroomId: widget.classroomId,
                        lectureId: lectureId,
                        lectureTopic: topic,
                        lectureDate: lectureDate,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.2),
                        child: const Icon(Icons.class_),
                      ),
                      title: Text(
                        topic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMMM d, y').format(lectureDate),
                          ),
                          Text(
                            '${lecture['startTime']} - ${lecture['endTime']}',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.how_to_reg),
                    ),

                    // Show attendance info if available
                    if (hasAttendance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '$presentCount/$totalStudents present',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            _buildAttendanceIndicator(attendancePercentage),
                            const SizedBox(width: 4),
                            Text(
                              '${attendancePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getColorForAttendance(
                                    attendancePercentage),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Tap to take attendance',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceIndicator(double percentage) {
    return Container(
      width: 50,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 50 * (percentage / 100),
            decoration: BoxDecoration(
              color: _getColorForAttendance(percentage),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForAttendance(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Future<void> _addLecture() async {
    final topicController = TextEditingController();
    DateTime? selectedDate;
    String? startTime;
    String? endTime;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Lecture'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'Enter lecture topic',
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(
                  selectedDate == null
                      ? 'Select date'
                      : DateFormat('EEEE, MMMM d, y').format(selectedDate!),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(startTime ?? 'Select start time'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    startTime = time.format(context);
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(endTime ?? 'Select end time'),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    endTime = time.format(context);
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (topicController.text.isEmpty ||
                  selectedDate == null ||
                  startTime == null ||
                  endTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('Dummy Classrooms')
                    .doc(widget.classroomId)
                    .collection('Lectures')
                    .add({
                  'topic': topicController.text,
                  'date': selectedDate,
                  'startTime': startTime,
                  'endTime': endTime,
                  'createdAt': DateTime.now(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lecture added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding lecture: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Resources')
          .orderBy('uploadedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final resources = snapshot.data?.docs ?? [];

        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No study materials added yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _uploadResource,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Study Material'),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: resources.length,
              itemBuilder: (context, index) {
                final resource =
                    resources[index].data() as Map<String, dynamic>;
                final String fileName = resource['fileName'] ?? 'Unnamed File';
                final String fileType = resource['fileType'] ?? 'unknown';
                final String downloadUrl = resource['downloadUrl'] ?? '';
                final DateTime uploadDate = resource['uploadedAt'].toDate();

                IconData fileIcon;
                Color iconColor;

                switch (fileType.toLowerCase()) {
                  case 'pdf':
                    fileIcon = Icons.picture_as_pdf;
                    iconColor = Colors.red;
                    break;
                  case 'doc':
                  case 'docx':
                    fileIcon = Icons.description;
                    iconColor = Colors.blue;
                    break;
                  case 'ppt':
                  case 'pptx':
                    fileIcon = Icons.slideshow;
                    iconColor = Colors.orange;
                    break;
                  case 'xls':
                  case 'xlsx':
                    fileIcon = Icons.table_chart;
                    iconColor = Colors.green;
                    break;
                  case 'jpg':
                  case 'jpeg':
                  case 'png':
                    fileIcon = Icons.image;
                    iconColor = Colors.purple;
                    break;
                  default:
                    fileIcon = Icons.insert_drive_file;
                    iconColor = Colors.grey;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.2),
                      child: Icon(fileIcon, color: iconColor),
                    ),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Uploaded on ${DateFormat('MMM d, y').format(uploadDate)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue),
                          onPressed: () async {
                            if (downloadUrl.isNotEmpty) {
                              try {
                                final Uri url = Uri.parse(downloadUrl);
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Could not open file: $e')),
                                );
                              }
                            }
                          },
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              onTap: () async {
                                // Add a small delay to allow the menu to close
                                await Future.delayed(
                                    const Duration(milliseconds: 100));
                                _deleteResource(
                                    resources[index].id, downloadUrl);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () async {
                      if (downloadUrl.isNotEmpty) {
                        try {
                          final Uri url = Uri.parse(downloadUrl);
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open file: $e')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
            if (_isUploading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Uploading file...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _uploadResource() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'jpg',
          'png',
          'xlsx',
          'xls'
        ],
      );

      if (result != null) {
        final File file = File(result.files.single.path!);
        final String fileName = result.files.single.name;
        final String fileExtension =
            path.extension(fileName).replaceAll('.', '');

        // Show uploading indicator
        setState(() {
          _isUploading = true;
        });

        // Upload file to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('classrooms/${widget.classroomId}/resources/$fileName');

        final uploadTask = storageRef.putFile(file);
        final taskSnapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await taskSnapshot.ref.getDownloadURL();

        // Add file details to Firestore
        await FirebaseFirestore.instance
            .collection('Dummy Classrooms')
            .doc(widget.classroomId)
            .collection('Resources')
            .add({
          'fileName': fileName,
          'fileType': fileExtension,
          'downloadUrl': downloadUrl,
          'uploadedAt': DateTime.now(),
          'size': file.lengthSync(),
        });

        // Hide uploading indicator
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      // Hide uploading indicator
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  Future<void> _deleteResource(String resourceId, String fileUrl) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Resources')
          .doc(resourceId)
          .delete();

      // Delete from Storage
      if (fileUrl.isNotEmpty) {
        try {
          // Extract file path from URL
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          // Just log the storage error but continue
          print('Error deleting file from storage: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting resource: $e')),
      );
    }
  }

  Widget _buildFloatingActionButton() {
    // Only show FAB for the currently active tab
    switch (_currentTabIndex) {
      case 0: // Students tab
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddStudentsScreen(
                  classroomId: widget.classroomId,
                ),
              ),
            );
          },
          tooltip: 'Add Student',
          child: const Icon(Icons.person_add),
        );
      case 1: // Lectures tab
        return FloatingActionButton(
          onPressed: _addLecture,
          tooltip: 'Add Lecture',
          child: const Icon(Icons.add_box),
        );
      case 2: // Resources tab
        return FloatingActionButton(
          onPressed: _uploadResource,
          tooltip: 'Upload Study Material',
          child: const Icon(Icons.upload_file),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Dummy Classrooms')
          .doc(widget.classroomId)
          .collection('Students')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final students = snapshot.data?.docs ?? [];

        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No students in this classroom yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddStudentsScreen(
                          classroomId: widget.classroomId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Student'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index].data() as Map<String, dynamic>;
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    student['name'][0].toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
                title: Text(
                  student['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Roll No: ${student['rollNo']}'),
                    if (student['email'] != null && student['email'].isNotEmpty)
                      Text('Email: ${student['email']}'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
