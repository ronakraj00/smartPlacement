import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/interview_model.dart';
import '../../theme/app_theme.dart';

/// Premium dashboard summary shown above the job tabs.
class StudentDashboardSummary extends StatelessWidget {
  const StudentDashboardSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: user.id)
          .snapshots(),
      builder: (context, appSnapshot) {
        final apps = appSnapshot.data?.docs ?? [];
        int applied = apps.length;
        int inProgress = 0;
        int rejected = 0;

        for (var doc in apps) {
          final status = ((doc.data() as Map)['status'] ?? '').toString().toLowerCase();
          if (status == 'rejected') {
            rejected++;
          } else if (status != 'applied') {
            inProgress++;
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting with gradient card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, ${user.name}! 👋',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text('${user.branch ?? ''} • CGPA: ${user.cgpa ?? "N/A"}',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                            ],
                          ),
                        ),
                        // Profile completeness ring
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Stack(
                            children: [
                              CircularProgressIndicator(
                                value: user.profileCompleteness / 100,
                                strokeWidth: 3,
                                backgroundColor: Colors.white.withAlpha(40),
                                color: Colors.white,
                              ),
                              Center(
                                child: Text('${user.profileCompleteness}%',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _miniStat('Applied', '$applied', AppTheme.info, Icons.send_rounded),
                  const SizedBox(width: 8),
                  _miniStat('In Progress', '$inProgress', AppTheme.warning, Icons.trending_up),
                  const SizedBox(width: 8),
                  _miniStat('Rejected', '$rejected', AppTheme.error, Icons.close_rounded),
                ],
              ),
              const SizedBox(height: 12),

              // Upcoming interviews
              _UpcomingInterviews(userId: user.id),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withAlpha(180))),
          ],
        ),
      ),
    );
  }
}

class _UpcomingInterviews extends StatelessWidget {
  final String userId;
  const _UpcomingInterviews({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('interviews')
          .where('studentId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final now = DateTime.now();
        final upcoming = snapshot.data!.docs
            .map((d) => InterviewModel.fromMap(d.data() as Map<String, dynamic>, d.id))
            .where((i) => i.dateTime.isAfter(now))
            .toList();
        upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.warning.withAlpha(12), AppTheme.warning.withAlpha(6)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.warning.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppTheme.warning.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.videocam, color: AppTheme.warning, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Upcoming Interviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.warning)),
                ],
              ),
              const SizedBox(height: 10),
              ...upcoming.take(3).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${i.dateTime.day}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.warning)),
                          Text(_monthAbbr(i.dateTime.month), style: const TextStyle(fontSize: 8, color: AppTheme.warning)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(i.roundName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('${i.dateTime.hour}:${i.dateTime.minute.toString().padLeft(2, '0')} • ${i.venue}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: i.mode == 'online' ? AppTheme.info.withAlpha(15) : AppTheme.success.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(i.mode.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                              color: i.mode == 'online' ? AppTheme.info : AppTheme.success)),
                    ),
                  ],
                ),
              )),
              if (upcoming.length > 3)
                Text('+ ${upcoming.length - 3} more', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }

  String _monthAbbr(int m) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m];
  }
}
