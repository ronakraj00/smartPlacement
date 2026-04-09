import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.notifications_off_rounded, size: 40, color: AppTheme.primary.withAlpha(100)),
                ),
                const SizedBox(height: 16),
                Text('All quiet', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                const Text('No notifications yet.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final body = data['body'] ?? '';
            final type = data['type'] ?? '';
            final isRead = data['read'] ?? false;
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null ? _formatTime(createdAt.toDate()) : '';

            final config = _notifConfig(type);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: InkWell(
                onTap: () {
                  if (!isRead) docs[index].reference.update({'read': true});
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : config.color.withAlpha(8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isRead ? AppTheme.dividerColor : config.color.withAlpha(40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [config.color.withAlpha(25), config.color.withAlpha(12)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(config.icon, color: config.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(title,
                                      style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 14)),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(color: config.color, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(body, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3)),
                            if (timeStr.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(timeStr, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withAlpha(150))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  _NotifConfig _notifConfig(String type) {
    switch (type) {
      case 'status_change': return _NotifConfig(Icons.swap_horiz_rounded, AppTheme.info);
      case 'interview': return _NotifConfig(Icons.videocam_rounded, AppTheme.warning);
      case 'offer': return _NotifConfig(Icons.card_giftcard_rounded, AppTheme.success);
      case 'job_approved': return _NotifConfig(Icons.check_circle_rounded, AppTheme.success);
      case 'account_approved': return _NotifConfig(Icons.verified_rounded, AppTheme.secondary);
      default: return _NotifConfig(Icons.notifications_rounded, AppTheme.primary);
    }
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

class _NotifConfig {
  final IconData icon;
  final Color color;
  _NotifConfig(this.icon, this.color);
}
