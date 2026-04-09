import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes in-app notification documents to Firestore.
/// These are read by the student's notifications screen in real-time.
class NotificationHelper {
  static final _db = FirebaseFirestore.instance;

  /// Called when a recruiter promotes/rejects a student's application.
  static Future<void> onApplicationStatusChange({
    required String studentId,
    required String jobTitle,
    required String newStatus,
  }) async {
    await _db.collection('notifications').add({
      'userId': studentId,
      'title': 'Application Update',
      'body': 'Your application for "$jobTitle" has been updated to: $newStatus',
      'type': 'status_change',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called when a recruiter schedules an interview.
  static Future<void> onInterviewScheduled({
    required String studentId,
    required String jobTitle,
    required String roundName,
    required String dateTime,
    required String venue,
  }) async {
    await _db.collection('notifications').add({
      'userId': studentId,
      'title': 'Interview Scheduled',
      'body': 'Interview for "$jobTitle" — Round: $roundName\nDate: $dateTime\nVenue: $venue',
      'type': 'interview',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called when admin approves a job (notify the recruiter).
  static Future<void> onJobApproved({
    required String recruiterId,
    required String jobTitle,
  }) async {
    await _db.collection('notifications').add({
      'userId': recruiterId,
      'title': 'Job Approved',
      'body': 'Your job listing "$jobTitle" has been approved and is now visible to students!',
      'type': 'job_approved',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called when admin approves a recruiter account.
  static Future<void> onRecruiterApproved({
    required String recruiterId,
  }) async {
    await _db.collection('notifications').add({
      'userId': recruiterId,
      'title': 'Account Approved',
      'body': 'Your recruiter account has been verified. You can now post jobs!',
      'type': 'account_approved',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
