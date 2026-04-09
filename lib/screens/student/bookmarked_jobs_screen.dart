import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import '../shared/company_profile_screen.dart';

/// Bookmarked/Saved jobs screen for students.
class BookmarkedJobsScreen extends StatelessWidget {
  const BookmarkedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const Center(child: Text('Not logged in.'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookmarks')
          .where('userId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, bookmarkSnap) {
        if (bookmarkSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookmarks = bookmarkSnap.data?.docs ?? [];
        if (bookmarks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No saved jobs yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('Tap the bookmark icon on any job to save it for later.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        final jobIds = bookmarks.map((b) => (b.data() as Map<String, dynamic>)['jobId'] as String).toList();

        return FutureBuilder<List<JobModel>>(
          future: _fetchJobs(jobIds),
          builder: (context, jobSnap) {
            if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator());
            final jobs = jobSnap.data!;
            if (jobs.isEmpty) return const Center(child: Text('Saved jobs were removed.'));

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CompanyProfileScreen(companyName: job.company),
                    )),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.withAlpha(20),
                      child: Text(job.company[0].toUpperCase(), style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(job.role, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} • ${job.location} • ${job.salary}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                      onPressed: () => _removeBookmark(user.id, job.id),
                      tooltip: 'Remove bookmark',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<JobModel>> _fetchJobs(List<String> jobIds) async {
    List<JobModel> jobs = [];
    for (var id in jobIds) {
      final doc = await FirebaseFirestore.instance.collection('jobs').doc(id).get();
      if (doc.exists) {
        jobs.add(JobModel.fromMap(doc.data()!, doc.id));
      }
    }
    return jobs;
  }

  static Future<void> _removeBookmark(String userId, String jobId) async {
    final snap = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  /// Static helper to toggle bookmark from job cards.
  static Future<void> toggleBookmark(String userId, String jobId) async {
    final snap = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .get();
    if (snap.docs.isNotEmpty) {
      for (var doc in snap.docs) {
        await doc.reference.delete();
      }
    } else {
      await FirebaseFirestore.instance.collection('bookmarks').add({
        'userId': userId,
        'jobId': jobId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Check if a job is bookmarked
  static Future<bool> isBookmarked(String userId, String jobId) async {
    final snap = await FirebaseFirestore.instance
        .collection('bookmarks')
        .where('userId', isEqualTo: userId)
        .where('jobId', isEqualTo: jobId)
        .get();
    return snap.docs.isNotEmpty;
  }
}
