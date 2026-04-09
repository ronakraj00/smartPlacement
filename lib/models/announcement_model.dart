import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String priority; // 'normal', 'urgent'
  final String targetAudience; // 'all', 'students', 'recruiters', or branch codes
  final List<String> attachmentUrls;
  final String createdBy;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.priority = 'normal',
    this.targetAudience = 'all',
    this.attachmentUrls = const [],
    required this.createdBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> data, String docId) {
    return AnnouncementModel(
      id: docId,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      priority: data['priority'] ?? 'normal',
      targetAudience: data['targetAudience'] ?? 'all',
      attachmentUrls: data['attachmentUrls'] != null
          ? List<String>.from(data['attachmentUrls'])
          : [],
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'priority': priority,
    'targetAudience': targetAudience,
    'attachmentUrls': attachmentUrls,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
