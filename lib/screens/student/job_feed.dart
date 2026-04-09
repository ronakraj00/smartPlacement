import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import '../../models/interview_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dashboard_summary.dart';

class JobFeed extends StatefulWidget {
  const JobFeed({super.key});

  @override
  State<JobFeed> createState() => _JobFeedState();
}

class _JobFeedState extends State<JobFeed> {
  String _searchQuery = '';
  String _filterJobType = 'All';

  // Computes a skill match percentage between student skills and job required skills
  int _skillMatchPercent(List<String>? studentSkills, List<String> jobSkills) {
    if (jobSkills.isEmpty) return 100;
    if (studentSkills == null || studentSkills.isEmpty) return 0;
    final studentLower = studentSkills.map((s) => s.toLowerCase().trim()).toSet();
    final jobLower = jobSkills.map((s) => s.toLowerCase().trim()).toSet();
    int matched = jobLower.intersection(studentLower).length;
    return ((matched / jobLower.length) * 100).round();
  }

  void _applyToJob(BuildContext context, JobModel job, String userId) async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      if (job.requiredCgpa > 0 && (user.cgpa ?? 0) < job.requiredCgpa) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You need a minimum CGPA of ${job.requiredCgpa} to apply.')),
          );
        }
        return;
      }
      if (job.isExpired) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This job has passed its application deadline.')),
          );
        }
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc('${userId}_${job.id}')
          .set({
        'studentId': userId,
        'jobId': job.id,
        'status': job.rounds.isNotEmpty ? job.rounds.first : 'Applied',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully applied to ${job.company}!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying: $e')),
        );
      }
    }
  }

  void _withdrawApplication(BuildContext context, String userId, String jobId, String company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Application?'),
        content: Text('Are you sure you want to withdraw from $company? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('applications').doc('${userId}_$jobId').delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application withdrawn.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showJobDetails(BuildContext context, JobModel job, String? applicationStatus, String userId) {
    final user = context.read<AuthService>().currentUser;
    int matchPct = _skillMatchPercent(user?.skills, job.requiredSkills);
    bool isRejected = applicationStatus?.toLowerCase() == 'rejected';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${job.role} at ${job.company}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skill match bar
                  if (job.requiredSkills.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('Skill Match: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: matchPct / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                            color: matchPct >= 70 ? Colors.green : matchPct >= 40 ? Colors.orange : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$matchPct%', style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: matchPct >= 70 ? Colors.green : matchPct >= 40 ? Colors.orange : Colors.red,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (applicationStatus != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isRejected ? Colors.red.withAlpha(25) : Colors.deepPurple.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status: $applicationStatus',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRejected ? Colors.red : Colors.deepPurple),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _detailRow(Icons.location_on, 'Location', job.location.isNotEmpty ? job.location : 'N/A'),
                  _detailRow(Icons.work_outline, 'Type', job.jobType.isNotEmpty ? job.jobType : 'N/A'),
                  _detailRow(Icons.currency_rupee, 'Salary', job.salary.isNotEmpty ? job.salary : 'N/A'),
                  _detailRow(Icons.people, 'Positions', job.openPositions > 0 ? '${job.openPositions}' : 'N/A'),
                  if (job.deadline != null)
                    _detailRow(Icons.timer, 'Deadline', '${job.deadline!.day}/${job.deadline!.month}/${job.deadline!.year}${job.isExpired ? " (EXPIRED)" : ""}'),
                  const SizedBox(height: 16),

                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(job.description),
                  const SizedBox(height: 16),

                  const Text('Eligibility', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Min CGPA: ${job.requiredCgpa}'),
                  Text('Branches: ${job.branchEligibility ?? "Any"}'),
                  const SizedBox(height: 16),

                  const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: job.requiredSkills.map((s) {
                      bool hasSkill = user?.skills?.any((us) => us.toLowerCase() == s.toLowerCase()) ?? false;
                      return Chip(
                        label: Text(s, style: TextStyle(fontSize: 12, color: hasSkill ? Colors.white : null)),
                        backgroundColor: hasSkill ? Colors.green : null,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),

                  if (job.rounds.length > 1) ...[
                    const SizedBox(height: 16),
                    const Text('Interview Process', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(job.rounds.join(' → ')),
                  ],

                  if (job.documentUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...job.documentUrls.map((url) => InkWell(
                      onTap: () => launchUrl(Uri.parse(url)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Flexible(child: Text(url, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (applicationStatus == null && !job.isExpired)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyToJob(context, job, userId);
                },
                child: const Text('Apply Now'),
              ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  List<JobModel> _filterEligibleJobs(List<JobModel> jobs, double? studentCgpa, String? studentBranch) {
    return jobs.where((job) {
      if (job.requiredCgpa > 0 && (studentCgpa ?? 0) < job.requiredCgpa) return false;
      if (job.branchEligibility != null && job.branchEligibility!.isNotEmpty) {
        final allowed = job.branchEligibility!.split(',').map((b) => b.trim().toLowerCase()).where((b) => b.isNotEmpty).toList();
        if (allowed.isNotEmpty && studentBranch != null && studentBranch.isNotEmpty) {
          if (!allowed.contains(studentBranch.toLowerCase())) return false;
        }
      }
      return true;
    }).toList();
  }

  List<JobModel> _applySearchAndFilter(List<JobModel> jobs) {
    return jobs.where((job) {
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!job.company.toLowerCase().contains(q) &&
            !job.role.toLowerCase().contains(q) &&
            !job.location.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Filter
      if (_filterJobType != 'All' && job.jobType.toLowerCase() != _filterJobType.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const Center(child: Text("Error: Not logged in."));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Dashboard summary at top
          const StudentDashboardSummary(),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by company, role, location...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Full-Time', 'Intern', 'Part-Time', 'Contract'].map((type) {
                bool selected = _filterJobType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type, style: TextStyle(fontSize: 12, color: selected ? Colors.white : null)),
                    selected: selected,
                    selectedColor: Colors.deepPurple,
                    onSelected: (_) => setState(() => _filterJobType = type),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          const TabBar(
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: [
              Tab(text: "Available Jobs"),
              Tab(text: "My Applications"),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('applications')
                  .where('studentId', isEqualTo: user.id)
                  .snapshots(),
              builder: (context, appSnapshot) {
                if (appSnapshot.hasError) return const Center(child: Text('Error loading'));

                final myAppDocs = appSnapshot.data?.docs ?? [];
                final Map<String, String> userApps = {
                  for (var doc in myAppDocs)
                    (doc.data() as Map<String, dynamic>)['jobId'] as String:
                    (doc.data() as Map<String, dynamic>)['status'] as String
                };
                final Map<String, String?> feedbackMap = {
                  for (var doc in myAppDocs)
                    (doc.data() as Map<String, dynamic>)['jobId'] as String:
                    (doc.data() as Map<String, dynamic>)['rejectionFeedback'] as String?
                };

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('jobs')
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, jobSnapshot) {
                    if (jobSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allJobs = (jobSnapshot.data?.docs ?? []).map((doc) {
                      return JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                    }).toList();

                    final eligible = _filterEligibleJobs(allJobs, user.cgpa, user.branch);
                    final searched = _applySearchAndFilter(eligible);
                    final available = searched.where((j) => !userApps.containsKey(j.id) && !j.isExpired).toList();
                    final applied = allJobs.where((j) => userApps.containsKey(j.id)).toList();

                    return TabBarView(
                      children: [
                        _buildAvailableList(context, available, user),
                        _buildAppliedList(context, applied, userApps, feedbackMap, user.id),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableList(BuildContext context, List<JobModel> jobs, dynamic user) {
    if (jobs.isEmpty) {
      return const Center(child: Text("No eligible jobs found. Try adjusting your search filters."));
    }
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        int matchPct = _skillMatchPercent(user.skills, job.requiredSkills);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          child: InkWell(
            onTap: () => _showJobDetails(context, job, null, user.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${job.role}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (job.requiredSkills.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: matchPct >= 70 ? Colors.green.withAlpha(30) : matchPct >= 40 ? Colors.orange.withAlpha(30) : Colors.red.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('$matchPct% Match', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: matchPct >= 70 ? Colors.green : matchPct >= 40 ? Colors.orange : Colors.red,
                          )),
                        ),
                    ],
                  ),
                  Text(job.company, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tag(Icons.location_on, job.location.isNotEmpty ? job.location : 'N/A'),
                      const SizedBox(width: 12),
                      _tag(Icons.work_outline, job.jobType.isNotEmpty ? job.jobType : 'N/A'),
                      const SizedBox(width: 12),
                      if (job.salary.isNotEmpty) _tag(Icons.currency_rupee, job.salary),
                    ],
                  ),
                  if (job.deadline != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      job.daysRemaining >= 0
                          ? '⏰ ${job.daysRemaining} days remaining'
                          : '❌ Deadline passed',
                      style: TextStyle(fontSize: 12, color: job.daysRemaining <= 3 ? Colors.red : Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tag(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAppliedList(BuildContext context, List<JobModel> jobs, Map<String, String> userApps, Map<String, String?> feedbackMap, String userId) {
    if (jobs.isEmpty) {
      return const Center(child: Text("You haven't applied to any jobs yet."));
    }
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final status = userApps[job.id] ?? 'Applied';
        final feedback = feedbackMap[job.id];
        bool isRejected = status.toLowerCase() == 'rejected';

        int currentStep = 0;
        if (!isRejected) {
          currentStep = job.rounds.indexWhere((r) => r.toLowerCase() == status.toLowerCase());
          if (currentStep == -1) currentStep = 0;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 2,
          child: InkWell(
            onTap: () => _showJobDetails(context, job, status, userId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(job.company, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        backgroundColor: isRejected ? Colors.red : Colors.deepPurple,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const Divider(),

                  // Compact progress row
                  const Text('Progress:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: job.rounds.length,
                      itemBuilder: (context, ridx) {
                        bool completed = !isRejected && ridx < currentStep;
                        bool current = !isRejected && ridx == currentStep;

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isRejected
                                    ? Colors.red.withAlpha(20)
                                    : completed
                                        ? Colors.green.withAlpha(30)
                                        : current
                                            ? Colors.deepPurple.withAlpha(30)
                                            : Colors.grey.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: current ? Border.all(color: Colors.deepPurple, width: 2) : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (completed) const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                  if (current) const Icon(Icons.radio_button_checked, size: 14, color: Colors.deepPurple),
                                  if (!completed && !current) Icon(Icons.circle_outlined, size: 14, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(job.rounds[ridx], style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: current ? FontWeight.bold : FontWeight.normal,
                                    color: completed ? Colors.green : current ? Colors.deepPurple : Colors.grey,
                                  )),
                                ],
                              ),
                            ),
                            if (ridx < job.rounds.length - 1)
                              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade300),
                          ],
                        );
                      },
                    ),
                  ),

                  // Rejection feedback from recruiter
                  if (isRejected && feedback != null && feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withAlpha(40)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.feedback, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Feedback: $feedback', style: const TextStyle(fontSize: 12, color: Colors.red))),
                        ],
                      ),
                    ),
                  ],

                  // Interview info
                  _InterviewInfoWidget(jobId: job.id, studentId: userId),

                  // Withdraw button (only if status is first round)
                  if (status.toLowerCase() == job.rounds.first.toLowerCase()) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _withdrawApplication(context, userId, job.id, job.company),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Withdraw', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InterviewInfoWidget extends StatelessWidget {
  final String jobId;
  final String studentId;
  const _InterviewInfoWidget({required this.jobId, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviews')
          .where('jobId', isEqualTo: jobId)
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final interviews = snapshot.data!.docs
            .map((d) => InterviewModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList();
        interviews.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            ...interviews.take(2).map((i) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(40)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i.roundName} — ${i.dateTime.day}/${i.dateTime.month} at ${i.dateTime.hour}:${i.dateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('${i.venue} • ${i.mode.toUpperCase()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (i.meetingLink != null && i.meetingLink!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.videocam, color: Colors.blue, size: 20),
                      onPressed: () => launchUrl(Uri.parse(i.meetingLink!)),
                      tooltip: 'Join',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}
