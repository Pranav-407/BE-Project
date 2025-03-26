import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailsScreen extends StatefulWidget {
  
  final Map<String, dynamic> studentData;

  const StudentDetailsScreen({super.key,required this.studentData});
   
  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  // Function to make a phone call
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $phoneNumber');
    }
  }
  
  // Function to open WhatsApp chat
  Future<void> openWhatsAppChat(String phoneNumber) async {
    // Format phone number for WhatsApp (add country code if needed)
    String formattedNumber = phoneNumber;
    if (!phoneNumber.startsWith('91')) {
      formattedNumber = '91$phoneNumber';
    }
    
    final Uri whatsappUri = Uri.parse('https://api.whatsapp.com/send?phone=$formattedNumber');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch WhatsApp for $phoneNumber');
    }
  }
  
  @override
  void initState() {
    log(widget.studentData.toString());
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Student Info',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0,vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStudentHeader(context),
                const SizedBox(height: 24),
                _buildInfoCard(
                  context,
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoRow('Name', widget.studentData['name'], context: context),
                    _buildInfoRow('Roll No', widget.studentData['rollNo'], context: context),
                    _buildInfoRow('PRN', widget.studentData['PRN'], context: context),
                    _buildInfoRow('Student UID', widget.studentData['UID'], context: context),
                    _buildInfoRow('Email', widget.studentData['Email'], context: context),
                    _buildInfoRow('Sinhgad Email', widget.studentData['SinhgadEmail'], context: context),
                    _buildInfoRow('Address', widget.studentData['permanentAddress'], context: context),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Contact Information',
                  icon: Icons.phone_outlined,
                  children: [
                    _buildInfoRow('Mobile No', widget.studentData['mobileNo'], isPhone: true, context: context),
                    _buildInfoRow('Parent\'s Mobile', widget.studentData['parentMobNo'], isPhone: true, context: context),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Academic Information',
                  icon: Icons.school_outlined,
                  children: [
                    _buildInfoRow('Division', widget.studentData['division'], context: context),
                    _buildInfoRow('Class Teacher', widget.studentData['ct'], context: context),
                    _buildInfoRow('Teacher Guardian', widget.studentData['tg'], context: context),
                    _buildInfoRow('TG Batch', widget.studentData['tgBatch'] ?? 'Not Available', context: context),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Financial Information',
                  icon: Icons.account_balance_wallet_outlined,
                  children: [
                    _buildInfoRow('Pending Fees', '₹${widget.studentData['pendingFees']}', context: context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            child: Text(
              widget.studentData['name'].toString().substring(0, 1),
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.studentData['name'],
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Roll No: ${widget.studentData['rollNo']}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.studentData['division']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isPhone = false, required BuildContext context}) {
    // Check if it's a valid phone number (simple validation)
    bool isValidPhone = isPhone && 
                         value != null && 
                         value != 'Not Available' &&
                         value.length >= 10;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value ?? 'Not Available',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: value != null && value != 'Not Available' ? FontWeight.w500 : FontWeight.normal,
                    color: value != null && value != 'Not Available' ? Colors.grey[800] : Colors.grey[500],
                  ),
                ),
                if (isValidPhone)
                  Row(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.call, color: Theme.of(context).primaryColor),
                        onPressed: () => makePhoneCall(value),
                        tooltip: 'Call',
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/images/whatsapp_icon.png', 
                          width: 24, 
                          height: 24,
                        ),
                        onPressed: () => openWhatsAppChat(value),
                        tooltip: 'WhatsApp',
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}