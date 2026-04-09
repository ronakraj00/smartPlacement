class ApplicationModel {
  final String id;
  final String studentId;
  final String jobId;
  final String status; // "Applied", "Shortlisted", "Interview", "Selected", "Rejected"

  ApplicationModel({
    required this.id,
    required this.studentId,
    required this.jobId,
    this.status = "Applied",
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ApplicationModel(
      id: documentId,
      studentId: data['studentId'] ?? '',
      jobId: data['jobId'] ?? '',
      status: data['status'] ?? 'Applied',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'jobId': jobId,
      'status': status,
    };
  }
}
