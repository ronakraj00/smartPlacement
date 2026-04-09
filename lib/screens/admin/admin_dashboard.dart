import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_helper.dart';
import '../../services/seed_data_service.dart';
import 'placement_settings_screen.dart';
import '../shared/announcements_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _approveJob(BuildContext context, JobModel job) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({'status': 'approved'});
      await NotificationHelper.onJobApproved(recruiterId: job.recruiterId, jobTitle: '${job.role} at ${job.company}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job approved!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _rejectJob(BuildContext context, String jobId) async {
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'rejected_by_admin'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job rejected.')));
    }
  }

  void _approveRecruiter(BuildContext context, String recruiterId, String recruiterName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(recruiterId).update({'accountStatus': 'approved'});
      await NotificationHelper.onRecruiterApproved(recruiterId: recruiterId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$recruiterName verified!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Placement Cell Admin'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.science),
              tooltip: 'Test Data',
              onSelected: (val) async {
                if (val == 'seed') {
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  await SeedDataService.seedAll();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Test data seeded!')));
                } else if (val == 'clear') {
                  showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                  await SeedDataService.clearAll();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Test data cleared.')));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'seed', child: Text('🌱 Seed Test Data')),
                const PopupMenuItem(value: 'clear', child: Text('🗑️ Clear Test Data')),
              ],
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => context.read<AuthService>().signOut()),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Analytics"),
              Tab(text: "Pending Jobs"),
              Tab(text: "Recruiters"),
              Tab(text: "All Users"),
              Tab(text: "Announcements"),
              Tab(text: "Settings"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnalyticsTab(),
            _buildJobApprovalsTab(),
            _buildRecruiterApprovalsTab(),
            _buildUsersTab(),
            const AnnouncementsScreen(isAdmin: true),
            const PlacementSettingsScreen(),
          ],
        ),
      ),
    );
  }

  // ======================== ANALYTICS ========================
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Platform Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FutureBuilder<List<int>>(
            future: Future.wait([_getCount('users'), _getCount('jobs'), _getCount('applications'), _getCount('offers')]),
            builder: (context, snap) {
              final c = snap.data ?? [0, 0, 0, 0];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statCard('Users', '${c[0]}', Colors.blue, Icons.people),
                  _statCard('Jobs', '${c[1]}', Colors.green, Icons.work),
                  _statCard('Applications', '${c[2]}', Colors.orange, Icons.description),
                  _statCard('Offers', '${c[3]}', Colors.purple, Icons.card_giftcard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: _getPlacementMetrics(),
            builder: (context, snap) {
              final m = snap.data ?? {};
              return Row(
                children: [
                  Expanded(child: _statCard('Placement Rate', '${m['placementRate'] ?? 0}%', Colors.teal, Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Placed', '${m['placed'] ?? 0} / ${m['total'] ?? 0}', Colors.green, Icons.check_circle)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // Branch-wise stats
          const Text('Branch-wise Placement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildBranchWiseStats(),
          const SizedBox(height: 24),
          // Tier-wise stats
          const Text('Tier-wise Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTierWiseStats(),
        ],
      ),
    );
  }

  Widget _buildBranchWiseStats() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, Map<String, int>> branchStats = {};
        for (var doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final branch = data['branch'] ?? 'Unknown';
          branchStats.putIfAbsent(branch, () => {'total': 0, 'placed': 0});
          branchStats[branch]!['total'] = (branchStats[branch]!['total'] ?? 0) + 1;
          if (data['placementStatus'] == 'placed') {
            branchStats[branch]!['placed'] = (branchStats[branch]!['placed'] ?? 0) + 1;
          }
        }
        if (branchStats.isEmpty) return const Text('No data.', style: TextStyle(color: Colors.grey));
        return DataTable(
          columns: const [
            DataColumn(label: Text('Branch', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Placed', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: branchStats.entries.map((e) {
            int total = e.value['total'] ?? 0;
            int placed = e.value['placed'] ?? 0;
            String rate = total > 0 ? '${(placed / total * 100).toStringAsFixed(0)}%' : '0%';
            return DataRow(cells: [
              DataCell(Text(e.key)),
              DataCell(Text('$total')),
              DataCell(Text('$placed', style: const TextStyle(color: Colors.green))),
              DataCell(Text(rate, style: const TextStyle(fontWeight: FontWeight.bold))),
            ]);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTierWiseStats() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('offers').where('status', isEqualTo: 'accepted').get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        Map<String, int> tierCounts = {'Normal': 0, 'Dream': 0, 'Super Dream': 0};
        for (var doc in snap.data!.docs) {
          final tier = (doc.data() as Map)['tier'] ?? 'Normal';
          tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;
        }
        return Row(
          children: tierCounts.entries.map((e) {
            Color c = e.key == 'Super Dream' ? Colors.amber.shade800 : e.key == 'Dream' ? Colors.purple : Colors.blue;
            return Expanded(
              child: Card(
                color: c.withAlpha(15),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(e.key, style: TextStyle(fontWeight: FontWeight.bold, color: c)),
                      Text('${e.value}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c)),
                      Text('offers', style: TextStyle(fontSize: 12, color: c)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<int> _getCount(String col) async => (await FirebaseFirestore.instance.collection(col).get()).size;

  Future<Map<String, dynamic>> _getPlacementMetrics() async {
    try {
      final students = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get();
      int total = students.size;
      int placed = students.docs.where((d) => (d.data())['placementStatus'] == 'placed').length;
      return {'placementRate': total > 0 ? (placed / total * 100).toStringAsFixed(1) : '0', 'placed': placed, 'total': total};
    } catch (_) {
      return {'placementRate': '0', 'placed': 0, 'total': 0};
    }
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return SizedBox(
      width: 160,
      child: Card(
        color: color.withAlpha(15),
        shape: RoundedRectangleBorder(side: BorderSide(color: color, width: 1.5), borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== JOB APPROVALS ========================
  Widget _buildJobApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No pending jobs."));
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(snapshot.data!.docs[index].data() as Map<String, dynamic>, snapshot.data!.docs[index].id);
            return Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${job.role} at ${job.company}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Type: ${job.jobType} | CTC: ${job.salary} | Location: ${job.location}'),
                    Text('Min CGPA: ${job.requiredCgpa} | Branches: ${job.branchEligibility ?? "Any"}'),
                    if (job.ctcLpa > 0) Text('Numeric CTC: ${job.ctcLpa} LPA'),
                    Text('Pipeline: ${job.rounds.join(' → ')}'),
                    const SizedBox(height: 8),
                    Text(job.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _rejectJob(context, job.id),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                          child: const Text('Reject', style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _approveJob(context, job),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ======================== RECRUITER APPROVALS ========================
  Widget _buildRecruiterApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'recruiter').where('accountStatus', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No pending recruiters."));
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final r = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text(r.name[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(r.email),
                trailing: ElevatedButton(
                  onPressed: () => _approveRecruiter(context, r.id, r.name),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Verify', style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ======================== ALL USERS ========================
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        final students = users.where((u) => u.role == UserRole.student).toList();
        final recruiters = users.where((u) => u.role == UserRole.recruiter).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _userSection('Students (${students.length})', students, Colors.blue, Icons.school),
              const SizedBox(height: 16),
              _userSection('Recruiters (${recruiters.length})', recruiters, Colors.green, Icons.business),
            ],
          ),
        );
      },
    );
  }

  Widget _userSection(String title, List<UserModel> users, Color color, IconData icon) {
    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      children: users.isEmpty
          ? [const ListTile(title: Text('None'))]
          : users.map((u) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(30),
                    child: Text(u.name.isNotEmpty ? u.name[0].toUpperCase() : '?', style: TextStyle(color: color)),
                  ),
                  title: Text(u.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.email),
                      if (u.role == UserRole.student) ...[
                        Text('CGPA: ${u.cgpa ?? "N/A"} | Branch: ${u.branch ?? "N/A"} | Backlogs: ${u.activeBacklogs ?? 0}'),
                        Text('Status: ${u.placementStatus ?? "not_placed"} | Offers: ${u.offersReceived}'),
                      ],
                      if (u.role == UserRole.recruiter)
                        Text('Status: ${u.accountStatus ?? "N/A"} | Company: ${u.companyName ?? "N/A"}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }).toList(),
    );
  }
}
