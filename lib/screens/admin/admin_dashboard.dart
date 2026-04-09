import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_helper.dart';
import '../../services/seed_data_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  void _approveJob(BuildContext context, JobModel job) async {
    try {
      await FirebaseFirestore.instance.collection('jobs').doc(job.id).update({
        'status': 'approved'
      });

      // Notify the recruiter
      await NotificationHelper.onJobApproved(
        recruiterId: job.recruiterId,
        jobTitle: '${job.role} at ${job.company}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job approved and published to eligible students!')),
        );
      }
    } catch(e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _approveRecruiter(BuildContext context, String recruiterId, String recruiterName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(recruiterId).update({
        'accountStatus': 'approved'
      });

      await NotificationHelper.onRecruiterApproved(recruiterId: recruiterId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$recruiterName has been verified!')),
        );
      }
    } catch(e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Placement Cell Admin'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.science),
              tooltip: 'Test Data',
              onSelected: (val) async {
                if (val == 'seed') {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  await SeedDataService.seedAll();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Test data seeded! Refresh screens to see.')),
                    );
                  }
                } else if (val == 'clear') {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  await SeedDataService.clearAll();
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('🗑️ Test data cleared.')),
                    );
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'seed', child: Text('🌱 Seed Test Data')),
                const PopupMenuItem(value: 'clear', child: Text('🗑️ Clear Test Data')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthService>().signOut(),
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Analytics"),
              Tab(text: "Pending Jobs"),
              Tab(text: "Recruiter Approvals"),
              Tab(text: "All Users"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAnalyticsTab(),
            _buildJobApprovalsTab(),
            _buildRecruiterApprovalsTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  // ======================== TAB 1: ANALYTICS ========================

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Platform Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Row 1: Basic Counts
          FutureBuilder<List<int>>(
            future: Future.wait([
              _getCount('users'),
              _getCount('jobs'),
              _getCount('applications'),
            ]),
            builder: (context, snapshot) {
              final counts = snapshot.data ?? [0, 0, 0];
              return Row(
                children: [
                  Expanded(child: _statCard('Total Users', '${counts[0]}', Colors.blue, Icons.people)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Jobs Posted', '${counts[1]}', Colors.green, Icons.work)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Applications', '${counts[2]}', Colors.orange, Icons.description)),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Row 2: Placement Metrics
          FutureBuilder<Map<String, dynamic>>(
            future: _getPlacementMetrics(),
            builder: (context, snapshot) {
              final metrics = snapshot.data ?? {};
              final placementRate = metrics['placementRate'] ?? '0';
              final totalSelected = metrics['totalSelected'] ?? 0;
              final totalStudents = metrics['totalStudents'] ?? 0;

              return Row(
                children: [
                  Expanded(child: _statCard('Placement Rate', '$placementRate%', Colors.teal, Icons.trending_up)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Selected', '$totalSelected / $totalStudents students', Colors.purple, Icons.check_circle)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Company-wise Hiring Table
          const Text('Company-wise Hiring', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCompanyHiringTable(),
        ],
      ),
    );
  }

  Future<int> _getCount(String collection) async {
    final snap = await FirebaseFirestore.instance.collection(collection).get();
    return snap.size;
  }

  Future<Map<String, dynamic>> _getPlacementMetrics() async {
    try {
      // Total students
      final studentsSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      int totalStudents = studentsSnap.size;

      // All applications
      final appsSnap = await FirebaseFirestore.instance.collection('applications').get();
      
      // Count unique students who got selected in at least ONE job
      // We check if the status matches the LAST round of any job they applied to
      // For simplicity, we look for common final statuses
      Set<String> selectedStudents = {};
      for (var doc in appsSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        // A student is "placed" if they reached the final round (not Applied, not Rejected)
        // We fetch the job's rounds to check
        // For performance, we use a simpler heuristic: if status is NOT 'rejected' and NOT the first round
        if (status != 'rejected' && status != 'applied') {
          selectedStudents.add(data['studentId'] ?? '');
        }
      }

      int totalSelected = selectedStudents.length;
      String rate = totalStudents > 0
          ? (totalSelected / totalStudents * 100).toStringAsFixed(1)
          : '0';

      return {
        'placementRate': rate,
        'totalSelected': totalSelected,
        'totalStudents': totalStudents,
      };
    } catch (e) {
      return {'placementRate': '0', 'totalSelected': 0, 'totalStudents': 0};
    }
  }

  Widget _buildCompanyHiringTable() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'approved').get(),
      builder: (context, jobsSnap) {
        if (!jobsSnap.hasData) return const Center(child: CircularProgressIndicator());
        
        final jobs = jobsSnap.data!.docs.map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        
        if (jobs.isEmpty) return const Text('No approved jobs yet.');

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('applications').get(),
          builder: (context, appsSnap) {
            if (!appsSnap.hasData) return const Center(child: CircularProgressIndicator());

            final apps = appsSnap.data!.docs;

            // Group by company
            Map<String, Map<String, int>> companyStats = {};
            for (var job in jobs) {
              companyStats.putIfAbsent(job.company, () => {'total': 0, 'active': 0, 'rejected': 0});
              final jobApps = apps.where((a) => (a.data() as Map)['jobId'] == job.id);
              for (var app in jobApps) {
                final status = ((app.data() as Map)['status'] ?? '').toString().toLowerCase();
                companyStats[job.company]!['total'] = (companyStats[job.company]!['total'] ?? 0) + 1;
                if (status == 'rejected') {
                  companyStats[job.company]!['rejected'] = (companyStats[job.company]!['rejected'] ?? 0) + 1;
                } else {
                  companyStats[job.company]!['active'] = (companyStats[job.company]!['active'] ?? 0) + 1;
                }
              }
            }

            return DataTable(
              columns: const [
                DataColumn(label: Text('Company', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Applied', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Active', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Rejected', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: companyStats.entries.map((entry) {
                return DataRow(cells: [
                  DataCell(Text(entry.key)),
                  DataCell(Text('${entry.value['total']}')),
                  DataCell(Text('${entry.value['active']}', style: const TextStyle(color: Colors.green))),
                  DataCell(Text('${entry.value['rejected']}', style: const TextStyle(color: Colors.red))),
                ]);
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Card(
      color: color.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, color: color, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ======================== TAB 2: JOB APPROVALS ========================

  Widget _buildJobApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('jobs')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending jobs to review."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final job = JobModel.fromMap(
                 snapshot.data!.docs[index].data() as Map<String, dynamic>, 
                 snapshot.data!.docs[index].id);

            return Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${job.role} at ${job.company}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Type: ${job.jobType} | CTC: ${job.salary} | Location: ${job.location}'),
                    Text('Min CGPA: ${job.requiredCgpa} | Branches: ${job.branchEligibility ?? "Any"}'),
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

  void _rejectJob(BuildContext context, String jobId) async {
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'rejected_by_admin'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job listing rejected.')));
    }
  }

  // ======================== TAB 3: RECRUITER APPROVALS ========================

  Widget _buildRecruiterApprovalsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'recruiter')
          .where('accountStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No pending recruiter verifications."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final recruiter = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

            return Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(recruiter.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(recruiter.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(recruiter.email),
                trailing: ElevatedButton(
                  onPressed: () => _approveRecruiter(context, recruiter.id, recruiter.name),
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

  // ======================== TAB 4: ALL USERS ========================

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text("No users."));

        final users = docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        final students = users.where((u) => u.role == UserRole.student).toList();
        final recruiters = users.where((u) => u.role == UserRole.recruiter).toList();
        final admins = users.where((u) => u.role == UserRole.admin).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _userSection('Students (${students.length})', students, Colors.blue, Icons.school),
              const SizedBox(height: 16),
              _userSection('Recruiters (${recruiters.length})', recruiters, Colors.green, Icons.business),
              const SizedBox(height: 16),
              _userSection('Admins (${admins.length})', admins, Colors.purple, Icons.admin_panel_settings),
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
                        Text('CGPA: ${u.cgpa ?? "N/A"} | Branch: ${u.branch ?? "N/A"}'),
                        Text('Skills: ${u.skills?.join(", ") ?? "None"}'),
                      ],
                      if (u.role == UserRole.recruiter)
                        Text('Status: ${u.accountStatus ?? "N/A"}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            }).toList(),
    );
  }
}
