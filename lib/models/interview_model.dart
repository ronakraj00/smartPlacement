import 'package:cloud_firestore/cloud_firestore.dart';

class InterviewModel {
  final String id;
  final String jobId;
  final String studentId;
  final String roundName;
  final DateTime dateTime;
  final String venue;
  final String mode; // 'online' or 'offline'
  final String? meetingLink;
  final String? notes;

  InterviewModel({
    required this.id,
    required this.jobId,
    required this.studentId,
    required this.roundName,
    required this.dateTime,
    required this.venue,
    required this.mode,
    this.meetingLink,
    this.notes,
  });

  factory InterviewModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InterviewModel(
      id: documentId,
      jobId: data['jobId'] ?? '',
      studentId: data['studentId'] ?? '',
      roundName: data['roundName'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      venue: data['venue'] ?? '',
      mode: data['mode'] ?? 'offline',
      meetingLink: data['meetingLink'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'studentId': studentId,
      'roundName': roundName,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
      'mode': mode,
      'meetingLink': meetingLink,
      'notes': notes,
    };
  }
}
