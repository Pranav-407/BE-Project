// import 'dart:io';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'dart:developer';
// import 'package:permission_handler/permission_handler.dart';

// class DownloadStudentCredentials extends StatefulWidget {
//   const DownloadStudentCredentials({super.key});

//   @override
//   State<DownloadStudentCredentials> createState() => _DownloadStudentCredentialsState();
// }

// class _DownloadStudentCredentialsState extends State<DownloadStudentCredentials> {
//   bool _isLoading = false;
//   String _status = '';

//   Future<bool> _requestStoragePermission() async {
//     // For Android 11 (API level 30) and above, we need to use MANAGE_EXTERNAL_STORAGE
//     // For Android 10 (API level 29) we can use WRITE_EXTERNAL_STORAGE
//     // For older versions, WRITE_EXTERNAL_STORAGE is sufficient
    
//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       final sdkInt = androidInfo.version.sdkInt;
      
//       // Android 11+
//       if (sdkInt >= 30) {
//         if (await Permission.manageExternalStorage.status != PermissionStatus.granted) {
//           final status = await Permission.manageExternalStorage.request();
//           if (status != PermissionStatus.granted) {
//             // Show dialog explaining how to grant permission manually
//             if (context.mounted) {
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   title: const Text('Storage Permission Required'),
//                   content: const Text('This app needs storage permission to save PDFs. Please enable it in app settings.'),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel'),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         openAppSettings();
//                       },
//                       child: const Text('Open Settings'),
//                     ),
//                   ],
//                 ),
//               );
//             }
//             return false;
//           }
//         }
//       } 
//       // Android 10 or below
//       else {
//         if (await Permission.storage.status != PermissionStatus.granted) {
//           final status = await Permission.storage.request();
//           if (status != PermissionStatus.granted) {
//             if (context.mounted) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Storage permission denied'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//             return false;
//           }
//         }
//       }
//     }
    
//     return true;
//   }

//   Future<String?> _getDownloadPath() async {
//     Directory? directory;
    
//     try {
//       if (Platform.isAndroid) {
//         // Try different approaches for getting download directory
//         try {
//           // Primary approach - standard Download folder
//           directory = Directory('/storage/emulated/0/Download');
//           if (!await directory.exists()) {
//             directory = null;
//           }
//         } catch (e) {
//           log('Error accessing standard Download folder: $e');
//           directory = null;
//         }
        
//         // Fallback approaches
//         if (directory == null) {
//           try {
//             // Try the external storage directory
//             directory = await getExternalStorageDirectory();
//           } catch (e) {
//             log('Error accessing external storage: $e');
//           }
//         }
        
//         if (directory == null) {
//           // Last resort - use app documents directory
//           directory = await getApplicationDocumentsDirectory();
//         }
//       } else {
//         // For iOS
//         directory = await getApplicationDocumentsDirectory();
//       }
      
//       return directory.path;
//     } catch (e) {
//       log('Error getting download path: $e');
//       return null;
//     }
//   }

//   Future<void> _downloadStudentCredentials() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _status = 'Checking permissions...';
//       });

//       // Request storage permission
//       final hasPermission = await _requestStoragePermission();
//       if (!hasPermission) {
//         setState(() {
//           _status = 'Storage permission denied';
//           _isLoading = false;
//         });
//         return;
//       }

//       setState(() {
//         _status = 'Fetching student data...';
//       });

//       // Get student data from Firestore
//       final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('Users')
//           .where('role', isEqualTo: 'student')
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         setState(() {
//           _status = 'No student data found!';
//           _isLoading = false;
//         });
//         return;
//       }

//       setState(() {
//         _status = 'Generating PDF...';
//       });

//       // Create PDF document
//       final pdf = pw.Document();

//       // Add page with title and table
//       pdf.addPage(
//         pw.MultiPage(
//           pageFormat: PdfPageFormat.a4,
//           margin: const pw.EdgeInsets.all(32),
//           header: (pw.Context context) {
//             return pw.Header(
//               level: 0,
//               child: pw.Text(
//                 'Student Login Credentials',
//                 style: pw.TextStyle(
//                   fontSize: 20,
//                   fontWeight: pw.FontWeight.bold,
//                 ),
//               ),
//             );
//           },
//           footer: (pw.Context context) {
//             return pw.Container(
//               alignment: pw.Alignment.centerRight,
//               margin: const pw.EdgeInsets.only(top: 20),
//               child: pw.Text(
//                 'Page ${context.pageNumber} of ${context.pagesCount}',
//                 style: const pw.TextStyle(
//                   fontSize: 12,
//                 ),
//               ),
//             );
//           },
//           build: (pw.Context context) {
//             // Extract student data
//             final List<List<String>> studentData = [];
//             for (var doc in querySnapshot.docs) {
//               final data = doc.data() as Map<String, dynamic>;
//               studentData.add([
//                 data['loginID'] ?? 'N/A',
//                 data['name'] ?? 'N/A',
//                 data['password'] ?? 'N/A',
//               ]);
//             }

//             // Create table
//             return [
//               pw.Table.fromTextArray(
//                 headers: ['Login ID', 'Name', 'Password'],
//                 data: studentData,
//                 border: pw.TableBorder.all(),
//                 headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 headerDecoration: const pw.BoxDecoration(
//                   color: PdfColors.grey300,
//                 ),
//                 cellHeight: 30,
//                 cellAlignments: {
//                   0: pw.Alignment.centerLeft,
//                   1: pw.Alignment.centerLeft,
//                   2: pw.Alignment.centerLeft,
//                 },
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text(
//                 'Total Students: ${studentData.length}',
//                 style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
//               ),
//               pw.SizedBox(height: 10),
//               pw.Text(
//                 'Generated on: ${DateTime.now().toString().split('.').first}',
//                 style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
//               ),
//             ];
//           },
//         ),
//       );

//       // Save PDF to Downloads folder
//       setState(() {
//         _status = 'Saving PDF...';
//       });
      
//       final downloadPath = await _getDownloadPath();
//       if (downloadPath == null) {
//         throw Exception("Could not find a suitable download location");
//       }
      
//       final fileName = 'student_credentials_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final filePath = '$downloadPath/$fileName';
//       final file = File(filePath);
      
//       try {
//         await file.writeAsBytes(await pdf.save());
//         log('PDF saved to: $filePath');
//       } catch (e) {
//         log('Error writing file: $e');
//         throw Exception("Could not write PDF file: $e");
//       }

//       setState(() {
//         _isLoading = false;
//         _status = '';
//       });

//       // Show success message
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('PDF downloaded to $downloadPath'),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//             action: SnackBarAction(
//               label: 'Open',
//               textColor: Colors.white,
//               onPressed: () {
//                 OpenFile.open(filePath);
//               },
//             ),
//           ),
//         );
//       }

//       // Open the PDF file directly
//       await Future.delayed(const Duration(milliseconds: 500));
//       await OpenFile.open(filePath);

//     } catch (e) {
//       log('Error in download process: $e');
//       setState(() {
//         _status = 'Error: $e';
//         _isLoading = false;
//       });
      
//       // Show error snackbar
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Download Student Credentials'),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(
//                 Icons.download_rounded,
//                 size: 80,
//                 color: Colors.blue,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Download Student Credentials',
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Download all student login information as a PDF file',
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
//               if (_isLoading) ...[
//                 const CircularProgressIndicator(),
//                 const SizedBox(height: 20),
//                 Text(_status),
//               ] else
//                 ElevatedButton.icon(
//                   onPressed: _downloadStudentCredentials,
//                   icon: const Icon(Icons.download),
//                   label: const Text('Download Credentials PDF'),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                   ),
//                 ),
//               const SizedBox(height: 20),
//               if (!_isLoading && _status.isNotEmpty)
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: _status.contains('Error') ? Colors.red.shade100 : Colors.green.shade100,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     _status,
//                     style: TextStyle(
//                       color: _status.contains('Error') ? Colors.red.shade800 : Colors.green.shade800,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';

class DownloadCredentials extends StatefulWidget {
  const DownloadCredentials({super.key});

  @override
  State<DownloadCredentials> createState() => _DownloadCredentialsState();
}

class _DownloadCredentialsState extends State<DownloadCredentials> {
  bool _isLoading = false;
  String _status = '';
  String _currentOperation = '';

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      // Android 11+
      if (sdkInt >= 30) {
        if (await Permission.manageExternalStorage.status != PermissionStatus.granted) {
          final status = await Permission.manageExternalStorage.request();
          if (status != PermissionStatus.granted) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Permission Required'),
                  content: const Text('This app needs storage permission to save PDFs. Please enable it in app settings.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        openAppSettings();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
            }
            return false;
          }
        }
      } 
      // Android 10 or below
      else {
        if (await Permission.storage.status != PermissionStatus.granted) {
          final status = await Permission.storage.request();
          if (status != PermissionStatus.granted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission denied'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        }
      }
    }
    
    return true;
  }

  Future<String?> _getDownloadPath() async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        // Try different approaches for getting download directory
        try {
          // Primary approach - standard Download folder
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = null;
          }
        } catch (e) {
          log('Error accessing standard Download folder: $e');
          directory = null;
        }
        
        // Fallback approaches
        if (directory == null) {
          try {
            // Try the external storage directory
            directory = await getExternalStorageDirectory();
          } catch (e) {
            log('Error accessing external storage: $e');
          }
        }
        
        if (directory == null) {
          // Last resort - use app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // For iOS
        directory = await getApplicationDocumentsDirectory();
      }
      
      return directory.path;
    } catch (e) {
      log('Error getting download path: $e');
      return null;
    }
  }

  Future<void> _downloadCredentials(String userType) async {
    try {
      setState(() {
        _isLoading = true;
        _currentOperation = userType;
        _status = 'Checking permissions...';
      });

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        setState(() {
          _status = 'Storage permission denied';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Fetching $userType data...';
      });

      // Get user data from Firestore
      final String roleFilter = userType == 'student' ? 'student' : 'teacher';
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: roleFilter)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _status = 'No $userType data found!';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Generating PDF...';
      });

      // Create PDF document
      final pdf = pw.Document();

      // Add page with title and table
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Header(
              level: 0,
              child: pw.Text(
                '${userType.substring(0, 1).toUpperCase()}${userType.substring(1)} Login Credentials',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 12,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            // Extract user data
            final List<List<String>> userData = [];
            for (var doc in querySnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              
              // Determine ID field name based on user type
              final idField = userType == 'student' ? 'loginID' : 'loginID';
              
              userData.add([
                data[idField] ?? 'N/A',
                data['name'] ?? 'N/A',
                data['password'] ?? 'N/A',
              ]);
            }

            // Create table
            return [
              pw.Table.fromTextArray(
                headers: [
                  userType == 'student' ? 'Student ID' : 'Employee ID', 
                  'Name', 
                  'Password'
                ],
                data: userData,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total ${userType == 'student' ? 'Students' : 'Teachers'}: ${userData.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Generated on: ${DateTime.now().toString().split('.').first}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ];
          },
        ),
      );

      // Save PDF to Downloads folder
      setState(() {
        _status = 'Saving PDF...';
      });
      
      final downloadPath = await _getDownloadPath();
      if (downloadPath == null) {
        throw Exception("Could not find a suitable download location");
      }
      
      final fileName = '${userType}_credentials_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '$downloadPath/$fileName';
      final file = File(filePath);
      
      try {
        await file.writeAsBytes(await pdf.save());
        log('PDF saved to: $filePath');
      } catch (e) {
        log('Error writing file: $e');
        throw Exception("Could not write PDF file: $e");
      }

      setState(() {
        _isLoading = false;
        _status = '';
        _currentOperation = '';
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userType.substring(0, 1).toUpperCase()}${userType.substring(1)} credentials PDF downloaded to $downloadPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                OpenFile.open(filePath);
              },
            ),
          ),
        );
      }

      // Open the PDF file directly
      await Future.delayed(const Duration(milliseconds: 500));
      await OpenFile.open(filePath);

    } catch (e) {
      log('Error in download process: $e');
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
        _currentOperation = '';
      });
      
      // Show error snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Credentials'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_download_rounded,
                    size: 80,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Download Credentials',
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Download login credentials for students or teachers',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  if (_isLoading) ...[
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentOperation == 'student' ? Colors.blue : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ] else
                    Column(
                      children: [
                        DownloadCard(
                          title: 'Student Credentials',
                          description: 'Download login information for all students as PDF',
                          icon: Icons.school,
                          color: Colors.blue,
                          onPressed: () => _downloadCredentials('student'),
                        ),
                        const SizedBox(height: 20),
                        DownloadCard(
                          title: 'Teacher Credentials',
                          description: 'Download login information for all teachers as PDF',
                          icon: Icons.person,
                          color: Colors.green,
                          onPressed: () => _downloadCredentials('teacher'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  if (!_isLoading && _status.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _status.contains('Error') ? Colors.red.shade100 : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Error') ? Colors.red.shade800 : Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DownloadCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const DownloadCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: color,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download_rounded,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}