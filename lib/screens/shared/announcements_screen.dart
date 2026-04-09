import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcement_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AnnouncementsScreen extends StatelessWidget {
  final bool isAdmin;
  const AnnouncementsScreen({super.key, this.isAdmin = false});

  void _showCreateDialog(BuildContext context) {
    final titleC = TextEditingController();
    final bodyC = TextEditingController();
    final attachC = TextEditingController();
    String priority = 'normal';
    String target = 'all';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('New Announcement'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title))),
                const SizedBox(height: 12),
                TextField(controller: bodyC, decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true), maxLines: 4),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority', prefixIcon: Icon(Icons.flag_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                  ],
                  onChanged: (v) => setState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: target,
                  decoration: const InputDecoration(labelText: 'Target Audience', prefixIcon: Icon(Icons.groups_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(value: 'students', child: Text('Students Only')),
                    DropdownMenuItem(value: 'recruiters', child: Text('Recruiters Only')),
                  ],
                  onChanged: (v) => setState(() => target = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: attachC, decoration: const InputDecoration(labelText: 'Attachment URLs (comma separated)', prefixIcon: Icon(Icons.attach_file))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleC.text.isEmpty || bodyC.text.isEmpty) return;
                final user = context.read<AuthService>().currentUser;
                final attachments = attachC.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await FirebaseFirestore.instance.collection('announcements').add({
                  'title': titleC.text,
                  'body': bodyC.text,
                  'priority': priority,
                  'targetAudience': target,
                  'attachmentUrls': attachments,
                  'createdBy': user?.name ?? 'Admin',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement published!')));
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final role = user?.role.toString().split('.').last ?? 'student';

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(onPressed: () => _showCreateDialog(context), child: const Icon(Icons.add))
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: AppTheme.primary.withAlpha(12), borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.campaign_rounded, size: 40, color: AppTheme.primary.withAlpha(100)),
                  ),
                  const SizedBox(height: 16),
                  Text('No announcements', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('Check back soon for updates.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final target = data['targetAudience'] ?? 'all';
            if (target == 'all') return true;
            if (target == 'students' && role == 'student') return true;
            if (target == 'recruiters' && role == 'recruiter') return true;
            if (isAdmin) return true;
            return false;
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final a = AnnouncementModel.fromMap(filtered[index].data() as Map<String, dynamic>, filtered[index].id);
              bool isUrgent = a.priority == 'urgent';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isUrgent ? AppTheme.error.withAlpha(80) : AppTheme.dividerColor, width: isUrgent ? 1.5 : 1),
                  boxShadow: isUrgent ? [BoxShadow(color: AppTheme.error.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Urgent ribbon
                    if (isUrgent)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.error.withAlpha(20), AppTheme.error.withAlpha(8)]),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                        ),
                        child: const Center(
                          child: Text('🔴 URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.error, letterSpacing: 1)),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: (isUrgent ? AppTheme.error : AppTheme.primary).withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(isUrgent ? Icons.warning_rounded : Icons.campaign_rounded,
                                    size: 18, color: isUrgent ? AppTheme.error : AppTheme.primary),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(a.title, style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: isUrgent ? AppTheme.error : AppTheme.textPrimary,
                                )),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withAlpha(10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(a.targetAudience.toUpperCase(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 0.5)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(a.body, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),

                          if (a.attachmentUrls.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: a.attachmentUrls.map((url) => ActionChip(
                                avatar: const Icon(Icons.attach_file_rounded, size: 14),
                                label: const Text('Attachment', style: TextStyle(fontSize: 12)),
                                onPressed: () => launchUrl(Uri.parse(url)),
                              )).toList(),
                            ),
                          ],

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary.withAlpha(150)),
                              const SizedBox(width: 4),
                              Text(a.createdBy, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withAlpha(150))),
                              const Spacer(),
                              Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary.withAlpha(150)),
                              const SizedBox(width: 4),
                              Text(_timeAgo(a.createdAt), style: TextStyle(fontSize: 11, color: AppTheme.textSecondary.withAlpha(150))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
