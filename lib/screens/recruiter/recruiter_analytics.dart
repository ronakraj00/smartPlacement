import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Premium analytics dashboard for recruiters.
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
          // Greeting Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${user.name}!',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text(user.companyName ?? 'Recruiter',
                          style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Job stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').where('recruiterId', isEqualTo: user.id).snapshots(),
            builder: (context, jobSnap) {
              if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator());
              final jobs = jobSnap.data!.docs.map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

              int activeJobs = jobs.where((j) => j.status == 'approved').length;
              int pendingJobs = jobs.where((j) => j.status == 'pending').length;
              int rejectedJobs = jobs.where((j) => j.status == 'rejected_by_admin').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Overview', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statCard('Active', '$activeJobs', AppTheme.success, Icons.check_circle_rounded),
                      const SizedBox(width: 10),
                      _statCard('Pending', '$pendingJobs', AppTheme.warning, Icons.pending_rounded),
                      const SizedBox(width: 10),
                      _statCard('Rejected', '$rejectedJobs', AppTheme.error, Icons.cancel_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pipeline overview
                  if (jobs.where((j) => j.status == 'approved').isNotEmpty) ...[
                    Text('Pipeline Overview', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    ...jobs.where((j) => j.status == 'approved').map((job) => _buildJobPipelineCard(context, job)),
                  ],

                  // Offers Summary
                  const SizedBox(height: 8),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('offers').get(),
                    builder: (context, offerSnap) {
                      if (!offerSnap.hasData) return const SizedBox.shrink();
                      final myJobIds = jobs.map((j) => j.id).toSet();
                      final myOffers = offerSnap.data!.docs.where((d) => myJobIds.contains((d.data() as Map)['jobId'])).toList();
                      if (myOffers.isEmpty) return const SizedBox.shrink();

                      int pending = myOffers.where((d) => (d.data() as Map)['status'] == 'pending').length;
                      int accepted = myOffers.where((d) => (d.data() as Map)['status'] == 'accepted').length;
                      int declined = myOffers.where((d) => (d.data() as Map)['status'] == 'declined').length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Offers Summary', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statCard('Pending', '$pending', AppTheme.warning, Icons.schedule_rounded),
                              const SizedBox(width: 10),
                              _statCard('Accepted', '$accepted', AppTheme.success, Icons.thumb_up_rounded),
                              const SizedBox(width: 10),
                              _statCard('Declined', '$declined', AppTheme.error, Icons.thumb_down_rounded),
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

  Widget _buildJobPipelineCard(BuildContext context, JobModel job) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('applications').where('jobId', isEqualTo: job.id).get(),
      builder: (context, appSnap) {
        if (!appSnap.hasData) return const SizedBox.shrink();
        final apps = appSnap.data!.docs;
        int total = apps.length;
        int rejected = apps.where((a) => (a.data() as Map)['status'] == 'Rejected').length;
        int active = total - rejected;
        double progress = total > 0 ? active / total : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(job.company[0], style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.role, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${job.location} • ${job.jobType}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Text('$total apps', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppTheme.success,
                  backgroundColor: AppTheme.error.withAlpha(30),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _miniLabel('Active', '$active', AppTheme.success),
                  const Spacer(),
                  _miniLabel('Rejected', '$rejected', AppTheme.error),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }

  Widget _miniLabel(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label: $value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
