import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../models/interview_model.dart';
import '../../services/auth_service.dart';

class PlacementCalendarScreen extends StatelessWidget {
  const PlacementCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Placement Calendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Upcoming events for the next 30 days', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          // My Interviews
          const _SectionHeader(icon: Icons.videocam, title: 'My Interviews', color: Colors.orange),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('interviews')
                .where('studentId', isEqualTo: user.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final interviews = snapshot.data!.docs
                  .map((d) => InterviewModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .where((i) => i.dateTime.isAfter(now))
                  .toList();
              interviews.sort((a, b) => a.dateTime.compareTo(b.dateTime));

              if (interviews.isEmpty) return const _EmptyHint(text: 'No upcoming interviews.');

              return Column(
                children: interviews.map((i) => _EventCard(
                  title: i.roundName,
                  subtitle: '${i.venue} • ${i.mode.toUpperCase()}',
                  date: i.dateTime,
                  color: Colors.orange,
                  icon: i.mode == 'online' ? Icons.videocam : Icons.room,
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Application Deadlines
          const _SectionHeader(icon: Icons.timer, title: 'Application Deadlines', color: Colors.red),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final jobs = snapshot.data!.docs
                  .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .where((j) => j.deadline != null && j.deadline!.isAfter(now) && j.deadline!.isBefore(now.add(const Duration(days: 30))))
                  .toList();
              jobs.sort((a, b) => a.deadline!.compareTo(b.deadline!));

              if (jobs.isEmpty) return const _EmptyHint(text: 'No upcoming deadlines.');

              return Column(
                children: jobs.map((j) => _EventCard(
                  title: '${j.role} at ${j.company}',
                  subtitle: '${j.jobType} • ${j.location}',
                  date: j.deadline!,
                  color: j.daysRemaining <= 3 ? Colors.red : Colors.deepPurple,
                  icon: Icons.work_outline,
                  trailing: '${j.daysRemaining}d left',
                )).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent Drives
          const _SectionHeader(icon: Icons.business, title: 'Recent Job Postings', color: Colors.green),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final jobs = snapshot.data!.docs
                  .map((d) => JobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
                  .where((j) => j.postedAt != null && j.postedAt!.isAfter(now.subtract(const Duration(days: 7))))
                  .toList();
              jobs.sort((a, b) => b.postedAt!.compareTo(a.postedAt!));

              if (jobs.isEmpty) return const _EmptyHint(text: 'No new jobs this week.');

              return Column(
                children: jobs.map((j) => _EventCard(
                  title: '${j.role} at ${j.company}',
                  subtitle: '${j.salary} • ${j.openPositions} positions',
                  date: j.postedAt!,
                  color: Colors.green,
                  icon: Icons.new_releases,
                  trailing: 'New',
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 28),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
  );
}

class _EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final IconData icon;
  final String? trailing;

  const _EventCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(_monthAbbr(date.month), style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(trailing!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              )
            : Icon(icon, color: color, size: 20),
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }
}
