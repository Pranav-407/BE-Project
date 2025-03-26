import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TeacherAssignmentScreen extends StatefulWidget {
  const TeacherAssignmentScreen({super.key});

  @override
  State<TeacherAssignmentScreen> createState() => _TeacherAssignmentScreenState();
}

class _TeacherAssignmentScreenState extends State<TeacherAssignmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> classes = ['SE1', 'SE2', 'SE3', 'SE4', 'SE5'];
  final List<String> batches = [
    'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'S10',
    'S11', 'S12', 'S13', 'S14', 'S15', 'S16', 'S17', 'S18', 'S19'
  ];
  
  Map<String, String?> selectedCTs = {};
  Map<String, String?> selectedTGs = {};
  bool isLoading = false;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentAssignments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentAssignments() async {
    setState(() => isLoading = true);
    try {
      // Initialize maps
      Map<String, String?> initialCTs = {
        for (var className in classes) className: null
      };
      Map<String, String?> initialTGs = {
        for (var batch in batches) batch: null
      };

      // Fetch teacher data from Firestore
      final QuerySnapshot teacherSnapshot =
          await FirebaseFirestore.instance.collection('Dummy Teachers').get();

      for (var doc in teacherSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Load CT assignments
        if (data.containsKey('assignedClassesCT') && data['assignedClassesCT'] is List) {
          final List<dynamic> assignedClasses = data['assignedClassesCT'];
          for (var className in assignedClasses) {
            if (initialCTs.containsKey(className)) {
              initialCTs[className] = doc.id;
            }
          }
        }

        // Load TG assignments
        if (data.containsKey('assignedBatchesTG') && data['assignedBatchesTG'] is List) {
          final List<dynamic> assignedBatches = data['assignedBatchesTG'];
          for (var batch in assignedBatches) {
            if (initialTGs.containsKey(batch)) {
              initialTGs[batch] = doc.id;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          selectedCTs = initialCTs;
          selectedTGs = initialTGs;
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error loading assignments: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveCTAssignments() async {
    setState(() => isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Clear existing CT assignments
      final teacherSnapshot = await FirebaseFirestore.instance.collection('Dummy Teachers').get();
      for (var doc in teacherSnapshot.docs) {
        batch.update(doc.reference, {'assignedClassesCT': []});
      }

      // Update teacher assignments
      Map<String, List<String>> teacherAssignments = {};
      for (var entry in selectedCTs.entries) {
        if (entry.value != null) {
          teacherAssignments.putIfAbsent(entry.value!, () => []).add(entry.key);
        }
      }

      // Update teachers collection
      for (var entry in teacherAssignments.entries) {
        final teacherRef = FirebaseFirestore.instance.collection('Dummy Teachers').doc(entry.key);
        batch.update(teacherRef, {'assignedClassesCT': entry.value});
      }

      // Update students collection
      for (var className in classes) {
        final assignedTeacherId = selectedCTs[className];
        if (assignedTeacherId != null) {
          // Get teacher's name
          final teacherDoc = await FirebaseFirestore.instance
              .collection('Dummy Teachers')
              .doc(assignedTeacherId)
              .get();
          final teacherName = (teacherDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

          // Update all students in this class
          final studentsSnapshot = await FirebaseFirestore.instance
              .collection('Dummy Students')
              .where('division', isEqualTo: className)
              .get();

          for (var studentDoc in studentsSnapshot.docs) {
            batch.update(studentDoc.reference, {
              'ct': teacherName,
            });
          }
        }
      }

      await batch.commit();
      _showSuccessAnimation = true;
      setState(() {});
      await Future.delayed(const Duration(seconds: 2));
      _showSuccessAnimation = false;
      setState(() {});
      _showSuccessSnackbar('Class Teacher assignments saved successfully!');
    } catch (e) {
      _showErrorSnackbar('Error saving CT assignments: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveTGAssignments() async {
    setState(() => isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Clear existing TG assignments
      final teacherSnapshot = await FirebaseFirestore.instance.collection('Dummy Teachers').get();
      for (var doc in teacherSnapshot.docs) {
        batch.update(doc.reference, {'assignedBatchesTG': []});
      }

      // Update teacher assignments
      Map<String, List<String>> teacherAssignments = {};
      for (var entry in selectedTGs.entries) {
        if (entry.value != null) {
          teacherAssignments.putIfAbsent(entry.value!, () => []).add(entry.key);
        }
      }

      // Update teachers collection
      for (var entry in teacherAssignments.entries) {
        final teacherRef = FirebaseFirestore.instance.collection('Dummy Teachers').doc(entry.key);
        batch.update(teacherRef, {'assignedBatchesTG': entry.value});
      }

      // Update students collection
      for (var batchName in batches) {
        final assignedTeacherId = selectedTGs[batchName];
        if (assignedTeacherId != null) {
          // Get teacher's name
          final teacherDoc = await FirebaseFirestore.instance
              .collection('Dummy Teachers')
              .doc(assignedTeacherId)
              .get();
          final teacherName = (teacherDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';

          // Update all students in this batch
          final studentsSnapshot = await FirebaseFirestore.instance
              .collection('Dummy Students')
              .where('tgBatch', isEqualTo: batchName)
              .get();

          for (var studentDoc in studentsSnapshot.docs) {
            batch.update(studentDoc.reference, {
              'tg': teacherName,
            });
          }
        }
      }

      await batch.commit();
      _showSuccessAnimation = true;
      setState(() {});
      await Future.delayed(const Duration(seconds: 2));
      _showSuccessAnimation = false;
      setState(() {});
      _showSuccessSnackbar('Teacher Guardian assignments saved successfully!');
    } catch (e) {
      _showErrorSnackbar('Error saving TG assignments: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _showSuccessSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Widget _buildAssignmentList(List<String> items, Map<String, String?> selections, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Dummy Teachers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading teachers...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          padding: const EdgeInsets.only(bottom: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              elevation: 3,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            type == 'CT' ? Icons.class_ : Icons.groups,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type == 'CT' ? 'Class: $item' : 'Batch: $item',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selections[item],
                          decoration: InputDecoration(
                            labelText: type == 'CT' ? 'Select Class Teacher' : 'Select Teacher Guardian',
                            labelStyle: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: GoogleFonts.poppins(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            prefixIcon: Icon(
                              type == 'CT' ? Icons.person : Icons.person_outline,
                              color: Theme.of(context).primaryColor.withOpacity(0.7),
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down_circle,
                            color: Theme.of(context).primaryColor,
                          ),
                          dropdownColor: Colors.white,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                'Not Assigned',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            ...snapshot.data!.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  data['name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selections[item] = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Teacher Assignments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadCurrentAssignments,
            tooltip: 'Refresh Assignments',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.class_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Class Teachers',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Teacher Guardians',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[100],
            child: TabBarView(
              controller: _tabController,
              children: [
                // Class Teachers Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Class Teacher Assignments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Assign teachers to classes. Each class can have one class teacher.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      Expanded(child: _buildAssignmentList(classes, selectedCTs, 'CT')),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveCTAssignments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                          ),
                          child: isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Saving...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Save Class Teacher Assignments',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
                // Teacher Guardians Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Teacher Guardian Assignments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Assign teacher guardians to batches. Each batch can have one teacher guardian.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      Expanded(child: _buildAssignmentList(batches, selectedTGs, 'TG')),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveTGAssignments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: Theme.of(context).primaryColor.withOpacity(0.4),
                          ),
                          child: isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Saving...'),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Save Teacher Guardian Assignments',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade500,
                        size: 60,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Saved!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }
}