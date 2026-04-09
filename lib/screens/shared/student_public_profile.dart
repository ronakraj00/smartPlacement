import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/offer_model.dart';

/// Public profile view — used by recruiters and admin to view a student's full profile.
class StudentPublicProfile extends StatelessWidget {
  final String studentId;
  const StudentPublicProfile({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Student not found.'));

          final student = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.deepPurple,
                          child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Text(student.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(student.email, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(student.placementStatus).withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _statusColor(student.placementStatus)),
                          ),
                          child: Text(
                            _statusLabel(student.placementStatus),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _statusColor(student.placementStatus)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Profile completeness
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Profile: ${student.profileCompleteness}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: LinearProgressIndicator(
                                value: student.profileCompleteness / 100,
                                color: student.profileCompleteness >= 80 ? Colors.green : Colors.orange,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // About
                if (student.about != null && student.about!.isNotEmpty) ...[
                  _sectionCard('About', [Text(student.about!)]),
                ],

                // Personal Details
                _sectionCard('Personal Information', [
                  _detailRow('Phone', student.phone ?? 'N/A'),
                  _detailRow('DOB', student.dob ?? 'N/A'),
                  _detailRow('Gender', student.gender ?? 'N/A'),
                  if (student.address != null) _detailRow('Address', student.address!),
                ]),

                // Academics
                _sectionCard('Academic Information', [
                  _detailRow('CGPA', '${student.cgpa ?? "N/A"}'),
                  _detailRow('Branch', student.branch ?? 'N/A'),
                  _detailRow('Semester', '${student.semester ?? "N/A"}'),
                  _detailRow('Graduation', '${student.graduationYear ?? "N/A"}'),
                  _detailRow('Active Backlogs', '${student.activeBacklogs ?? 0}'),
                  _detailRow('Total Backlogs', '${student.totalBacklogs ?? 0}'),
                  _detailRow('Attendance', '${student.attendance ?? "N/A"}%'),
                ]),

                // Education History
                if (student.class10th != null || student.class12th != null)
                  _sectionCard('Education History', [
                    if (student.class10th != null)
                      _detailRow('Class 10th', '${student.class10th!['board']} — ${student.class10th!['percentage']}% (${student.class10th!['year']})'),
                    if (student.class12th != null)
                      _detailRow('Class 12th', '${student.class12th!['board']} — ${student.class12th!['percentage']}% (${student.class12th!['year']})'),
                  ]),

                // Skills
                if (student.skills != null && student.skills!.isNotEmpty)
                  _sectionCard('Skills', [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: student.skills!.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.deepPurple.withAlpha(20),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ]),

                // Projects
                if (student.projects != null && student.projects!.isNotEmpty)
                  _sectionCard('Projects', [
                    ...student.projects!.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.code, size: 16, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p)),
                      ]),
                    )),
                  ]),

                // Certifications
                if (student.certifications != null && student.certifications!.isNotEmpty)
                  _sectionCard('Certifications', [
                    ...student.certifications!.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.verified, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${c['name']}${c['issuer'] != null && c['issuer'].toString().isNotEmpty ? " — ${c['issuer']}" : ""}')),
                      ]),
                    )),
                  ]),

                // Work Experience
                if (student.workExperience != null && student.workExperience!.isNotEmpty)
                  _sectionCard('Work Experience', [
                    ...student.workExperience!.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e['role']} at ${e['company']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (e['duration'] != null && e['duration'].toString().isNotEmpty)
                            Text(e['duration'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (e['description'] != null && e['description'].toString().isNotEmpty)
                            Text(e['description'], style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
                  ]),

                // Social Links
                if (student.socialLinks != null && student.socialLinks!.isNotEmpty)
                  _sectionCard('Social Links', [
                    ...student.socialLinks!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(_socialIcon(e.key), size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.value, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
                      ]),
                    )),
                  ]),

                // Resume
                if (student.resumeUrl != null && student.resumeUrl!.isNotEmpty)
                  _sectionCard('Resume', [
                    Row(children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('📄 Resume uploaded', style: TextStyle(color: Colors.blue)),
                    ]),
                  ]),

                // Offers received
                const SizedBox(height: 8),
                _buildOffersSection(),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('offers').where('studentId', isEqualTo: studentId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
        final offers = snap.data!.docs.map((d) => OfferModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
        return _sectionCard('Offers (${offers.length})', [
          ...offers.map((o) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: _tierColor(o.tier).withAlpha(30),
              child: Text(o.company[0], style: TextStyle(color: _tierColor(o.tier), fontWeight: FontWeight.bold)),
            ),
            title: Text('${o.role} at ${o.company}'),
            subtitle: Text('${o.ctcLpa} LPA — ${o.tier} — ${o.status.toUpperCase()}'),
            trailing: Icon(
              o.status == 'accepted' ? Icons.check_circle : o.status == 'declined' ? Icons.cancel : Icons.pending,
              color: o.status == 'accepted' ? Colors.green : o.status == 'declined' ? Colors.red : Colors.orange,
            ),
          )),
        ]);
      },
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    if (status == 'placed') return Colors.green;
    if (status == 'opted_out') return Colors.orange;
    return Colors.blue;
  }

  String _statusLabel(String? status) {
    if (status == 'placed') return '✅ PLACED';
    if (status == 'opted_out') return '🚫 OPTED OUT';
    return '🔍 SEEKING PLACEMENT';
  }

  Color _tierColor(String tier) {
    if (tier == 'Super Dream') return Colors.amber.shade800;
    if (tier == 'Dream') return Colors.purple;
    return Colors.blue;
  }

  IconData _socialIcon(String key) {
    switch (key) {
      case 'linkedin': return Icons.link;
      case 'github': return Icons.code;
      case 'portfolio': return Icons.web;
      case 'leetcode': return Icons.terminal;
      default: return Icons.link;
    }
  }
}
