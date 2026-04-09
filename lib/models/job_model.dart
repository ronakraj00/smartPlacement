import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String recruiterId;
  final String company;
  final String role;
  final String description;
  final double requiredCgpa;
  final List<String> requiredSkills;
  final String? branchEligibility;
  
  final String status;
  final String location;
  final String salary;
  final String jobType;
  final List<String> rounds;
  final List<String> documentUrls;

  // New fields
  final DateTime? deadline;
  final DateTime? postedAt;
  final int openPositions;

  JobModel({
    required this.id,
    required this.recruiterId,
    required this.company,
    required this.role,
    required this.description,
    this.requiredCgpa = 0.0,
    this.requiredSkills = const [],
    this.branchEligibility,
    this.status = 'pending',
    this.location = '',
    this.salary = '',
    this.jobType = '',
    this.rounds = const ['Applied'],
    this.documentUrls = const [],
    this.deadline,
    this.postedAt,
    this.openPositions = 0,
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String documentId) {
    return JobModel(
      id: documentId,
      recruiterId: data['recruiterId'] ?? '',
      company: data['company'] ?? '',
      role: data['role'] ?? '',
      description: data['description'] ?? '',
      requiredCgpa: data['requiredCgpa']?.toDouble() ?? 0.0,
      requiredSkills: data['requiredSkills'] != null
          ? List<String>.from(data['requiredSkills'])
          : [],
      branchEligibility: data['branchEligibility'],
      status: data['status'] ?? 'pending',
      location: data['location'] ?? '',
      salary: data['salary'] ?? '',
      jobType: data['jobType'] ?? '',
      rounds: data['rounds'] != null ? List<String>.from(data['rounds']) : ['Applied'],
      documentUrls: data['documentUrls'] != null ? List<String>.from(data['documentUrls']) : [],
      deadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
      postedAt: data['postedAt'] != null || data['createdAt'] != null
          ? ((data['postedAt'] ?? data['createdAt']) as Timestamp).toDate()
          : null,
      openPositions: data['openPositions'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recruiterId': recruiterId,
      'company': company,
      'role': role,
      'description': description,
      'requiredCgpa': requiredCgpa,
      'requiredSkills': requiredSkills,
      'branchEligibility': branchEligibility,
      'status': status,
      'location': location,
      'salary': salary,
      'jobType': jobType,
      'rounds': rounds,
      'documentUrls': documentUrls,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'postedAt': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'openPositions': openPositions,
    };
  }

  bool get isExpired => deadline != null && DateTime.now().isAfter(deadline!);
  
  int get daysRemaining => deadline != null ? deadline!.difference(DateTime.now()).inDays : -1;
}
