import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class UploadFeeExcel extends StatefulWidget {
  const UploadFeeExcel({super.key});

  @override
  State<UploadFeeExcel> createState() => _UploadFeeExcelState();
}

class _UploadFeeExcelState extends State<UploadFeeExcel> with SingleTickerProviderStateMixin {
  String? _fileName;
  bool _isLoading = false;
  bool _isUploading = false;
  List<Map<String, dynamic>>? _processedData;
  late AnimationController _animationController;
  bool _showSuccess = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickExcelFile() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        setState(() => _fileName = result.files.first.name);

        final file = File(result.files.first.path!);
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        _processedData = _processExcelData(excel);
        setState(() {});
      }
    } catch (e) {
      _showCustomSnackBar('Error reading file: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _processExcelData(Excel excel) {
    final sheet = excel.tables[excel.tables.keys.first]!;
    final rows = sheet.rows;
    
    // Skip the first two rows (title and date) and start from the header row
    if (rows.length < 4) return []; // Ensure we have enough rows
    
    final processedData = <Map<String, dynamic>>[];
    
    // Start from row 4 (index 3) which contains actual data
    for (var i = 3; i < rows.length; i++) {
      final row = rows[i];
      
      // Get student name with ID from column B (index 1)
      final studentNameWithId = row[1]?.value?.toString() ?? '';
      // Get pending fee from column C (index 2)
      final pendingFees = row[2]?.value?.toString() ?? '0';
      
      if (studentNameWithId.isNotEmpty) {
        processedData.add({
          'studentInfo': studentNameWithId,
          'pendingFees': pendingFees,
        });
      }
    }
    
    return processedData;
  }

  Future<void> _storeDataInFirestore() async {
    if (_processedData == null || _processedData!.isEmpty) {
      _showCustomSnackBar('No data to process', isError: true);
      return;
    }

    setState(() {
      _isUploading = true;
      _showSuccess = false;
    });
    
    final firestore = FirebaseFirestore.instance;
    int successCount = 0;
    int notFoundCount = 0;

    try {
      for (var data in _processedData!) {
        final studentInfo = data['studentInfo'] as String;
        final parts = studentInfo.split('/');
        
        if (parts.length >= 2) {
          // Extract the document ID (e.g., 2324-VSKN-12596)
          final idParts = parts.sublist(1);
          final documentId = idParts.join('-');
          
          final docRef = firestore.collection('Dummy Students').doc(documentId);
          
          // Check if document exists
          final docSnapshot = await docRef.get();
          
          if (docSnapshot.exists) {
            // Update only pending fees for existing document
            final pendingFees = double.tryParse(data['pendingFees'].toString()) ?? 0;
            await docRef.update({
              'pendingFees': pendingFees,
            });
            successCount++;
          } else {
            notFoundCount++;
          }
        }
      }

      setState(() {
        _showSuccess = true;
        _animationController.forward();
      });
      
      _showCustomSnackBar(
        'Successfully updated fees for $successCount students. $notFoundCount students not found.',
        duration: 4
      );
    } catch (e) {
      _showCustomSnackBar('Error updating fees: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }
  
  void _showCustomSnackBar(String message, {bool isError = false, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade700,
        duration: Duration(seconds: duration),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Update Student Fees',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
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
                          primaryColor.withOpacity(0.7),
                          primaryColor.withOpacity(0.5),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30, top: 20),
                      child: Icon(
                        Icons.description,
                        color: Colors.white.withOpacity(0.3),
                        size: 100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    _buildFileSelectionCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFileSelectionCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_showSuccess)
              Lottie.network(
                'https://assets7.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                height: 150,
                controller: _animationController,
              )
            else
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _fileName == null ? Icons.upload_file : Icons.description,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              _fileName == null ? 'No File Selected' : 'File Selected',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description,
                        size: 16,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fileName!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (_isLoading)
              Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Processing Excel File...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickExcelFile,
                    icon: const Icon(Icons.file_upload),
                    label: Text(
                      _fileName == null ? 'Select Excel File' : 'Change File',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                    ),
                  ),
                  if (_processedData != null && !_isUploading) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _storeDataInFirestore,
                      icon: const Icon(Icons.cloud_upload),
                      label: Text(
                        'Update Fees',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: null,
                      icon: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      label: Text(
                        'Uploading...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ],
              ),
            if (_processedData != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  '${_processedData!.length} students found in file',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}