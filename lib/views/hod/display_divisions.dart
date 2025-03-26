import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class DivisionWiseView extends StatefulWidget {
  const DivisionWiseView({super.key});

  @override
  State<DivisionWiseView> createState() => _DivisionWiseViewState();
}

class _DivisionWiseViewState extends State<DivisionWiseView> with SingleTickerProviderStateMixin {
  String? _selectedDivision;
  bool _isLoading = false;
  List<Map<String, dynamic>> _studentData = [];
  List<Map<String, dynamic>> _filteredStudentData = [];
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _showSearchBar = false;
  final ScrollController _tableScrollController = ScrollController();

  final List<String> _divisions = ['SE1', 'SE2', 'SE3', 'SE4', 'SE5'];
  final Map<String, Color> _divisionColors = {
    'SE1': Colors.blue.shade700,
    'SE2': Colors.green.shade700,
    'SE3': Colors.purple.shade700,
    'SE4': Colors.orange.shade700,
    'SE5': Colors.teal.shade700,
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    _tabController = TabController(length: _divisions.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchDivisionData(_divisions[_tabController.index]);
      }
    });
    
    // Fetch initial division data after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDivisionData(_divisions[0]); // Load first division by default
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudentData = _studentData.where((student) {
        final String name = student['name'].toString().toLowerCase();
        final String rollNo = student['rollNo'].toString().toLowerCase();
        final String ct = student['ct']?.toString().toLowerCase() ?? '';
        final String tg = student['tg']?.toString().toLowerCase() ?? '';
        return name.contains(query) || 
               rollNo.contains(query) || 
               ct.contains(query) || 
               tg.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchDivisionData(String division) async {
    if (_selectedDivision == division && _studentData.isNotEmpty) return;
    
    setState(() {
      _isLoading = true;
      _selectedDivision = division;
      _searchController.clear();
    });

    try {
      // Add artificial delay to show loading animation (remove in production)
      await Future.delayed(const Duration(milliseconds: 800));
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .where('division', isEqualTo: division)
          .get();

      _studentData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'rollNo': data['rollNo'] ?? '',
          'name': data['name'] ?? '',
          'division': data['division'] ?? '',
          'ct': data['ct'] ?? '',
          'tg': data['tg'] ?? '',
        };
      }).toList();

      _studentData.sort((a, b) => a['rollNo'].compareTo(b['rollNo']));
      _filteredStudentData = List.from(_studentData);
      
      // Debug print for data verification
      print('Fetched ${_studentData.length} students for division $division');
      print('Sample data: ${_studentData.isNotEmpty ? _studentData.first : "No data"}');
      
    } catch (e) {
      print('Error fetching data: $e');
      _showErrorSnackBar('Error fetching data: $e');
      _studentData = [];
      _filteredStudentData = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Color _getSelectedDivisionColor() {
    return _selectedDivision != null 
        ? _divisionColors[_selectedDivision]! 
        : Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      body: Column(
        children: [
          // App Bar - Fixed height to prevent sizing issues
          Container(
            height: 160, // Adjusted height to ensure tabs are visible
            color: _getSelectedDivisionColor(),
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            // Handle back navigation
                            Navigator.of(context).pop();
                          },
                        ),
                        Expanded(
                          child: Text(
                            _selectedDivision != null 
                                ? 'Division $_selectedDivision Students' 
                                : 'Division Wise Students',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => _showSearchBar = !_showSearchBar);
                            print('Search bar toggled: $_showSearchBar');
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                          ),
                          tooltip: 'Refresh data',
                          onPressed: _selectedDivision != null
                              ? () => _fetchDivisionData(_selectedDivision!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab Bar - Ensures tabs are visible
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true, // Make tabs scrollable for small screens
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 20), // Add more padding
                      tabs: _divisions.map((division) {
                        return Tab(
                          child: Text(
                            division,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showSearchBar ? 70 : 0,
            color: Colors.white,
            child: Visibility(
              visible: _showSearchBar,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search by name, roll number, CT or TG',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: _getSelectedDivisionColor()),
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
                        color: _getSelectedDivisionColor(),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Stats card
          if (_selectedDivision != null && !_isLoading && _filteredStudentData.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    'Total Students',
                    _filteredStudentData.length.toString(),
                    Icons.people,
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[200]),
                  _buildStatItem(
                    context,
                    'Class Teachers',
                    _getUniqueCount('ct').toString(),
                    Icons.school,
                  ),
                  Container(height: 40, width: 1, color: Colors.grey[200]),
                  _buildStatItem(
                    context,
                    'Teacher Guardians',
                    _getUniqueCount('tg').toString(),
                    Icons.person,
                  ),
                ],
              ),
            ),
            
          // Table or loading/empty state
          Expanded(
            child: _buildTableContent(isSmallScreen),
          ),
        ],
      ),
    );
  }

  int _getUniqueCount(String field) {
    final Set<String> uniqueValues = {};
    for (var student in _filteredStudentData) {
      if (student[field] != null && student[field].toString().isNotEmpty) {
        uniqueValues.add(student[field].toString());
      }
    }
    return uniqueValues.length;
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: _getSelectedDivisionColor(),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getSelectedDivisionColor(),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTableContent(bool isSmallScreen) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_getSelectedDivisionColor()),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading students data...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedDivision == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_,
              size: 70,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Select a division to view students',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredStudentData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear search'),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
          ],
        ),
      );
    }

    // Use a responsive approach for the data table
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isSmallScreen 
            ? _buildMobileTable()
            : _buildDesktopTable(),
      ),
    );
  }

  Widget _buildMobileTable() {
    // For mobile screens, use a more compact layout
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudentData.length,
      separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
      itemBuilder: (context, index) {
        final student = _filteredStudentData[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roll Number
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: _getSelectedDivisionColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student['rollNo'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getSelectedDivisionColor(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Student Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: _getSelectedDivisionColor().withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getSelectedDivisionColor().withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            student['division'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _getSelectedDivisionColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (student['ct'] != null && student['ct'].toString().isNotEmpty)
                          Expanded(
                            child: Text(
                              'CT: ${student['ct']}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    if (student['tg'] != null && student['tg'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'TG: ${student['tg']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return Scrollbar(
      controller: _tableScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _tableScrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.grey[200],
              cardColor: Colors.white,
            ),
            child: DataTable(
              dataRowHeight: 70,
              horizontalMargin: 24,
              columnSpacing: 32,
              headingRowHeight: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
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
                DataColumn(label: Text('Division')),
                DataColumn(label: Text('CT')),
                DataColumn(label: Text('TG')),
              ],
              rows: _filteredStudentData.map((student) {
                return DataRow(
                  color: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.grey.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  }),
                  cells: [
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _getSelectedDivisionColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student['rollNo'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getSelectedDivisionColor(),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          student['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _getSelectedDivisionColor().withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getSelectedDivisionColor().withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          student['division'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _getSelectedDivisionColor(),
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        student['ct'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        student['tg'] ?? '',
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
    );
  }
}