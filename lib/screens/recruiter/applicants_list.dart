import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/job_model.dart';
import '../../models/user_model.dart';
import '../../services/notification_helper.dart';
import '../shared/student_public_profile.dart';

class ApplicantsList extends StatelessWidget {
  final String jobId;

  const ApplicantsList({super.key, required this.jobId});

  void _updateStatus(BuildContext context, String applicationId, String newStatus, String studentName, String studentId, String jobTitle) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({'status': newStatus});

      // Fire notification to the student
      await NotificationHelper.onApplicationStatusChange(
        studentId: studentId,
        jobTitle: jobTitle,
        newStatus: newStatus,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migrated $studentName to $newStatus!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, String applicationId, String studentName, String studentId, String jobTitle) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject $studentName?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide feedback for the candidate (optional):'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                hintText: 'e.g., Not enough experience in...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Update status
              await FirebaseFirestore.instance.collection('applications').doc(applicationId).update({
                'status': 'Rejected',
                'rejectionFeedback': feedbackController.text.isNotEmpty ? feedbackController.text : null,
              });
              // Notify student with feedback
              String body = 'Your application for "$jobTitle" has been rejected.';
              if (feedbackController.text.isNotEmpty) {
                body += '\nFeedback: ${feedbackController.text}';
              }
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': studentId,
                'title': 'Application Rejected',
                'body': body,
                'type': 'status_change',
                'read': false,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$studentName rejected.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExtendOfferDialog(BuildContext context, String studentId, String studentName, String jobId, String jobTitle, double defaultCtc, String company, String role) {
    final ctcC = TextEditingController(text: defaultCtc > 0 ? '$defaultCtc' : '');
    final letterC = TextEditingController();
    final deadlineC = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Extend Offer to $studentName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctcC, decoration: const InputDecoration(labelText: 'CTC (LPA)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              TextField(controller: letterC, decoration: const InputDecoration(labelText: 'Offer Letter URL (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                controller: deadlineC,
                decoration: const InputDecoration(labelText: 'Response Deadline', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (picked != null) {
                    deadline = picked;
                    deadlineC.text = '${picked.day}/${picked.month}/${picked.year}';
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ctc = double.tryParse(ctcC.text) ?? 0.0;
              Navigator.pop(ctx);

              await FirebaseFirestore.instance.collection('offers').add({
                'jobId': jobId,
                'studentId': studentId,
                'company': company,
                'role': role,
                'ctcLpa': ctc,
                'offerLetterUrl': letterC.text.isNotEmpty ? letterC.text : null,
                'status': 'pending',
                'offeredAt': FieldValue.serverTimestamp(),
                'responseDeadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
                'tier': ctc >= 25 ? 'Super Dream' : ctc >= 15 ? 'Dream' : 'Normal',
              });

              // Notify student
              await FirebaseFirestore.instance.collection('notifications').add({
                'userId': studentId,
                'title': '🎉 You received an offer!',
                'body': '$company has extended an offer for $role — ${ctc} LPA!',
                'type': 'offer',
                'read': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer sent to $studentName!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Send Offer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, String studentId, String studentName, String jobId, String jobTitle, String roundName) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final venueController = TextEditingController();
    final linkController = TextEditingController();
    final notesController = TextEditingController();
    String mode = 'offline';

    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Schedule Interview — $roundName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                          dateController.text = '${picked.day}/${picked.month}/${picked.year}';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: timeController,
                      decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder(), suffixIcon: Icon(Icons.access_time)),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          selectedTime = picked;
                          timeController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: mode,
                      decoration: const InputDecoration(labelText: 'Mode', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'offline', child: Text('Offline (In-Person)')),
                        DropdownMenuItem(value: 'online', child: Text('Online (Virtual)')),
                      ],
                      onChanged: (val) => setDialogState(() => mode = val ?? 'offline'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: venueController,
                      decoration: const InputDecoration(labelText: 'Venue / Room', border: OutlineInputBorder()),
                    ),
                    if (mode == 'online') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: linkController,
                        decoration: const InputDecoration(labelText: 'Meeting Link', border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedDate == null || selectedTime == null || venueController.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please fill date, time, and venue.')),
                      );
                      return;
                    }
                    final dateTime = DateTime(
                      selectedDate!.year, selectedDate!.month, selectedDate!.day,
                      selectedTime!.hour, selectedTime!.minute,
                    );

                    await FirebaseFirestore.instance.collection('interviews').add({
                      'jobId': jobId,
                      'studentId': studentId,
                      'roundName': roundName,
                      'dateTime': Timestamp.fromDate(dateTime),
                      'venue': venueController.text,
                      'mode': mode,
                      'meetingLink': linkController.text.isNotEmpty ? linkController.text : null,
                      'notes': notesController.text.isNotEmpty ? notesController.text : null,
                    });

                    // Notify the student
                    await NotificationHelper.onInterviewScheduled(
                      studentId: studentId,
                      jobTitle: jobTitle,
                      roundName: roundName,
                      dateTime: '${dateController.text} ${timeController.text}',
                      venue: venueController.text,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Interview scheduled for $studentName!')),
                      );
                    }
                  },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
      builder: (context, jobSnapshot) {
        if (!jobSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final job = JobModel.fromMap(jobSnapshot.data!.data() as Map<String, dynamic>, jobSnapshot.data!.id);
        final jobTitle = '${job.role} at ${job.company}';
        
        final List<String> pipelineTabs = List<String>.from(job.rounds)..add('Rejected');

        return DefaultTabController(
          length: pipelineTabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Pipeline: ${job.role}'),
              bottom: TabBar(
                isScrollable: true,
                tabs: pipelineTabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
            body: TabBarView(
              children: pipelineTabs.map((tabStatus) {
                return _buildPipelineColumn(context, tabStatus, job, jobTitle);
              }).toList(),
            ),
          ),
        );
      }
    );
  }

  Widget _buildPipelineColumn(BuildContext context, String targetStatus, JobModel job, String jobTitle) {
    final completePipeline = job.rounds;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: targetStatus) 
          .snapshots(),
      builder: (context, appSnapshot) {
        if (appSnapshot.hasError) return const Center(child: Text('Error.'));
        if (appSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawDocs = appSnapshot.data?.docs ?? [];
        
        final Set<String> seenStudents = {};
        final docs = rawDocs.where((doc) {
          final sid = (doc.data() as Map<String, dynamic>)['studentId'] as String;
          if (seenStudents.contains(sid)) return false;
          seenStudents.add(sid);
          return true;
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Text('No students in "$targetStatus" round.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final applicationDoc = docs[index];
            final data = applicationDoc.data() as Map<String, dynamic>;
            final studentId = data['studentId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const Card(child: ListTile(title: Text('Loading candidate...')));
                
                final student = UserModel.fromMap(
                    userSnapshot.data!.data() as Map<String, dynamic>, userSnapshot.data!.id);

                bool isRejected = targetStatus.toLowerCase() == 'rejected';
                
                int currentIdx = completePipeline.indexOf(targetStatus);
                String? nextStatus;
                if (!isRejected && currentIdx != -1 && currentIdx < completePipeline.length - 1) {
                  nextStatus = completePipeline[currentIdx + 1];
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentPublicProfile(studentId: studentId),
                    )),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepPurple,
                              child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(student.email, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CGPA: ${student.cgpa ?? "N/A"} | Branch: ${student.branch ?? "N/A"}'),
                              Text('Skills: ${student.skills?.join(", ") ?? "None"}'),
                              if (student.projects != null && student.projects!.isNotEmpty)
                                Text('Projects: ${student.projects!.join(", ")}'),
                              if (student.resumeUrl != null && student.resumeUrl!.isNotEmpty)
                                InkWell(
                                  onTap: () {},
                                  child: const Text('📄 View Resume', style: TextStyle(color: Colors.blue)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Action Buttons
                        if (!isRejected) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showRejectDialog(context, applicationDoc.id, student.name, studentId, jobTitle),
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                ),
                              ),
                              if (nextStatus != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _updateStatus(context, applicationDoc.id, nextStatus!, student.name, studentId, jobTitle),
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Promote'),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showExtendOfferDialog(context, studentId, student.name, jobId, jobTitle, job.ctcLpa, job.company, job.role),
                                    icon: const Icon(Icons.card_giftcard),
                                    label: const Text('Extend Offer'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Schedule Interview Button
                          OutlinedButton.icon(
                            onPressed: () => _showScheduleDialog(context, studentId, student.name, jobId, jobTitle, targetStatus),
                            icon: const Icon(Icons.event, color: Colors.orange),
                            label: const Text('Schedule Interview', style: TextStyle(color: Colors.orange)),
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange)),
                          ),
                        ] else ...[
                           Center(
                             child: OutlinedButton.icon(
                                onPressed: () => _updateStatus(context, applicationDoc.id, completePipeline.first, student.name, studentId, jobTitle),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Restore to Pipeline'),
                              ),
                           )
                        ]
                      ],
                    ), // Column
                  ), // Padding
                ), // InkWell
                ); // Card
              },
            );
          },
        );
      },
    );
  }
}
