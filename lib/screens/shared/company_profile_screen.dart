import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/company_model.dart';
import '../../models/job_model.dart';

class CompanyProfileScreen extends StatelessWidget {
  final String companyName;
  const CompanyProfileScreen({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(companyName)),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('companies')
            .where('name', isEqualTo: companyName)
            .limit(1)
            .get(),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.deepPurple.withAlpha(30),
                          child: Text(
                            companyName.isNotEmpty ? companyName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(companyName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        if (company != null) ...[
                          const SizedBox(height: 4),
                          Text(company.industry, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Company Details
                if (company != null) ...[
                  _infoSection('About', company.description),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow(Icons.location_city, 'Headquarters', company.headquarters ?? 'N/A'),
                          _infoRow(Icons.people, 'Employees', company.employeeCount ?? 'N/A'),
                          _infoRow(Icons.star, 'Rating', '${company.avgRating}/5'),
                          if (company.website != null)
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(company!.website!)),
                              child: _infoRow(Icons.language, 'Website', company.website!),
                            ),
                          if (company.pastVisitYears.isNotEmpty)
                            _infoRow(Icons.history, 'Past Visits', company.pastVisitYears.join(', ')),
                        ],
                      ),
                    ),
                  ),
                ] else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No detailed company profile available yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  ),

                const SizedBox(height: 24),
                const Text('Active Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Active jobs from this company
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where('company', isEqualTo: companyName)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, jobSnap) {
                    if (!jobSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final jobs = jobSnap.data!.docs
                        .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                        .toList();
                    if (jobs.isEmpty) return const Text('No active jobs.', style: TextStyle(color: Colors.grey));

                    return Column(
                      children: jobs.map((job) => Card(
                        child: ListTile(
                          title: Text(job.role, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${job.jobType} • ${job.location} • ${job.salary}'),
                          trailing: job.ctcLpa > 0
                              ? Chip(
                                  label: Text('${job.ctcLpa} LPA', style: const TextStyle(fontSize: 11)),
                                  backgroundColor: Colors.green.withAlpha(30),
                                )
                              : null,
                        ),
                      )).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),
                const Text('Hiring History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Past applications stats
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('applications')
                      .get(),
                  builder: (context, appSnap) {
                    if (!appSnap.hasData) return const SizedBox.shrink();
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('jobs')
                          .where('company', isEqualTo: companyName)
                          .get(),
                      builder: (context, allJobSnap) {
                        if (!allJobSnap.hasData) return const SizedBox.shrink();
                        final jobIds = allJobSnap.data!.docs.map((d) => d.id).toSet();
                        final apps = appSnap.data!.docs.where((d) => jobIds.contains((d.data() as Map)['jobId']));
                        int total = apps.length;
                        int rejected = apps.where((d) => ((d.data() as Map)['status'] ?? '').toString().toLowerCase() == 'rejected').length;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statCol('Total Apps', '$total', Colors.blue),
                                _statCol('Active', '${total - rejected}', Colors.green),
                                _statCol('Rejected', '$rejected', Colors.red),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoSection(String title, String content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
