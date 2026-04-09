import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';

/// Analytics widget shown at the top of recruiter dashboard.
class RecruiterAnalytics extends StatelessWidget {
  const RecruiterAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome, ${user.name}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.companyName ?? 'Recruiter', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          // Stats Row
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('recruiterId', isEqualTo: user.id)
                .snapshots(),
            builder: (context, jobSnap) {
              if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator());
              final jobs = jobSnap.data!.docs.map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

              int activeJobs = jobs.where((j) => j.status == 'approved').length;
              int pendingJobs = jobs.where((j) => j.status == 'pending').length;
              int rejectedJobs = jobs.where((j) => j.status == 'rejected_by_admin').length;

              return Column(
                children: [
                  // Top stats
                  Row(
                    children: [
                      Expanded(child: _statCard('Active Jobs', '$activeJobs', Colors.green, Icons.check_circle)),
                      const SizedBox(width: 8),
                      Expanded(child: _statCard('Pending', '$pendingJobs', Colors.orange, Icons.pending)),
                      const SizedBox(width: 8),
                      Expanded(child: _statCard('Rejected', '$rejectedJobs', Colors.red, Icons.cancel)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Per-job pipeline stats
                  const Text('Job Pipeline Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...jobs.where((j) => j.status == 'approved').map((job) {
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('applications')
                          .where('jobId', isEqualTo: job.id)
                          .get(),
                      builder: (context, appSnap) {
                        if (!appSnap.hasData) return const SizedBox.shrink();
                        final apps = appSnap.data!.docs;
                        int total = apps.length;
                        int rejected = apps.where((a) => (a.data() as Map)['status'] == 'Rejected').length;
                        int inProgress = total - rejected;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('${job.company} • ${job.location}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _miniStat('Total', '$total', Colors.blue),
                                    const SizedBox(width: 16),
                                    _miniStat('Active', '$inProgress', Colors.green),
                                    const SizedBox(width: 16),
                                    _miniStat('Rejected', '$rejected', Colors.red),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? inProgress / total : 0,
                                    minHeight: 6,
                                    color: Colors.green,
                                    backgroundColor: Colors.red.withAlpha(80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  const SizedBox(height: 16),

                  // Offers extended
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('offers')
                        .get(),
                    builder: (context, offerSnap) {
                      if (!offerSnap.hasData) return const SizedBox.shrink();
                      final myJobIds = jobs.map((j) => j.id).toSet();
                      final myOffers = offerSnap.data!.docs
                          .where((d) => myJobIds.contains((d.data() as Map)['jobId']))
                          .toList();
                      int pendingOffers = myOffers.where((d) => (d.data() as Map)['status'] == 'pending').length;
                      int acceptedOffers = myOffers.where((d) => (d.data() as Map)['status'] == 'accepted').length;
                      int declinedOffers = myOffers.where((d) => (d.data() as Map)['status'] == 'declined').length;

                      if (myOffers.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Offers Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _statCard('Pending', '$pendingOffers', Colors.orange, Icons.pending)),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Accepted', '$acceptedOffers', Colors.green, Icons.thumb_up)),
                              const SizedBox(width: 8),
                              Expanded(child: _statCard('Declined', '$declinedOffers', Colors.red, Icons.thumb_down)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Card(
      color: color.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label: $value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
