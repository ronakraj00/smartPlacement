import 'package:cloud_firestore/cloud_firestore.dart';

/// Populates Firestore with realistic fake data for testing all platform features.
/// Triggered from the Admin Dashboard via a button.
class SeedDataService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await _seedStudents();
    await _seedRecruiters();
    await _seedJobs();
    await _seedApplications();
    await _seedInterviews();
    await _seedNotifications();
  }

  // ======================== STUDENTS ========================
  static final List<Map<String, dynamic>> _students = [
    {
      'id': 'student_001',
      'email': 'arjun.sharma@university.edu',
      'name': 'Arjun Sharma',
      'role': 'student',
      'cgpa': 8.5,
      'branch': 'CSE',
      'skills': ['Flutter', 'Dart', 'Firebase', 'Python', 'Machine Learning'],
      'projects': ['E-Commerce App', 'Chat Bot using NLP', 'Weather Forecast Dashboard'],
      'resumeUrl': 'https://drive.google.com/file/d/sample1',
      'about': 'Final year CSE student passionate about mobile development and AI.',
    },
    {
      'id': 'student_002',
      'email': 'priya.patel@university.edu',
      'name': 'Priya Patel',
      'role': 'student',
      'cgpa': 9.1,
      'branch': 'CSE',
      'skills': ['Java', 'Spring Boot', 'React', 'SQL', 'Docker', 'AWS'],
      'projects': ['Hospital Management System', 'Online Exam Portal'],
      'resumeUrl': 'https://drive.google.com/file/d/sample2',
      'about': 'Full-stack developer with a focus on enterprise applications.',
    },
    {
      'id': 'student_003',
      'email': 'rahul.verma@university.edu',
      'name': 'Rahul Verma',
      'role': 'student',
      'cgpa': 7.8,
      'branch': 'ECE',
      'skills': ['C++', 'Embedded Systems', 'MATLAB', 'Python', 'IoT'],
      'projects': ['Smart Home Automation', 'Drone Navigation System'],
      'resumeUrl': null,
      'about': 'ECE student interested in embedded systems and IoT.',
    },
    {
      'id': 'student_004',
      'email': 'sneha.gupta@university.edu',
      'name': 'Sneha Gupta',
      'role': 'student',
      'cgpa': 8.9,
      'branch': 'CSE',
      'skills': ['Python', 'TensorFlow', 'Data Science', 'SQL', 'Tableau'],
      'projects': ['Stock Price Predictor', 'Sentiment Analysis Tool', 'Customer Churn Model'],
      'resumeUrl': 'https://drive.google.com/file/d/sample4',
      'about': 'Aspiring Data Scientist with strong analytical skills.',
    },
    {
      'id': 'student_005',
      'email': 'vikram.singh@university.edu',
      'name': 'Vikram Singh',
      'role': 'student',
      'cgpa': 6.5,
      'branch': 'ME',
      'skills': ['AutoCAD', 'SolidWorks', 'Python', 'MATLAB'],
      'projects': ['CNC Machine Optimizer'],
      'resumeUrl': null,
      'about': 'Mechanical engineering student with a passion for automation.',
    },
    {
      'id': 'student_006',
      'email': 'ananya.reddy@university.edu',
      'name': 'Ananya Reddy',
      'role': 'student',
      'cgpa': 9.4,
      'branch': 'CSE',
      'skills': ['Flutter', 'Dart', 'React Native', 'Firebase', 'Node.js', 'MongoDB'],
      'projects': ['Food Delivery App', 'Social Media Clone', 'Task Manager with AI'],
      'resumeUrl': 'https://drive.google.com/file/d/sample6',
      'about': 'Top of the class. Passionate about cross-platform mobile development.',
    },
    {
      'id': 'student_007',
      'email': 'karan.mehta@university.edu',
      'name': 'Karan Mehta',
      'role': 'student',
      'cgpa': 7.2,
      'branch': 'CSE',
      'skills': ['JavaScript', 'React', 'Node.js', 'HTML', 'CSS'],
      'projects': ['Portfolio Website', 'Blog Platform'],
      'resumeUrl': null,
      'about': 'Frontend developer exploring full-stack.',
    },
    {
      'id': 'student_008',
      'email': 'neha.joshi@university.edu',
      'name': 'Neha Joshi',
      'role': 'student',
      'cgpa': 8.0,
      'branch': 'IT',
      'skills': ['Java', 'Kotlin', 'Android', 'Firebase', 'SQL'],
      'projects': ['Attendance Tracker App', 'Library Management System'],
      'resumeUrl': 'https://drive.google.com/file/d/sample8',
      'about': 'Android developer with a keen interest in mobile-first solutions.',
    },
  ];

  static Future<void> _seedStudents() async {
    for (var s in _students) {
      await _db.collection('users').doc(s['id']).set(s..remove('id'));
    }
  }

  // ======================== RECRUITERS ========================
  static final List<Map<String, dynamic>> _recruiters = [
    {
      'id': 'recruiter_google',
      'email': 'hr@google.com',
      'name': 'Sunita Kapoor (Google)',
      'role': 'recruiter',
      'accountStatus': 'approved',
    },
    {
      'id': 'recruiter_microsoft',
      'email': 'talent@microsoft.com',
      'name': 'Rajesh Nair (Microsoft)',
      'role': 'recruiter',
      'accountStatus': 'approved',
    },
    {
      'id': 'recruiter_infosys',
      'email': 'campus@infosys.com',
      'name': 'Meera Iyer (Infosys)',
      'role': 'recruiter',
      'accountStatus': 'approved',
    },
    {
      'id': 'recruiter_startup',
      'email': 'hiring@techstartup.io',
      'name': 'Amit Jain (NovaTech)',
      'role': 'recruiter',
      'accountStatus': 'pending',
    },
  ];

  static Future<void> _seedRecruiters() async {
    for (var r in _recruiters) {
      final id = r.remove('id');
      await _db.collection('users').doc(id).set(r);
    }
  }

  // ======================== JOBS ========================
  static Future<void> _seedJobs() async {
    final jobs = [
      {
        'id': 'job_google_sde',
        'recruiterId': 'recruiter_google',
        'company': 'Google',
        'role': 'Software Engineer (SDE-1)',
        'description': 'Join Google\'s core search team. You\'ll work on distributed systems serving billions of users. Strong DSA and system design skills required.',
        'requiredCgpa': 8.0,
        'requiredSkills': ['Python', 'Java', 'Data Structures', 'System Design'],
        'branchEligibility': 'CSE, IT',
        'status': 'approved',
        'location': 'Bangalore',
        'salary': '₹25 LPA',
        'jobType': 'Full-Time',
        'rounds': ['Applied', 'Online Assessment', 'Technical Interview 1', 'Technical Interview 2', 'HR Round'],
        'documentUrls': ['https://careers.google.com/sde1-jd.pdf'],
        'openPositions': 5,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 20))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'id': 'job_google_intern',
        'recruiterId': 'recruiter_google',
        'company': 'Google',
        'role': 'STEP Intern (Summer 2026)',
        'description': 'A 12-week summer internship for students who are early in their CS studies. Work on real Google products alongside full-time engineers.',
        'requiredCgpa': 7.5,
        'requiredSkills': ['Python', 'C++', 'Algorithms'],
        'branchEligibility': 'CSE',
        'status': 'approved',
        'location': 'Hyderabad',
        'salary': '₹80K/month stipend',
        'jobType': 'Intern',
        'rounds': ['Applied', 'Coding Challenge', 'Technical Phone Screen', 'Project Match'],
        'documentUrls': [],
        'openPositions': 10,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      },
      {
        'id': 'job_microsoft_sde',
        'recruiterId': 'recruiter_microsoft',
        'company': 'Microsoft',
        'role': 'Software Development Engineer',
        'description': 'Build the next generation of cloud services on Azure. We\'re looking for engineers who thrive in ambiguity and love tackling complex distributed problems.',
        'requiredCgpa': 7.0,
        'requiredSkills': ['Java', 'Spring Boot', 'Docker', 'AWS', 'System Design'],
        'branchEligibility': 'CSE, IT, ECE',
        'status': 'approved',
        'location': 'Noida',
        'salary': '₹22 LPA',
        'jobType': 'Full-Time',
        'rounds': ['Applied', 'Online Test', 'Group Discussion', 'Tech Interview', 'Managerial Round'],
        'documentUrls': ['https://microsoft.com/jd-sde.pdf'],
        'openPositions': 8,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'job_infosys_analyst',
        'recruiterId': 'recruiter_infosys',
        'company': 'Infosys',
        'role': 'Systems Engineer',
        'description': 'Come build enterprise solutions for global clients. Training provided through Infosys Mysore campus. Open to all branches.',
        'requiredCgpa': 6.0,
        'requiredSkills': ['SQL', 'Java', 'Communication'],
        'branchEligibility': '',
        'status': 'approved',
        'location': 'Mysore / Pune',
        'salary': '₹6.5 LPA',
        'jobType': 'Full-Time',
        'rounds': ['Applied', 'Aptitude Test', 'Technical Interview', 'HR Interview'],
        'documentUrls': [],
        'openPositions': 50,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 45))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      },
      {
        'id': 'job_infosys_intern',
        'recruiterId': 'recruiter_infosys',
        'company': 'Infosys',
        'role': 'InStep Intern (Data Science)',
        'description': 'Work on real-world data science problems in a structured internship program. Mentorship from industry experts.',
        'requiredCgpa': 7.5,
        'requiredSkills': ['Python', 'Data Science', 'SQL', 'Machine Learning'],
        'branchEligibility': 'CSE, IT',
        'status': 'approved',
        'location': 'Bangalore',
        'salary': '₹40K/month stipend',
        'jobType': 'Intern',
        'rounds': ['Applied', 'Resume Screening', 'Case Study', 'Final Interview'],
        'documentUrls': [],
        'openPositions': 15,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 25))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      },
      {
        'id': 'job_startup_flutter',
        'recruiterId': 'recruiter_startup',
        'company': 'NovaTech Solutions',
        'role': 'Flutter Developer',
        'description': 'Early-stage startup building an AI-powered EdTech platform. Looking for passionate Flutter devs to build our mobile experience from scratch.',
        'requiredCgpa': 0.0,
        'requiredSkills': ['Flutter', 'Dart', 'Firebase', 'REST APIs'],
        'branchEligibility': '',
        'status': 'pending',
        'location': 'Remote',
        'salary': '₹8 LPA + ESOPs',
        'jobType': 'Full-Time',
        'rounds': ['Applied', 'Take-Home Assignment', 'Technical Discussion', 'Culture Fit'],
        'documentUrls': [],
        'openPositions': 3,
        'deadline': null,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
    ];

    for (var j in jobs) {
      final id = j.remove('id');
      await _db.collection('jobs').doc(id as String).set(j);
    }
  }

  // ======================== APPLICATIONS ========================
  static Future<void> _seedApplications() async {
    final applications = [
      // Google SDE applications
      {'id': 'student_001_job_google_sde', 'studentId': 'student_001', 'jobId': 'job_google_sde', 'status': 'Technical Interview 1', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_002_job_google_sde', 'studentId': 'student_002', 'jobId': 'job_google_sde', 'status': 'Technical Interview 2', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_004_job_google_sde', 'studentId': 'student_004', 'jobId': 'job_google_sde', 'status': 'Online Assessment', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_006_job_google_sde', 'studentId': 'student_006', 'jobId': 'job_google_sde', 'status': 'HR Round', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_007_job_google_sde', 'studentId': 'student_007', 'jobId': 'job_google_sde', 'status': 'Rejected', 'rejectionFeedback': 'Needs stronger DSA fundamentals. Consider practicing competitive programming.', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},

      // Google Intern applications
      {'id': 'student_001_job_google_intern', 'studentId': 'student_001', 'jobId': 'job_google_intern', 'status': 'Coding Challenge', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},
      {'id': 'student_006_job_google_intern', 'studentId': 'student_006', 'jobId': 'job_google_intern', 'status': 'Technical Phone Screen', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},

      // Microsoft applications
      {'id': 'student_002_job_microsoft_sde', 'studentId': 'student_002', 'jobId': 'job_microsoft_sde', 'status': 'Tech Interview', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_003_job_microsoft_sde', 'studentId': 'student_003', 'jobId': 'job_microsoft_sde', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)))},
      {'id': 'student_007_job_microsoft_sde', 'studentId': 'student_007', 'jobId': 'job_microsoft_sde', 'status': 'Online Test', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_008_job_microsoft_sde', 'studentId': 'student_008', 'jobId': 'job_microsoft_sde', 'status': 'Group Discussion', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},

      // Infosys Systems Engineer — mass hiring
      {'id': 'student_003_job_infosys_analyst', 'studentId': 'student_003', 'jobId': 'job_infosys_analyst', 'status': 'Technical Interview', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)))},
      {'id': 'student_005_job_infosys_analyst', 'studentId': 'student_005', 'jobId': 'job_infosys_analyst', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)))},
      {'id': 'student_007_job_infosys_analyst', 'studentId': 'student_007', 'jobId': 'job_infosys_analyst', 'status': 'Aptitude Test', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},
      {'id': 'student_008_job_infosys_analyst', 'studentId': 'student_008', 'jobId': 'job_infosys_analyst', 'status': 'Rejected', 'rejectionFeedback': 'Could not clear aptitude round. Better luck next time!', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)))},

      // Infosys DS Intern
      {'id': 'student_004_job_infosys_intern', 'studentId': 'student_004', 'jobId': 'job_infosys_intern', 'status': 'Case Study', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6)))},
      {'id': 'student_001_job_infosys_intern', 'studentId': 'student_001', 'jobId': 'job_infosys_intern', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
    ];

    for (var app in applications) {
      final id = app.remove('id');
      await _db.collection('applications').doc(id as String).set(app);
    }
  }

  // ======================== INTERVIEWS ========================
  static Future<void> _seedInterviews() async {
    final interviews = [
      {
        'jobId': 'job_google_sde',
        'studentId': 'student_001',
        'roundName': 'Technical Interview 1',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2, hours: 10))),
        'venue': 'Google Meet (Virtual)',
        'mode': 'online',
        'meetingLink': 'https://meet.google.com/abc-defg-hij',
        'notes': 'Focus on DSA + System Design. 45 min duration.',
      },
      {
        'jobId': 'job_google_sde',
        'studentId': 'student_002',
        'roundName': 'Technical Interview 2',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3, hours: 14))),
        'venue': 'Google Meet (Virtual)',
        'mode': 'online',
        'meetingLink': 'https://meet.google.com/xyz-abcd-efg',
        'notes': 'Deep dive into past projects. Be ready to explain architecture decisions.',
      },
      {
        'jobId': 'job_google_sde',
        'studentId': 'student_006',
        'roundName': 'HR Round',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5, hours: 11))),
        'venue': 'Room 301, Placement Cell',
        'mode': 'offline',
        'meetingLink': null,
        'notes': 'Bring original documents. 30 min round.',
      },
      {
        'jobId': 'job_microsoft_sde',
        'studentId': 'student_002',
        'roundName': 'Tech Interview',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4, hours: 9))),
        'venue': 'Microsoft Teams',
        'mode': 'online',
        'meetingLink': 'https://teams.microsoft.com/meet/12345',
        'notes': 'Coding + low-level design round. Use any language.',
      },
      {
        'jobId': 'job_infosys_analyst',
        'studentId': 'student_003',
        'roundName': 'Technical Interview',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1, hours: 15))),
        'venue': 'Seminar Hall B',
        'mode': 'offline',
        'meetingLink': null,
        'notes': 'Panel interview. Carry resume hard copy.',
      },
      {
        'jobId': 'job_infosys_intern',
        'studentId': 'student_004',
        'roundName': 'Case Study',
        'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 6, hours: 10))),
        'venue': 'Zoom',
        'mode': 'online',
        'meetingLink': 'https://zoom.us/j/98765432',
        'notes': 'You will be given a dataset. Prepare Jupyter Notebook.',
      },
    ];

    for (var i in interviews) {
      await _db.collection('interviews').add(i);
    }
  }

  // ======================== NOTIFICATIONS ========================
  static Future<void> _seedNotifications() async {
    final notifications = [
      {
        'userId': 'student_001',
        'title': 'Application Update',
        'body': 'Your application for "Software Engineer (SDE-1)" at Google has been updated to: Technical Interview 1',
        'type': 'status_change',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
      },
      {
        'userId': 'student_001',
        'title': 'Interview Scheduled',
        'body': 'Interview for "Software Engineer (SDE-1)" at Google — Round: Technical Interview 1\nDate: ${DateTime.now().add(const Duration(days: 2)).day}/${DateTime.now().add(const Duration(days: 2)).month}\nVenue: Google Meet (Virtual)',
        'type': 'interview',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      },
      {
        'userId': 'student_002',
        'title': 'Application Update',
        'body': 'Your application for "Software Engineer (SDE-1)" at Google has been updated to: Technical Interview 2',
        'type': 'status_change',
        'read': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'userId': 'student_006',
        'title': 'Interview Scheduled',
        'body': 'Interview for "Software Engineer (SDE-1)" at Google — Round: HR Round\nVenue: Room 301, Placement Cell',
        'type': 'interview',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
      },
      {
        'userId': 'student_007',
        'title': 'Application Rejected',
        'body': 'Your application for "Software Engineer (SDE-1)" at Google has been rejected.\nFeedback: Needs stronger DSA fundamentals. Consider practicing competitive programming.',
        'type': 'status_change',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 8))),
      },
      {
        'userId': 'student_004',
        'title': 'Interview Scheduled',
        'body': 'Interview for "InStep Intern (Data Science)" at Infosys — Round: Case Study\nVenue: Zoom',
        'type': 'interview',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      },
      {
        'userId': 'recruiter_google',
        'title': 'Job Approved',
        'body': 'Your job listing "Software Engineer (SDE-1) at Google" has been approved and is now visible to students!',
        'type': 'job_approved',
        'read': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'userId': 'recruiter_microsoft',
        'title': 'Job Approved',
        'body': 'Your job listing "Software Development Engineer at Microsoft" has been approved!',
        'type': 'job_approved',
        'read': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
    ];

    for (var n in notifications) {
      await _db.collection('notifications').add(n);
    }
  }

  /// Deletes all seeded test data
  static Future<void> clearAll() async {
    await _clearCollection('interviews');
    await _clearCollection('notifications');

    // Clear seeded applications
    final appIds = [
      'student_001_job_google_sde', 'student_002_job_google_sde', 'student_004_job_google_sde',
      'student_006_job_google_sde', 'student_007_job_google_sde',
      'student_001_job_google_intern', 'student_006_job_google_intern',
      'student_002_job_microsoft_sde', 'student_003_job_microsoft_sde',
      'student_007_job_microsoft_sde', 'student_008_job_microsoft_sde',
      'student_003_job_infosys_analyst', 'student_005_job_infosys_analyst',
      'student_007_job_infosys_analyst', 'student_008_job_infosys_analyst',
      'student_004_job_infosys_intern', 'student_001_job_infosys_intern',
    ];
    for (var id in appIds) {
      await _db.collection('applications').doc(id).delete();
    }

    // Clear seeded jobs
    final jobIds = ['job_google_sde', 'job_google_intern', 'job_microsoft_sde', 'job_infosys_analyst', 'job_infosys_intern', 'job_startup_flutter'];
    for (var id in jobIds) {
      await _db.collection('jobs').doc(id).delete();
    }

    // Clear seeded users
    final userIds = ['student_001', 'student_002', 'student_003', 'student_004', 'student_005', 'student_006', 'student_007', 'student_008', 'recruiter_google', 'recruiter_microsoft', 'recruiter_infosys', 'recruiter_startup'];
    for (var id in userIds) {
      await _db.collection('users').doc(id).delete();
    }
  }

  static Future<void> _clearCollection(String name) async {
    final snap = await _db.collection(name).get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
