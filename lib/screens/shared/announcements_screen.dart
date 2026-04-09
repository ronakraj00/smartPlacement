import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcement_model.dart';
import '../../services/auth_service.dart';

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
          title: const Text('New Announcement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyC,
                  decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                  ],
                  onChanged: (v) => setState(() => priority = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: target,
                  decoration: const InputDecoration(labelText: 'Target Audience', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(value: 'students', child: Text('Students Only')),
                    DropdownMenuItem(value: 'recruiters', child: Text('Recruiters Only')),
                  ],
                  onChanged: (v) => setState(() => target = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attachC,
                  decoration: const InputDecoration(labelText: 'Attachment URLs (comma separated)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement published!')),
                  );
                }
              },
              child: const Text('Publish'),
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
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }

          // Filter by target audience
          final filtered = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final target = data['targetAudience'] ?? 'all';
            if (target == 'all') return true;
            if (target == 'students' && role == 'student') return true;
            if (target == 'recruiters' && role == 'recruiter') return true;
            if (isAdmin) return true; // admin sees all
            return false;
          }).toList();

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final a = AnnouncementModel.fromMap(
                  filtered[index].data() as Map<String, dynamic>, filtered[index].id);
              bool isUrgent = a.priority == 'urgent';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: isUrgent ? Colors.red.withAlpha(15) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isUrgent ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUrgent) ...[
                            const Icon(Icons.priority_high, color: Colors.red, size: 20),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(a.title, style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold,
                              color: isUrgent ? Colors.red : null,
                            )),
                          ),
                          Chip(
                            label: Text(a.targetAudience.toUpperCase(), style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.body),
                      if (a.attachmentUrls.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: a.attachmentUrls.map((url) => ActionChip(
                            avatar: const Icon(Icons.attach_file, size: 16),
                            label: const Text('Attachment', style: TextStyle(fontSize: 12)),
                            onPressed: () => launchUrl(Uri.parse(url)),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('By ${a.createdBy} • ${_timeAgo(a.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
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
