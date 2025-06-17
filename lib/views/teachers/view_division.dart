// view_division.dart file content:
import 'package:be_project_campus_connect/services/shared_preference.dart';
import 'package:be_project_campus_connect/views/teachers/student_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewDivision extends StatefulWidget {
  const ViewDivision({super.key});

  @override
  State<ViewDivision> createState() => _ViewDivisionState();
}

class _ViewDivisionState extends State<ViewDivision> {
  bool _isLoading = false;
  List<String> _assignedDivisions = [];
  String? _selectedDivision;
  List<Map<String, dynamic>> _studentData = [];
  List<Map<String, dynamic>> _filteredStudentData = [];
  final TextEditingController _searchController = TextEditingController();
  Map<String, int> _divisionCounts = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    _fetchTeacherDivisions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudentData = _studentData.where((student) {
        final String name = student['name'].toString().toLowerCase();
        final String rollNo = student['rollNo'].toString().toLowerCase();
        return name.contains(query) || rollNo.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchTeacherDivisions() async {
    await SharedPreferenceData.getSharedPreferenceData();
    setState(() => _isLoading = true);

    try {
      final DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
          .collection('Dummy Teachers')
          .doc(SharedPreferenceData.loginID)
          .get();

      if (teacherDoc.exists) {
        final data = teacherDoc.data() as Map<String, dynamic>;
        final List<dynamic> divisions = data['assignedClassesCT'] ?? [];
        _assignedDivisions = divisions.cast<String>();

        // Fetch counts for each division
        Map<String, int> counts = {};
        for (String division in _assignedDivisions) {
          final QuerySnapshot snapshot = await FirebaseFirestore.instance
              .collection('Dummy Students')
              .where('division', isEqualTo: division)
              .get();
          counts[division] = snapshot.size;
        }

        setState(() => _divisionCounts = counts);
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching assigned divisions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDivisionData(String division) async {
    setState(() {
      _isLoading = true;
      _selectedDivision = division;
      _searchController.clear();
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .where('division', isEqualTo: division)
          .get();

      _studentData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'rollNo': data['rollNo'] ?? '',
          'UID': data['UID'] ?? '',
          'name': data['name'] ?? '',
          'ct': data['ct'] ?? '',
          'division': data['division'] ?? '',
          'tgBatch': data['tgBatch'] ?? '',
          'pendingFees': data['pendingFees'] ?? '',
          'SinhgadEmail': data['SinhgadEmail'] ?? '',
          'Email': data['Email'] ?? '',
          'PRN': data['prnNo'] ?? '',
          'tg': data['tg'] ?? '',
          'mobileNo': data['studentMobile'] ?? '',
          'parentMobNo': data['parentMobile'] ?? '',
          'permanentAddress': data['permanentAddress'] ?? '',
          // Add any other fields you want to display
        };
      }).toList();

      _studentData.sort((a, b) => a['rollNo'].compareTo(b['rollNo']));
      _filteredStudentData = List.from(_studentData);
    } catch (e) {
      _showErrorSnackbar('Error fetching student data: $e');
      _studentData = [];
      _filteredStudentData = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'My Division',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Your Assigned Divisions',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_assignedDivisions.isEmpty && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'No divisions assigned yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _assignedDivisions.length,
                        itemBuilder: (context, index) {
                          final division = _assignedDivisions[index];
                          final isSelected = _selectedDivision == division;
                          final count = _divisionCounts[division] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ElevatedButton(
                              onPressed: () => _fetchDivisionData(division),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : Colors.grey[800],
                                elevation: isSelected ? 2 : 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey[300]!,
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    division,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count students',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.9)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_selectedDivision != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search by name or roll number',
                          hintStyle:
                              GoogleFonts.poppins(color: Colors.grey[400]),
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : _selectedDivision == null
                      ? Center(
                          child: Text(
                            'Select a division to view students',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : _filteredStudentData.isEmpty
                          ? Center(
                              child: Text(
                                'No students found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    dividerColor: Colors.grey[200],
                                  ),
                                  child: DataTable(
                                    dataRowHeight: 70,
                                    horizontalMargin: 24,
                                    columnSpacing: 32,
                                    headingRowHeight: 56,
                                    headingTextStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                    headingRowColor: MaterialStateProperty.all(
                                      Colors.grey[100],
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Roll No')),
                                      DataColumn(label: Text('Name')),
                                      DataColumn(label: Text('TG Batch')),
                                      DataColumn(label: Text('TG Teacher')),
                                      DataColumn(label: Text('Pending Fee')),
                                      DataColumn(label: Text('Mobile No')),
                                      DataColumn(label: Text('Parent Mobile No')),
                                      DataColumn(label: Text('Address')),
                                    ],
                                    rows: _filteredStudentData.map((student) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              student['rollNo'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        StudentDetailsScreen(
                                                      studentData: student,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: SizedBox(
                                                width: 200,
                                                child: Text(
                                                  student['name'],
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: Colors.blue[700],
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              student['tgBatch'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              student['tg'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${student['pendingFees']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${student['mobileNo']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${student['parentMobNo']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "${student['permanentAddress']}",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}