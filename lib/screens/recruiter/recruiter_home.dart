import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../student/notifications_screen.dart';
import '../shared/announcements_screen.dart';
import 'recruiter_company_profile.dart';
import 'recruiter_analytics.dart';

class RecruiterHome extends StatefulWidget {
  const RecruiterHome({super.key});

  @override
  State<RecruiterHome> createState() => _RecruiterHomeState();
}

class _RecruiterHomeState extends State<RecruiterHome> {
  int _bottomIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    final isPendingAccount = user?.accountStatus == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AuthService>().signOut()),
        ],
      ),
      floatingActionButton: (_bottomIndex != 1 || isPendingAccount)
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => context.push('/job-creation'),
            ),
      body: _buildBody(context, user, isPendingAccount),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.work), label: 'My Jobs'),
          NavigationDestination(icon: Icon(Icons.business), label: 'Company'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }

  String _appBarTitle() {
    switch (_bottomIndex) {
      case 0: return 'Dashboard';
      case 1: return 'My Jobs';
      case 2: return 'Company Profile';
      case 3: return 'Announcements';
      case 4: return 'Notifications';
      default: return 'Recruiter';
    }
  }

  Widget _buildBody(BuildContext context, dynamic user, bool isPendingAccount) {
    if (isPendingAccount) {
      return _buildPendingBanner();
    }

    switch (_bottomIndex) {
      case 0: return const RecruiterAnalytics();
      case 1: return _buildJobsList(context, user);
      case 2: return const RecruiterCompanyProfile();
      case 3: return const AnnouncementsScreen();
      case 4: return const NotificationsScreen();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPendingBanner() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top, color: Colors.amber, size: 48),
            SizedBox(height: 12),
            Text('Account Pending Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('The placement cell admin needs to verify your account before you can post jobs.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsList(BuildContext context, dynamic user) {
    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('recruiterId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_off, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No jobs posted yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text('Tap + to create one!', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
            bool isPending = job.status.toLowerCase() == 'pending';
            bool isRejected = job.status == 'rejected_by_admin';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isRejected ? const BorderSide(color: Colors.red, width: 1) : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isPending || isRejected ? null : () => context.push('/applicants/${job.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.role, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                Text(job.company, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          _statusChip(job.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: [
                          _infoTag(Icons.work_outline, job.jobType.isNotEmpty ? job.jobType : 'N/A'),
                          _infoTag(Icons.location_on, job.location.isNotEmpty ? job.location : 'N/A'),
                          _infoTag(Icons.people, '${job.rounds.length} rounds'),
                          if (job.ctcLpa > 0) _infoTag(Icons.currency_rupee, '${job.ctcLpa} LPA'),
                        ],
                      ),
                      if (job.deadline != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Deadline: ${job.deadline!.day}/${job.deadline!.month}/${job.deadline!.year}${job.isExpired ? " (CLOSED)" : ""}',
                          style: TextStyle(fontSize: 12, color: job.isExpired ? Colors.red : Colors.grey),
                        ),
                      ],
                      if (!isPending && !isRejected) ...[
                        const Divider(height: 20),
                        _PipelineStatsRow(jobId: job.id, rounds: job.rounds),
                      ],
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

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'approved': color = Colors.green; label = 'ACTIVE'; break;
      case 'rejected_by_admin': color = Colors.red; label = 'REJECTED'; break;
      default: color = Colors.amber; label = 'PENDING'; break;
    }
    return Chip(
      label: Text(label, style: TextStyle(color: status == 'approved' ? Colors.white : Colors.black, fontSize: 10)),
      backgroundColor: status == 'approved' ? Colors.green : color.withAlpha(60),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

/// Shows compact pipeline stats per job.
class _PipelineStatsRow extends StatelessWidget {
  final String jobId;
  final List<String> rounds;

  const _PipelineStatsRow({required this.jobId, required this.rounds});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final apps = snapshot.data!.docs;
        Map<String, int> counts = {};
        int rejected = 0;
        for (var app in apps) {
          final status = ((app.data() as Map)['status'] ?? '').toString();
          if (status.toLowerCase() == 'rejected') {
            rejected++;
          } else {
            counts[status] = (counts[status] ?? 0) + 1;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...rounds.map((r) {
                    int count = counts[r] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: count > 0 ? Colors.deepPurple.withAlpha(20) : Colors.grey.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$r: $count', style: TextStyle(fontSize: 11, color: count > 0 ? Colors.deepPurple : Colors.grey)),
                    );
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rejected > 0 ? Colors.red.withAlpha(20) : Colors.grey.withAlpha(15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Rejected: $rejected', style: TextStyle(fontSize: 11, color: rejected > 0 ? Colors.red : Colors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('${apps.length} total applicants', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        );
      },
    );
  }
}
