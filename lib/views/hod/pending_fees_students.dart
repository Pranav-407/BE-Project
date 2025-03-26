import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PendingFeesScreen extends StatefulWidget {
  const PendingFeesScreen({super.key});

  @override
  State<PendingFeesScreen> createState() => _PendingFeesScreenState();
}

class _PendingFeesScreenState extends State<PendingFeesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _studentsWithPendingFees = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredStudents = [];
  double _totalPendingAmount = 0;
  bool _isTotalVisible = false;
  bool _isSendingReminders = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentsWithPendingFees();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStudents() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _studentsWithPendingFees.where((student) {
        final name = student['name'].toString().toLowerCase();
        final id = student['id'].toString().toLowerCase();
        final division = student['division'].toString().toLowerCase();
        final rollNo = student['rollNo'].toString().toLowerCase();
        final tg = student['tg'].toString().toLowerCase();
        return name.contains(query) ||
            id.contains(query) ||
            division.contains(query) ||
            rollNo.contains(query) ||
            tg.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchStudentsWithPendingFees() async {
    setState(() {
      _isLoading = true;
      _searchController.clear();
      _isTotalVisible = false;
    });

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .where('pendingFees', isGreaterThan: 0)
          .get();

      _studentsWithPendingFees = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'pendingFees': data['pendingFees'] ?? 0.0,
          'division': data['division'] ?? 'N/A',
          'rollNo': data['rollNo'] ?? 'N/A',
          'tg': data['tg'] ?? 'N/A',
        };
      }).toList();

      _studentsWithPendingFees.sort((a, b) =>
          (b['pendingFees'] as num).compareTo(a['pendingFees'] as num));

      _filteredStudents = List.from(_studentsWithPendingFees);

      _totalPendingAmount = _studentsWithPendingFees.fold(
          0, (sum, student) => sum + (student['pendingFees'] as num));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading students: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      _studentsWithPendingFees = [];
      _filteredStudents = [];
      _totalPendingAmount = 0;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleTotalVisibility() {
    setState(() {
      _isTotalVisible = !_isTotalVisible;
    });
  }

  Future<void> _sendRemindersToAllStudents() async {
    if (_filteredStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No students with pending fees'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      return;
    }

    setState(() {
      _isSendingReminders = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (var student in _filteredStudents) {
        final studentId = student['id'];
        final studentName = student['name'];
        final pendingAmount = student['pendingFees'] as num;

        final notificationRef = FirebaseFirestore.instance
            .collection('Dummy Students')
            .doc(studentId)
            .collection('Notifications')
            .doc();

        batch.set(notificationRef, {
          'id': notificationRef.id,
          'title': 'Fee Payment Reminder',
          'message':
              'Dear $studentName, this is a reminder that you have a pending fee balance of ₹${pendingAmount.toStringAsFixed(2)}. Please clear your dues at your earliest convenience to avoid any late payment penalties.',
          'timestamp': timestamp,
          'type': 'fee_reminder',
          'isRead': false,
          'amount': pendingAmount,
        });
      }

      await batch.commit();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group_rounded,
                    color: Colors.green,
                    size: 60,
                  ).animate().scale(delay: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Reminders Sent!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Fee reminders have been sent to ${_filteredStudents.length} students',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send bulk reminders: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } finally {
      setState(() {
        _isSendingReminders = false;
      });
    }
  }

  Future<void> _sendFeeReminder(String studentId, String studentName,
      num pendingAmount, BuildContext context) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final notificationId = FirebaseFirestore.instance
          .collection('Dummy Students')
          .doc(studentId)
          .collection('Notifications')
          .doc()
          .id;

      await FirebaseFirestore.instance
          .collection('Dummy Students')
          .doc(studentId)
          .collection('Notifications')
          .doc(notificationId)
          .set({
        'id': notificationId,
        'title': 'Fee Payment Reminder',
        'message':
            'Dear $studentName, this is a reminder that you have a pending fee balance of ₹${pendingAmount.toStringAsFixed(2)}. Please clear your dues at your earliest convenience to avoid any late payment penalties.',
        'timestamp': timestamp,
        'type': 'fee_reminder',
        'isRead': false,
        'amount': pendingAmount,
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ).animate().scale(delay: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Reminder Sent!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Fee reminder has been sent to $studentName',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reminder: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Pending Fees',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_filteredStudents.isNotEmpty && !_isSendingReminders)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _sendRemindersToAllStudents,
              tooltip: 'Send Reminders to All',
            ),
          if (_isSendingReminders)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentsWithPendingFees,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Students with Pending Fees',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_filteredStudents.length}',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideY(begin: 0.3, end: 0),
                        Text(
                          'Students',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: _isTotalVisible
                                  ? Text(
                                      '₹${_totalPendingAmount.toStringAsFixed(2)}',
                                      key: const ValueKey<bool>(true),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      '₹ *****',
                                      key: const ValueKey<bool>(false),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _toggleTotalVisibility,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _isTotalVisible ? 'Hide' : 'View',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate(delay: 400.ms)
                            .fadeIn()
                            .slideY(begin: 0.3, end: 0),
                        Text(
                          'Total Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(delay: 200.ms),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID, division, roll no, or TG',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStudents();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[400],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : _buildStudentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final pendingAmount = student['pendingFees'] as num;
        final isHighAmount = pendingAmount > 5000;

        final baseColor = isHighAmount
            ? Color(0xFFE57373)
            : Color(0xFF81C784);

        final cardBackground = isHighAmount
            ? Color(0xFFFFF8F8)
            : Color(0xFFF8FFF8);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: baseColor.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          color: cardBackground,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        student['name'].toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          letterSpacing: 0.2,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: baseColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: baseColor.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '₹${pendingAmount.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          color: isHighAmount
                              ? Color(0xFFD32F2F)
                              : Color(0xFF388E3C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  color: baseColor.withOpacity(0.2),
                  thickness: 0.8,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoChip(
                      context,
                      'Div: ${student['division'] ?? 'N/A'}',
                      Color(0xFF5C6BC0),
                    ),
                    _buildInfoChip(
                      context,
                      'Roll: ${student['rollNo'] ?? 'N/A'}',
                      Color(0xFF7986CB),
                    ),
                    _buildInfoChip(
                      context,
                      'TG: ${student['tg'] ?? 'N/A'}',
                      Color(0xFF9575CD),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _sendFeeReminder(student['id'],
                          student['name'], pendingAmount, context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: baseColor.withOpacity(0.1),
                      ),
                      icon: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: isHighAmount
                            ? Color(0xFFC62828)
                            : Color(0xFF2E7D32),
                      ),
                      label: Text(
                        'Send Reminder',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isHighAmount
                              ? Color(0xFFC62828)
                              : Color(0xFF2E7D32),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(
                duration: 400.ms,
                delay: 80.ms * index,
                curve: Curves.easeOutQuad)
            .slideX(
                begin: 0.1,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[300],
          )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 600.ms)
              .then(delay: 200.ms)
              .fadeOut(duration: 600.ms),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _searchController.text.isEmpty
                  ? 'No students with pending fees'
                  : 'No matching students found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().scale().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}