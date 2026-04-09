import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  final String id;
  final String jobId;
  final String studentId;
  final String company;
  final String role;
  final double ctcLpa;
  final String? offerLetterUrl;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime offeredAt;
  final DateTime? responseDeadline;
  final String tier; // 'Normal', 'Dream', 'Super Dream'

  OfferModel({
    required this.id,
    required this.jobId,
    required this.studentId,
    required this.company,
    required this.role,
    required this.ctcLpa,
    this.offerLetterUrl,
    this.status = 'pending',
    required this.offeredAt,
    this.responseDeadline,
    this.tier = 'Normal',
  });

  factory OfferModel.fromMap(Map<String, dynamic> data, String docId) {
    return OfferModel(
      id: docId,
      jobId: data['jobId'] ?? '',
      studentId: data['studentId'] ?? '',
      company: data['company'] ?? '',
      role: data['role'] ?? '',
      ctcLpa: (data['ctcLpa'] ?? 0.0).toDouble(),
      offerLetterUrl: data['offerLetterUrl'],
      status: data['status'] ?? 'pending',
      offeredAt: data['offeredAt'] != null
          ? (data['offeredAt'] as Timestamp).toDate()
          : DateTime.now(),
      responseDeadline: data['responseDeadline'] != null
          ? (data['responseDeadline'] as Timestamp).toDate()
          : null,
      tier: data['tier'] ?? 'Normal',
    );
  }

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'studentId': studentId,
    'company': company,
    'role': role,
    'ctcLpa': ctcLpa,
    'offerLetterUrl': offerLetterUrl,
    'status': status,
    'offeredAt': Timestamp.fromDate(offeredAt),
    'responseDeadline': responseDeadline != null ? Timestamp.fromDate(responseDeadline!) : null,
    'tier': tier,
  };

  bool get isExpired => responseDeadline != null && DateTime.now().isAfter(responseDeadline!) && status == 'pending';
}
