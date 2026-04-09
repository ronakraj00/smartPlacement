import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const Center(child: Text("Not logged in."));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.id)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No notifications yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final body = data['body'] ?? '';
            final type = data['type'] ?? '';
            final isRead = data['read'] ?? false;
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null
                ? _formatTime(createdAt.toDate())
                : '';

            IconData icon;
            Color iconColor;
            switch (type) {
              case 'status_change':
                icon = Icons.update;
                iconColor = Colors.blue;
                break;
              case 'interview':
                icon = Icons.event;
                iconColor = Colors.orange;
                break;
              case 'job_approved':
                icon = Icons.check_circle;
                iconColor = Colors.green;
                break;
              case 'account_approved':
                icon = Icons.verified_user;
                iconColor = Colors.teal;
                break;
              default:
                icon = Icons.notifications;
                iconColor = Colors.deepPurple;
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: isRead ? null : Colors.deepPurple.withOpacity(0.05),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor),
                ),
                title: Text(title, style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                )),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(body),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  // Mark as read on tap
                  if (!isRead) {
                    docs[index].reference.update({'read': true});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
