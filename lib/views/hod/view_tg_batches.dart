import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BatchWiseView extends StatefulWidget {
  const BatchWiseView({super.key});

  @override
  State<BatchWiseView> createState() => _BatchWiseViewState();
}

class _BatchWiseViewState extends State<BatchWiseView> {
  String? _selectedBatch;
  bool _isLoading = false;
  List<Map<String, dynamic>> _studentData = [];
  List<Map<String, dynamic>> _filteredStudentData = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _batchScrollController = ScrollController();

  final List<String> _batches = [
    'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10',
    'S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19'
  ];

  Map<String, int> _batchCounts = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterStudents);
    _fetchAllBatchCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _batchScrollController.dispose();
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

  Future<void> _fetchAllBatchCounts() async {
    setState(() => _isLoading = true);

    try {
      Map<String, int> counts = {};
      
      for (String batch in _batches) {
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('Dummy Students')
            .where('tgBatch', isEqualTo: batch)
            .get();
        counts[batch] = snapshot.size;
      }

      setState(() => _batchCounts = counts);
    } catch (e) {
      _showErrorSnackbar('Error fetching batch counts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchBatchData(String batch) async {
    setState(() {
      _isLoading = true;
      _selectedBatch = batch;
      _searchController.clear();
    });

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .where('tgBatch', isEqualTo: batch)
          .get();

      _studentData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'rollNo': data['rollNo'] ?? '',
          'name': data['name'] ?? '',
          'ct': data['ct'] ?? '',
          'tg': data['tg'] ?? '',
          'division': data['division'] ?? '',
          'batch': data['tgBatch'] ?? '',
        };
      }).toList();

      _studentData.sort((a, b) => a['rollNo'].compareTo(b['rollNo']));
      _filteredStudentData = List.from(_studentData);
    } catch (e) {
      _showErrorSnackbar('Error fetching data: $e');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Batch Wise Students',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withOpacity(0.8),
                            primaryColor.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: Container(
          color: Colors.grey[50],
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
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
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.group_outlined,
                            color: primaryColor,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select Batch',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.builder(
                        controller: _batchScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _batches.length,
                        itemBuilder: (context, index) {
                          final batch = _batches[index];
                          final isSelected = _selectedBatch == batch;
                          final count = _batchCounts[batch] ?? 0;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 12, bottom: 12),
                            child: Material(
                              elevation: isSelected ? 4 : 0,
                              shadowColor: primaryColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => _fetchBatchData(batch),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryColor : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                          ? Colors.transparent 
                                          : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        batch,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: isSelected 
                                              ? Colors.white 
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Colors.white.withOpacity(0.3) 
                                              : Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          count.toString(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected 
                                                ? Colors.white 
                                                : Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Search by name or roll number',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: primaryColor.withOpacity(0.7)),
                            filled: true,
                            fillColor: Colors.white,
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
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    color: Colors.grey[500],
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading data...',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudentData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedBatch == null
                                      ? Icons.touch_app
                                      : Icons.search_off,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedBatch == null
                                      ? 'Select a batch to view students'
                                      : 'No students found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_selectedBatch != null && _searchController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Try a different search',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 16),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Batch ',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        TextSpan(
                                          text: _selectedBatch,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' • ${_filteredStudentData.length} students',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Card(
                                    elevation: 2,
                                    shadowColor: Colors.black.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: SingleChildScrollView(
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
                                                color: primaryColor,
                                                fontSize: 14,
                                              ),
                                              headingRowColor: MaterialStateProperty.all(
                                                Colors.grey[50],
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              columns: const [
                                                DataColumn(label: Text('Roll No')),
                                                DataColumn(label: Text('Name')),
                                                DataColumn(label: Text('Division')),
                                                DataColumn(label: Text('Class Teacher')),
                                                DataColumn(label: Text('TG')),
                                              ],
                                              rows: _filteredStudentData.map((student) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: primaryColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          student['rollNo'],
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color: primaryColor,
                                                            fontWeight: FontWeight.w500,
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
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.grey[800],
                                                          ),
                                                          softWrap: true,
                                                          overflow: TextOverflow.visible,
                                                          maxLines: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          vertical: 4,
                                                          horizontal: 8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          student['division'],
                                                          style: GoogleFonts.poppins(
                                                            fontSize: 14,
                                                            color: Colors.grey[800],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        student['ct'],
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
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}