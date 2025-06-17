import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/students/classroom_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class MyClassroomsScreen extends StatefulWidget {
  const MyClassroomsScreen({super.key});

  @override
  State<MyClassroomsScreen> createState() => _MyClassroomsScreenState();
}

class _MyClassroomsScreenState extends State<MyClassroomsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _classrooms = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchClassrooms();
  }

  Future<void> _fetchClassrooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get the student document to access their classrooms
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
      final enrolledClassrooms =
          studentData['myClassrooms'] as List<dynamic>? ?? [];

      if (enrolledClassrooms.isEmpty) {
        setState(() {
          _isLoading = false;
          _classrooms = [];
        });
        return;
      }

      // Convert to a more convenient format
      final List<Map<String, dynamic>> classroomsList = [];
      for (final classroom in enrolledClassrooms) {
        // Convert to Map if it's not already
        final classroomMap = classroom is Map
            ? Map<String, dynamic>.from(classroom)
            : Map<String, dynamic>.from(classroom as Map<String, dynamic>);

        // Get additional details from the classroom document
        try {
          final classroomDoc = await FirebaseFirestore.instance
              .collection('Dummy Classrooms')
              .doc(classroomMap['classroomId'])
              .get();

          if (classroomDoc.exists) {
            final classroomData = classroomDoc.data() ?? {};
            classroomMap['studentCount'] = classroomData['studentCount'] ?? 0;
            classroomMap['teacherName'] =
                classroomData['teacherName'] ?? 'Unknown';
            classroomMap['classCode'] = classroomData['classCode'] ?? '';

            // Get the count of resources (formerly announcements)
            final resourcesQuery = await FirebaseFirestore.instance
                .collection('Dummy Classrooms')
                .doc(classroomMap['classroomId'])
                .collection('Resources')  // Keeping the collection name the same
                .count()
                .get();

            classroomMap['resourceCount'] = resourcesQuery.count;

            // Get the count of lectures
            final lecturesQuery = await FirebaseFirestore.instance
                .collection('Dummy Classrooms')
                .doc(classroomMap['classroomId'])
                .collection('Lectures')  // Assuming this collection exists
                .count()
                .get();

            classroomMap['lectureCount'] = lecturesQuery.count;

            classroomsList.add(classroomMap);
          }
        } catch (e) {
          print(
              'Error fetching details for classroom ${classroomMap['classroomId']}: $e');
        }
      }

      setState(() {
        _isLoading = false;
        _classrooms = classroomsList;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading classrooms: $e';
      });
    }
  }

  void _viewClassroomDetails(Map<String, dynamic> classroom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentClassroomDetailScreen(
          classroomId: classroom['classroomId'],
          className: classroom['className'],
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${classroom['className']}...'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Classrooms',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchClassrooms,
            tooltip: 'Refresh',
          ),
        ],
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                )
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _classrooms.isEmpty
                      ? _buildEmptyStateWidget()
                      : _buildClassroomsList(),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchClassrooms,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ).animate().scale(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
            const SizedBox(height: 20),
            Text(
              'No Classrooms Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You haven\'t joined any classrooms yet. Use a classroom code to join your first class!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade600,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to home
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Join a Classroom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with counter
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 30,
                  color: Colors.deepPurple.shade400,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_classrooms.length} ${_classrooms.length == 1 ? 'Classroom' : 'Classrooms'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    Text(
                      'Tap a classroom to view details',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(
                begin: -0.2,
                end: 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 20),

          // Classrooms list
          Expanded(
            child: ListView.builder(
              itemCount: _classrooms.length,
              itemBuilder: (context, index) {
                final classroom = _classrooms[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildClassroomCard(classroom, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(Map<String, dynamic> classroom, int index) {
    // Set up some colors based on index for variety
    final List<Color> cardColors = [
      Colors.deepPurple.shade50,
      Colors.blue.shade50,
      Colors.teal.shade50,
      Colors.amber.shade50,
      Colors.pink.shade50,
    ];

    final List<Color> iconColors = [
      Colors.deepPurple.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.amber.shade700,
      Colors.pink.shade400,
    ];

    final colorIndex = index % cardColors.length;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: cardColors[colorIndex],
      child: InkWell(
        onTap: () => _viewClassroomDetails(classroom),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with subject and class code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Subject pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: iconColors[colorIndex].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      classroom['subject'] ?? 'No Subject',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColors[colorIndex],
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Class code
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.keyboard,
                          size: 12,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          classroom['classCode'] ?? '------',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Class name
              Text(
                classroom['className'] ?? 'Unknown Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 5),

              // Teacher name
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: iconColors[colorIndex],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    classroom['teacherName'] ?? 'Unknown Teacher',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Students count
                  _buildStatItem(
                    Icons.people,
                    '${classroom['studentCount'] ?? 0}',
                    'Students',
                    iconColors[colorIndex],
                  ),

                  // Vertical divider
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),

                  // Resources count (formerly announcements)
                  _buildStatItem(
                    Icons.folder,
                    '${classroom['resourceCount'] ?? 0}',
                    'Resources',
                    iconColors[colorIndex],
                  ),

                  // Vertical divider
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),

                  // Lectures count (formerly joined date)
                  _buildStatItem(
                    Icons.video_library,
                    '${classroom['lectureCount'] ?? 0}',
                    'Lectures',
                    iconColors[colorIndex],
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Action button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _viewClassroomDetails(classroom),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColors[colorIndex],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fade(
          duration: Duration(milliseconds: 300 + (index * 100)),
          delay: Duration(milliseconds: index * 50),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.3,
          end: 0,
          duration: Duration(milliseconds: 300 + (index * 100)),
          delay: Duration(milliseconds: index * 50),
          curve: Curves.easeOut,
        );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}