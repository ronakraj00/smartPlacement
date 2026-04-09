import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/offer_model.dart';
import '../../theme/app_theme.dart';

/// Premium public profile view — used by recruiters and admin.
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
                // Header Card with gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(student.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text(student.email, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200))),
                      const SizedBox(height: 10),
                      // Status + Profile badges row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statusBadge(student.placementStatus),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(
                                    value: student.profileCompleteness / 100,
                                    strokeWidth: 2, color: Colors.white, backgroundColor: Colors.white.withAlpha(60),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('${student.profileCompleteness}%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // About
                if (student.about != null && student.about!.isNotEmpty)
                  _sectionCard('About', AppTheme.primary, Icons.person_rounded, [
                    Text(student.about!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                  ]),

                // Personal
                _sectionCard('Personal', AppTheme.secondary, Icons.badge_rounded, [
                  _detailRow('Phone', student.phone ?? 'N/A'),
                  _detailRow('DOB', student.dob ?? 'N/A'),
                  _detailRow('Gender', student.gender ?? 'N/A'),
                  if (student.address != null) _detailRow('Address', student.address!),
                ]),

                // Academics
                _sectionCard('Academics', AppTheme.info, Icons.school_rounded, [
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
                  _sectionCard('Education', AppTheme.dreamTier, Icons.history_edu_rounded, [
                    if (student.class10th != null)
                      _detailRow('10th', '${student.class10th!['board']} — ${student.class10th!['percentage']}% (${student.class10th!['year']})'),
                    if (student.class12th != null)
                      _detailRow('12th', '${student.class12th!['board']} — ${student.class12th!['percentage']}% (${student.class12th!['year']})'),
                  ]),

                // Skills
                if (student.skills != null && student.skills!.isNotEmpty)
                  _sectionCard('Skills', AppTheme.primary, Icons.build_rounded, [
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: student.skills!.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary.withAlpha(12), AppTheme.primary.withAlpha(6)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withAlpha(40)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                      )).toList(),
                    ),
                  ]),

                // Projects
                if (student.projects != null && student.projects!.isNotEmpty)
                  _sectionCard('Projects', AppTheme.success, Icons.code_rounded, [
                    ...student.projects!.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(color: AppTheme.success.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.folder_rounded, size: 14, color: AppTheme.success),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                      ]),
                    )),
                  ]),

                // Certifications
                if (student.certifications != null && student.certifications!.isNotEmpty)
                  _sectionCard('Certifications', AppTheme.warning, Icons.verified_rounded, [
                    ...student.certifications!.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(color: AppTheme.warning.withAlpha(15), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.workspace_premium_rounded, size: 14, color: AppTheme.warning),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${c['name']}${c['issuer'] != null && c['issuer'].toString().isNotEmpty ? " — ${c['issuer']}" : ""}')),
                      ]),
                    )),
                  ]),

                // Work Experience
                if (student.workExperience != null && student.workExperience!.isNotEmpty)
                  _sectionCard('Experience', AppTheme.info, Icons.work_history_rounded, [
                    ...student.workExperience!.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e['role']} at ${e['company']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          if (e['duration'] != null && e['duration'].toString().isNotEmpty)
                            Text(e['duration'], style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          if (e['description'] != null && e['description'].toString().isNotEmpty)
                            Text(e['description'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.3)),
                        ],
                      ),
                    )),
                  ]),

                // Social Links
                if (student.socialLinks != null && student.socialLinks!.isNotEmpty)
                  _sectionCard('Social Links', AppTheme.info, Icons.link_rounded, [
                    ...student.socialLinks!.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppTheme.info.withAlpha(12), borderRadius: BorderRadius.circular(8)),
                          child: Icon(_socialIcon(e.key), size: 14, color: AppTheme.info),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.value, style: const TextStyle(color: AppTheme.info, fontSize: 13, fontWeight: FontWeight.w500))),
                      ]),
                    )),
                  ]),

                // Resume
                if (student.resumeUrl != null && student.resumeUrl!.isNotEmpty)
                  _sectionCard('Resume', AppTheme.success, Icons.description_rounded, [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(children: [
                        Icon(Icons.picture_as_pdf_rounded, color: AppTheme.success),
                        SizedBox(width: 10),
                        Text('Resume uploaded', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),

                // Offers
                const SizedBox(height: 4),
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
        return _sectionCard('Offers (${offers.length})', AppTheme.superDreamTier, Icons.card_giftcard_rounded, [
          ...offers.map((o) {
            final tierColor = _tierColor(o.tier);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tierColor.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tierColor.withAlpha(40)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: tierColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(o.company[0], style: TextStyle(fontWeight: FontWeight.w800, color: tierColor))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${o.role} at ${o.company}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('₹${o.ctcLpa} LPA — ${o.tier}', style: TextStyle(fontSize: 11, color: tierColor)),
                      ],
                    ),
                  ),
                  _offerStatusBadge(o.status),
                ],
              ),
            );
          }),
        ]);
      },
    );
  }

  Widget _sectionCard(String title, Color color, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 28, height: 28,
                decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'placed': color = AppTheme.success; label = '✅ PLACED'; break;
      case 'opted_out': color = AppTheme.warning; label = '🚫 OPTED OUT'; break;
      default: color = AppTheme.info; label = '🔍 SEEKING'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color == AppTheme.success ? Colors.white : Colors.white.withAlpha(220))),
    );
  }

  Widget _offerStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'accepted': color = AppTheme.success; icon = Icons.check_circle_rounded; break;
      case 'declined': color = AppTheme.error; icon = Icons.cancel_rounded; break;
      default: color = AppTheme.warning; icon = Icons.pending_rounded; break;
    }
    return Icon(icon, color: color, size: 22);
  }

  Color _tierColor(String tier) {
    switch (tier) {
      case 'Super Dream': return AppTheme.superDreamTier;
      case 'Dream': return AppTheme.dreamTier;
      default: return AppTheme.normalTier;
    }
  }

  IconData _socialIcon(String key) {
    switch (key) {
      case 'linkedin': return Icons.link_rounded;
      case 'github': return Icons.code_rounded;
      case 'portfolio': return Icons.web_rounded;
      case 'leetcode': return Icons.terminal_rounded;
      default: return Icons.link_rounded;
    }
  }
}
