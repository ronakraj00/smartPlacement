class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? collegeId;

  // Personal
  final String? phone;
  final String? dob;
  final String? gender;
  final String? address;
  final String? profilePhotoUrl;

  // Academic
  final double? cgpa;
  final String? branch;
  final int? graduationYear;
  final int? semester;
  final int? activeBacklogs;
  final int? totalBacklogs;
  final double? attendance;

  // Education History
  final Map<String, dynamic>? class10th; // {board, percentage, year}
  final Map<String, dynamic>? class12th; // {board, percentage, year}

  // Professional
  final List<String>? skills;
  final List<String>? projects;
  final String? resumeUrl;
  final String? about;
  final List<Map<String, dynamic>>? certifications; // [{name, issuer, url}]
  final List<Map<String, dynamic>>? workExperience; // [{company, role, duration, description}]

  // Social
  final Map<String, String>? socialLinks; // {linkedin, github, portfolio, leetcode}

  // Placement
  final String? placementStatus; // 'not_placed', 'placed', 'opted_out'
  final int offersReceived;

  // Recruiter
  final String? accountStatus;
  final String? companyName; // recruiter's company

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.collegeId,
    this.phone,
    this.dob,
    this.gender,
    this.address,
    this.profilePhotoUrl,
    this.cgpa,
    this.branch,
    this.graduationYear,
    this.semester,
    this.activeBacklogs,
    this.totalBacklogs,
    this.attendance,
    this.class10th,
    this.class12th,
    this.skills,
    this.projects,
    this.resumeUrl,
    this.about,
    this.certifications,
    this.workExperience,
    this.socialLinks,
    this.placementStatus,
    this.offersReceived = 0,
    this.accountStatus,
    this.companyName,
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
      collegeId: data['collegeId'],
      phone: data['phone'],
      dob: data['dob'],
      gender: data['gender'],
      address: data['address'],
      profilePhotoUrl: data['profilePhotoUrl'],
      cgpa: data['cgpa']?.toDouble(),
      branch: data['branch'],
      graduationYear: data['graduationYear'],
      semester: data['semester'],
      activeBacklogs: data['activeBacklogs'],
      totalBacklogs: data['totalBacklogs'],
      attendance: data['attendance']?.toDouble(),
      class10th: data['class10th'] != null ? Map<String, dynamic>.from(data['class10th']) : null,
      class12th: data['class12th'] != null ? Map<String, dynamic>.from(data['class12th']) : null,
      skills: data['skills'] != null ? List<String>.from(data['skills']) : null,
      projects: data['projects'] != null ? List<String>.from(data['projects']) : null,
      resumeUrl: data['resumeUrl'],
      about: data['about'],
      certifications: data['certifications'] != null
          ? List<Map<String, dynamic>>.from(
              (data['certifications'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      workExperience: data['workExperience'] != null
          ? List<Map<String, dynamic>>.from(
              (data['workExperience'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      socialLinks: data['socialLinks'] != null
          ? Map<String, String>.from(data['socialLinks'])
          : null,
      placementStatus: data['placementStatus'],
      offersReceived: data['offersReceived'] ?? 0,
      accountStatus: data['accountStatus'],
      companyName: data['companyName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'collegeId': collegeId,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'address': address,
      'profilePhotoUrl': profilePhotoUrl,
      'cgpa': cgpa,
      'branch': branch,
      'graduationYear': graduationYear,
      'semester': semester,
      'activeBacklogs': activeBacklogs,
      'totalBacklogs': totalBacklogs,
      'attendance': attendance,
      'class10th': class10th,
      'class12th': class12th,
      'skills': skills,
      'projects': projects,
      'resumeUrl': resumeUrl,
      'about': about,
      'certifications': certifications,
      'workExperience': workExperience,
      'socialLinks': socialLinks,
      'placementStatus': placementStatus,
      'offersReceived': offersReceived,
      'accountStatus': accountStatus,
      'companyName': companyName,
    };
  }

  int get profileCompleteness {
    int filled = 0;
    int total = 14;
    if (phone != null && phone!.isNotEmpty) filled++;
    if (dob != null && dob!.isNotEmpty) filled++;
    if (gender != null && gender!.isNotEmpty) filled++;
    if (cgpa != null) filled++;
    if (branch != null && branch!.isNotEmpty) filled++;
    if (about != null && about!.isNotEmpty) filled++;
    if (skills != null && skills!.isNotEmpty) filled++;
    if (projects != null && projects!.isNotEmpty) filled++;
    if (resumeUrl != null && resumeUrl!.isNotEmpty) filled++;
    if (class10th != null) filled++;
    if (class12th != null) filled++;
    if (certifications != null && certifications!.isNotEmpty) filled++;
    if (workExperience != null && workExperience!.isNotEmpty) filled++;
    if (socialLinks != null && socialLinks!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }
}

enum UserRole {
  student,
  recruiter,
  admin
}
