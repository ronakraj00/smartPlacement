import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../models/interview_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

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
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.calendar_month_rounded, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Placement Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Upcoming events for the next 30 days', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // My Interviews
          _SectionHeader(icon: Icons.videocam_rounded, title: 'My Interviews', color: AppTheme.warning),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('interviews').where('studentId', isEqualTo: user.id).snapshots(),
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
                  color: AppTheme.warning,
                  icon: i.mode == 'online' ? Icons.videocam_rounded : Icons.room_rounded,
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Application Deadlines
          _SectionHeader(icon: Icons.timer_rounded, title: 'Application Deadlines', color: AppTheme.error),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'approved').snapshots(),
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
                  color: j.daysRemaining <= 3 ? AppTheme.error : AppTheme.primary,
                  icon: Icons.work_outline_rounded,
                  trailing: '${j.daysRemaining}d left',
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Recent Drives
          _SectionHeader(icon: Icons.rocket_launch_rounded, title: 'Recent Job Postings', color: AppTheme.success),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').where('status', isEqualTo: 'approved').snapshots(),
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
                  color: AppTheme.success,
                  icon: Icons.new_releases_rounded,
                  trailing: 'New',
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
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
    padding: const EdgeInsets.only(bottom: 8, left: 42),
    child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Date chip
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withAlpha(20), color.withAlpha(8)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                  Text(_monthAbbr(date.month), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (trailing != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Text(trailing!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              )
            else
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }
}
