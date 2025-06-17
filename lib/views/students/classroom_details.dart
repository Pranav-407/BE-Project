// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentClassroomDetailScreen extends StatefulWidget {
  final String classroomId;
  final String className;

  const StudentClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.className,
  });

  @override
  State<StudentClassroomDetailScreen> createState() =>
      _StudentClassroomDetailScreenState();
}

class _StudentClassroomDetailScreenState
    extends State<StudentClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Replace this with the actual student ID that you're using in your app
  final String _studentId =
      '2223-VSKN-11453'; // This should match your Firestore document ID

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.class_), text: 'Lectures'),
            Tab(icon: Icon(Icons.book), text: 'Resources'),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLecturesTab(),
            _buildResourcesTab(),
          ],
        ),
      ),
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading lectures',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final lectures = snapshot.data?.docs ?? [];

        if (lectures.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.class_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No lectures available',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your teacher hasn\'t added any lectures yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple.shade600,
                  ),
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

            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Dummy Classrooms')
                  .doc(widget.classroomId)
                  .collection('Lectures')
                  .doc(lectureId)
                  .collection('Attendance')
                  .limit(
                      1) // Get just the first document since there should be only one
                  .get(),
              builder: (context, attendanceSnapshot) {
                // Default to unknown attendance status
                bool? wasPresent;

                if (attendanceSnapshot.connectionState ==
                        ConnectionState.done &&
                    attendanceSnapshot.hasData &&
                    attendanceSnapshot.data!.docs.isNotEmpty) {
                  // Get the first document
                  final attendanceDoc = attendanceSnapshot.data!.docs[0];
                  final attendanceData =
                      attendanceDoc.data() as Map<String, dynamic>;

                  // Access the 'present' map field and get the value for the student ID
                  if (attendanceData.containsKey('present')) {
                    Map<String, dynamic> presentMap =
                        attendanceData['present'] as Map<String, dynamic>;
                    if (presentMap.containsKey(_studentId)) {
                      wasPresent = presentMap[_studentId] as bool;
                    }
                  }
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.deepPurple.withOpacity(0.2),
                              child: const Icon(
                                Icons.class_,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMMM d, y')
                                        .format(lectureDate),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${lecture['startTime']} - ${lecture['endTime']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildAttendanceStatus(wasPresent),
                          ],
                        ),
                        if (hasAttendance)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.deepPurple.shade400,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Class Attendance',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$presentCount/$totalStudents students present',
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getAttendanceStatusColor(
                                                  attendancePercentage)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${attendancePercentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _getAttendanceStatusColor(
                                                attendancePercentage),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildAttendanceProgressBar(
                                      attendancePercentage),
                                ],
                              ),
                            ),
                          ),
                        if (wasPresent != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: wasPresent
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: wasPresent
                                      ? Colors.green.shade200
                                      : Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    wasPresent
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color:
                                        wasPresent ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    wasPresent
                                        ? 'You were present in this lecture'
                                        : 'You were absent from this lecture',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: wasPresent
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
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
      },
    );
  }

  Widget _buildAttendanceStatus(bool? wasPresent) {
    if (wasPresent == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Pending',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: wasPresent ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            wasPresent ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: wasPresent ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            wasPresent ? 'Present' : 'Absent',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: wasPresent ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceProgressBar(double percentage) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Container(
            width:
                (MediaQuery.of(context).size.width - 64) * (percentage / 100),
            height: 6,
            decoration: BoxDecoration(
              color: _getAttendanceStatusColor(percentage),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceStatusColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Error loading resources',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final resources = snapshot.data?.docs ?? [];

        if (resources.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.book_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No study materials available',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your teacher hasn\'t added any study materials yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final resource = resources[index].data() as Map<String, dynamic>;
            final String fileName = resource['fileName'] ?? 'Unnamed File';
            final String fileType = resource['fileType'] ?? 'unknown';
            final String downloadUrl = resource['downloadUrl'] ?? '';
            final DateTime uploadDate = resource['uploadedAt'].toDate();
            final int fileSize = resource['size'] ?? 0;

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          fileIcon,
                          size: 32,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uploaded on ${DateFormat('MMM d, y').format(uploadDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatFileSize(fileSize),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          color: Colors.deepPurple.shade600,
                        ),
                        onPressed: () async {
                          if (downloadUrl.isNotEmpty) {
                            try {
                              final Uri url = Uri.parse(downloadUrl);
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Could not download file: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
