import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentNotificationsScreen extends StatefulWidget {
  final String studentId;

  const StudentNotificationsScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Dummy Students')
                .doc(widget.studentId)
                .collection('Notifications')
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mark_email_read),
                    onPressed: unreadCount > 0 ? _markAllAsRead : null,
                    tooltip: 'Mark all as read',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification header with animation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Activity Center',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay updated with important announcements and reminders',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0, duration: 400.ms),

          // Notifications stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Dummy Students')
                  .doc(widget.studentId)
                  .collection('Notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Process the notifications for batch reads
                _processUnreadNotifications(docs);

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildNotificationCard(data, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _processUnreadNotifications(List<QueryDocumentSnapshot> docs) {
    // Batch update to mark notifications as read when viewed
    final batch = FirebaseFirestore.instance.batch();
    bool hasUnread = false;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] == false) {
        hasUnread = true;
        batch.update(doc.reference, {'isRead': true});
      }
    }

    // Only commit the batch if there are unread notifications
    if (hasUnread) {
      batch.commit();
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Dummy Students')
          .doc(widget.studentId)
          .collection('Notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_notifications.png', // Add this image to your assets
            width: 150,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image is not available
              return Icon(
                Icons.notifications_off_outlined,
                size: 80,
                color: Colors.grey[300],
              );
            },
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fade(begin: 0.7, end: 1.0, duration: 1500.ms),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'All Caught Up!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have no notifications at the moment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().scale(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, int index) {
    final timestamp = data['timestamp'] as Timestamp?;
    final dateTime = timestamp?.toDate();
    final timeString = dateTime != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(dateTime)
        : 'Unknown time';

    final isRead = data['isRead'] ?? true;
    final notificationType = data['type'] ?? 'general';

    // Determine notification styling based on type
    NotificationStyle style = _getNotificationStyle(notificationType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead ? Colors.transparent : style.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isRead ? Colors.white : style.color.withOpacity(0.05),
        ),
        child: Column(
          children: [
            // Notification header with icon and time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    style.icon,
                    color: style.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    data['title'] ?? 'Notification',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: style.color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: style.color.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isRead ? 'Read' : 'New',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: style.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Notification content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['message'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeString,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),

                  // Fee reminder specific content
                  if (notificationType == 'fee_reminder' &&
                      data['amount'] != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            style.color.withOpacity(0.1),
                            style.color.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: style.color.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Amount Due:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '₹${(data['amount'] as num).toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: style.color,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              // Change the app package name to your college app's package
                              final String collegeAppPackage =
                                  'com.aspire.aspire_app_sinhagadinstitute';
                              final String playStoreUrl =
                                  'https://play.google.com/store/apps/details?id=$collegeAppPackage';

                              try {
                                // Try to launch the college app directly (this URI scheme works for Android)
                                final Uri appUri = Uri.parse(
                                    'android-app://$collegeAppPackage');
                                bool launched = await launchUrl(
                                  appUri,
                                  mode: LaunchMode.externalApplication,
                                );

                                if (!launched) {
                                  // If app can't be launched, open Play Store
                                  if (context.mounted) {
                                    final Uri storeUri =
                                        Uri.parse(playStoreUrl);
                                    await launchUrl(
                                      storeUri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                }
                              } catch (e) {
                                // Fallback to Play Store if there's any error
                                if (context.mounted) {
                                  try {
                                    final Uri storeUri =
                                        Uri.parse(playStoreUrl);
                                    await launchUrl(
                                      storeUri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } catch (storeError) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Unable to open the College app or Play Store')),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: style.color,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.school,
                                    size: 18), // Changed to school icon
                                const SizedBox(width: 8),
                                Text(
                                  'Pay Now', // Changed button text
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 50.ms * index)
        .slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  // Helper class for notification styling
  NotificationStyle _getNotificationStyle(String type) {
    switch (type) {
      case 'fee_reminder':
        return NotificationStyle(
          icon: Icons.account_balance_wallet,
          color: Colors.orange[700]!,
        );
      case 'assignment':
        return NotificationStyle(
          icon: Icons.assignment,
          color: Colors.blue[600]!,
        );
      case 'exam':
        return NotificationStyle(
          icon: Icons.school,
          color: Colors.purple[600]!,
        );
      case 'important':
        return NotificationStyle(
          icon: Icons.warning,
          color: Colors.red[600]!,
        );
      default:
        return NotificationStyle(
          icon: Icons.notifications,
          color: Colors.teal[600]!,
        );
    }
  }
}

// Helper class for notification styling
class NotificationStyle {
  final IconData icon;
  final Color color;

  NotificationStyle({
    required this.icon,
    required this.color,
  });
}

// --------- NOTIFICATION BADGE FOR STUDENT DASHBOARD ---------

class NotificationBadge extends StatelessWidget {
  final String studentId;
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.studentId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Dummy Students')
          .doc(studentId)
          .collection('Notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.length;
        }

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: onTap,
              tooltip: 'Notifications',
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(delay: 300.ms)
                  .then(delay: 200.ms)
                  .shake(duration: 400.ms, offset: const Offset(0, 1)),
          ],
        );
      },
    );
  }
}
