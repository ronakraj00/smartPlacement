import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/interview_model.dart';

/// A summary dashboard shown above the job tabs
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

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hi, ${user.name}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _miniStat('Applied', '$applied', Colors.blue, Icons.send),
                  const SizedBox(width: 8),
                  _miniStat('In Progress', '$inProgress', Colors.orange, Icons.pending_actions),
                  const SizedBox(width: 8),
                  _miniStat('Rejected', '$rejected', Colors.red, Icons.cancel_outlined),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.event, color: Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Text('Upcoming Interviews', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              ...upcoming.take(3).map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i.roundName} — ${i.dateTime.day}/${i.dateTime.month} at ${i.dateTime.hour}:${i.dateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13),
                ),
              )),
              if (upcoming.length > 3)
                Text('+ ${upcoming.length - 3} more', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
