class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  
  // Student-specific fields
  final double? cgpa;
  final String? branch;
  final List<String>? skills;
  final List<String>? projects;
  final String? resumeUrl;
  final String? about;

  // Recruiter-specific fields
  final String? accountStatus; // 'pending' or 'approved' (for recruiters)

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.cgpa,
    this.branch,
    this.skills,
    this.projects,
    this.resumeUrl,
    this.about,
    this.accountStatus,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.student,
      ),
      cgpa: data['cgpa']?.toDouble(),
      branch: data['branch'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : null,
      projects: data['projects'] != null ? List<String>.from(data['projects']) : null,
      resumeUrl: data['resumeUrl'],
      about: data['about'],
      accountStatus: data['accountStatus'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'cgpa': cgpa,
      'branch': branch,
      'skills': skills,
      'projects': projects,
      'resumeUrl': resumeUrl,
      'about': about,
      'accountStatus': accountStatus,
    };
  }
}

enum UserRole {
  student,
  recruiter,
  admin
}
