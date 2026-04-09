import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../student/notifications_screen.dart';

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
        title: Text(_bottomIndex == 0 ? 'Recruiter Dashboard' : 'Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthService>().signOut(),
          )
        ],
      ),
      floatingActionButton: (_bottomIndex != 0 || isPendingAccount)
          ? null
          : FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => context.push('/job-creation'),
            ),
      body: _bottomIndex == 0
          ? _buildDashboard(context, user, isPendingAccount)
          : const NotificationsScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomIndex,
        onTap: (i) => setState(() => _bottomIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic user, bool isPendingAccount) {
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (isPendingAccount)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Pending Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('The placement cell admin needs to verify your account before you can post jobs.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: isPendingAccount
              ? const Center(child: Text('Waiting for admin approval...'))
              : StreamBuilder<QuerySnapshot>(
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
                      return const Center(child: Text('No jobs posted yet.\nTap + to create one!'));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final job = JobModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
                        bool isPending = job.status.toLowerCase() == 'pending';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isPending ? null : () => context.push('/applicants/${job.id}'),
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
                                      Chip(
                                        label: Text(
                                          isPending ? 'PENDING' : 'ACTIVE',
                                          style: TextStyle(color: isPending ? Colors.black : Colors.white, fontSize: 10),
                                        ),
                                        backgroundColor: isPending ? Colors.amberAccent : Colors.green,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _infoTag(Icons.work_outline, job.jobType.isNotEmpty ? job.jobType : 'N/A'),
                                      const SizedBox(width: 12),
                                      _infoTag(Icons.location_on, job.location.isNotEmpty ? job.location : 'N/A'),
                                      const SizedBox(width: 12),
                                      _infoTag(Icons.people, '${job.rounds.length} rounds'),
                                    ],
                                  ),
                                  if (job.deadline != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Deadline: ${job.deadline!.day}/${job.deadline!.month}/${job.deadline!.year}${job.isExpired ? " (CLOSED)" : ""}',
                                      style: TextStyle(fontSize: 12, color: job.isExpired ? Colors.red : Colors.grey),
                                    ),
                                  ],

                                  if (!isPending) ...[
                                    const Divider(height: 20),
                                    // Per-job pipeline stats
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
                ),
        ),
      ],
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

/// Shows a compact row of pipeline stats per job (e.g., Applied: 5, Interview: 2, etc.)
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
