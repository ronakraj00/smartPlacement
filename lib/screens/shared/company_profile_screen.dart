import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/company_model.dart';
import '../../models/job_model.dart';
import '../../theme/app_theme.dart';

class CompanyProfileScreen extends StatelessWidget {
  final String companyName;
  const CompanyProfileScreen({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(companyName)),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('companies').where('name', isEqualTo: companyName).limit(1).get(),
        builder: (context, snapshot) {
          CompanyModel? company;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final doc = snapshot.data!.docs.first;
            company = CompanyModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Company Header
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
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(18)),
                        child: Center(
                          child: Text(companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(companyName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      if (company != null)
                        Text(company.industry, style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200))),
                      if (company != null && company.avgRating > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < company!.avgRating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                              color: Colors.amber, size: 20,
                            )),
                            const SizedBox(width: 6),
                            Text('${company.avgRating}', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Company Details
                if (company != null) ...[
                  // About
                  if (company.description.isNotEmpty)
                    _card([
                      _sectionTitle('About'),
                      const SizedBox(height: 8),
                      Text(company.description, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5)),
                    ]),

                  // Details grid
                  _card([
                    _sectionTitle('Details'),
                    const SizedBox(height: 10),
                    if (company.headquarters != null) _detailRow(Icons.location_city_rounded, 'Headquarters', company.headquarters!),
                    if (company.employeeCount != null) _detailRow(Icons.people_rounded, 'Employees', company.employeeCount!),
                    if (company.website != null)
                      InkWell(
                        onTap: () => launchUrl(Uri.parse(company!.website!)),
                        child: _detailRow(Icons.language_rounded, 'Website', company.website!, isLink: true),
                      ),
                    if (company.pastVisitYears.isNotEmpty)
                      _detailRow(Icons.history_rounded, 'Campus Visits', company.pastVisitYears.join(', ')),
                  ]),
                ] else
                  _card([
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary.withAlpha(120)),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('No detailed company profile available yet.', style: TextStyle(color: AppTheme.textSecondary))),
                      ],
                    ),
                  ]),

                const SizedBox(height: 20),
                Text('Active Jobs', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),

                // Active jobs
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('jobs').where('company', isEqualTo: companyName).where('status', isEqualTo: 'approved').snapshots(),
                  builder: (context, jobSnap) {
                    if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final jobs = jobSnap.data!.docs.map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
                    if (jobs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.dividerColor)),
                        child: const Center(child: Text('No active jobs.', style: TextStyle(color: AppTheme.textSecondary))),
                      );
                    }

                    return Column(
                      children: jobs.map((job) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.work_rounded, color: AppTheme.primary, size: 20),
                          ),
                          title: Text(job.role, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text('${job.jobType} • ${job.location} • ${job.salary}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          trailing: job.ctcLpa > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withAlpha(12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.success.withAlpha(40)),
                                  ),
                                  child: Text('₹${job.ctcLpa}L', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success)),
                                )
                              : null,
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text('Hiring History', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),

                // Hiring stats
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('applications').get(),
                  builder: (context, appSnap) {
                    if (!appSnap.hasData) return const SizedBox.shrink();
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('jobs').where('company', isEqualTo: companyName).get(),
                      builder: (context, allJobSnap) {
                        if (!allJobSnap.hasData) return const SizedBox.shrink();
                        final jobIds = allJobSnap.data!.docs.map((d) => d.id).toSet();
                        final apps = appSnap.data!.docs.where((d) => jobIds.contains((d.data() as Map)['jobId']));
                        int total = apps.length;
                        int rejected = apps.where((d) => ((d.data() as Map)['status'] ?? '').toString().toLowerCase() == 'rejected').length;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              _statCol('Total', '$total', AppTheme.info),
                              Container(width: 1, height: 36, color: AppTheme.dividerColor),
                              _statCol('Active', '${total - rejected}', AppTheme.success),
                              Container(width: 1, height: 36, color: AppTheme.dividerColor),
                              _statCol('Rejected', '$rejected', AppTheme.error),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary));
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isLink ? AppTheme.info : AppTheme.textPrimary,
            decoration: isLink ? TextDecoration.underline : null,
          ))),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withAlpha(180))),
        ],
      ),
    );
  }
}
