import 'package:cloud_firestore/cloud_firestore.dart';

/// Populates Firestore with realistic fake data for ALL platform features.
class SeedDataService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await _seedCollege();
    await _seedCompanies();
    await _seedStudents();
    await _seedRecruiters();
    await _seedJobs();
    await _seedApplications();
    await _seedInterviews();
    await _seedOffers();
    await _seedAnnouncements();
    await _seedNotifications();
  }

  // ======================== COLLEGE ========================
  static Future<void> _seedCollege() async {
    await _db.collection('colleges').doc('college_main').set({
      'name': 'National Institute of Technology Patna',
      'code': 'NITP',
      'address': 'Ashok Rajpath, Patna, Bihar 800005',
      'placementBatch': '2025-26',
      'policy': {
        'maxOffers': 2,
        'dreamCtcThreshold': 15.0,
        'superDreamCtcThreshold': 25.0,
        'blockAfterDream': true,
        'allowedActiveBacklogs': 0,
        'minCgpa': 6.0,
        'minAttendance': 75.0,
      },
    });
  }

  // ======================== COMPANIES ========================
  static Future<void> _seedCompanies() async {
    final companies = [
      {
        'id': 'company_google',
        'name': 'Google',
        'industry': 'Technology / Internet',
        'website': 'https://careers.google.com',
        'description': 'Google LLC is a multinational technology company specializing in internet-related services and products. From search to cloud to AI, Google is at the forefront of innovation.',
        'headquarters': 'Mountain View, California',
        'employeeCount': '180,000+',
        'avgRating': 4.8,
        'pastVisitYears': ['2023-24', '2024-25', '2025-26'],
      },
      {
        'id': 'company_microsoft',
        'name': 'Microsoft',
        'industry': 'Technology / Software',
        'website': 'https://careers.microsoft.com',
        'description': 'Microsoft Corporation builds industry-defining platforms, from Azure to Office 365 to Xbox. We empower every person and every organization on the planet to achieve more.',
        'headquarters': 'Redmond, Washington',
        'employeeCount': '220,000+',
        'avgRating': 4.6,
        'pastVisitYears': ['2022-23', '2024-25', '2025-26'],
      },
      {
        'id': 'company_infosys',
        'name': 'Infosys',
        'industry': 'IT Services / Consulting',
        'website': 'https://www.infosys.com/careers',
        'description': 'Infosys Limited is a global leader in next-generation digital services and consulting. We enable clients in over 50 countries to navigate their digital transformation.',
        'headquarters': 'Bangalore, India',
        'employeeCount': '340,000+',
        'avgRating': 3.9,
        'pastVisitYears': ['2021-22', '2022-23', '2023-24', '2024-25', '2025-26'],
      },
      {
        'id': 'company_novatech',
        'name': 'NovaTech Solutions',
        'industry': 'EdTech / AI Startup',
        'website': 'https://novatech.io',
        'description': 'NovaTech is an early-stage AI-powered EdTech startup backed by Y Combinator. We are building the future of personalized learning.',
        'headquarters': 'Remote (India)',
        'employeeCount': '25',
        'avgRating': 4.2,
        'pastVisitYears': ['2025-26'],
      },
    ];
    for (var c in companies) {
      final id = c.remove('id');
      await _db.collection('companies').doc(id as String).set(c);
    }
  }

  // ======================== STUDENTS ========================
  static Future<void> _seedStudents() async {
    final students = [
      {
        'id': 'student_001',
        'email': 'arjun.sharma@nitp.edu',
        'name': 'Arjun Sharma',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543210',
        'dob': '15/03/2003',
        'gender': 'Male',
        'cgpa': 8.5,
        'branch': 'CSE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 92.0,
        'class10th': {'board': 'CBSE', 'percentage': 94.2, 'year': 2019},
        'class12th': {'board': 'CBSE', 'percentage': 89.6, 'year': 2021},
        'skills': ['Flutter', 'Dart', 'Firebase', 'Python', 'Machine Learning'],
        'projects': ['E-Commerce App', 'Chat Bot using NLP', 'Weather Forecast Dashboard'],
        'certifications': [{'name': 'Google Cloud Associate', 'issuer': 'Google', 'url': ''}],
        'workExperience': [{'company': 'Google (Intern)', 'role': 'SWE Intern', 'duration': '3 months', 'description': 'Worked on Search UI improvements'}],
        'socialLinks': {'linkedin': 'https://linkedin.com/in/arjun-sharma', 'github': 'https://github.com/arjunsharma', 'leetcode': 'https://leetcode.com/arjun_sharma'},
        'resumeUrl': 'https://drive.google.com/file/d/sample1',
        'about': 'Final year CSE student passionate about mobile development and AI.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_002',
        'email': 'priya.patel@nitp.edu',
        'name': 'Priya Patel',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543211',
        'dob': '22/08/2003',
        'gender': 'Female',
        'cgpa': 9.1,
        'branch': 'CSE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 95.0,
        'class10th': {'board': 'ICSE', 'percentage': 96.0, 'year': 2019},
        'class12th': {'board': 'ISC', 'percentage': 93.2, 'year': 2021},
        'skills': ['Java', 'Spring Boot', 'React', 'SQL', 'Docker', 'AWS'],
        'projects': ['Hospital Management System', 'Online Exam Portal'],
        'certifications': [{'name': 'AWS Solutions Architect', 'issuer': 'Amazon', 'url': ''}],
        'socialLinks': {'linkedin': 'https://linkedin.com/in/priya-patel', 'github': 'https://github.com/priyapatel'},
        'resumeUrl': 'https://drive.google.com/file/d/sample2',
        'about': 'Full-stack developer with a focus on enterprise applications.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_003',
        'email': 'rahul.verma@nitp.edu',
        'name': 'Rahul Verma',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543212',
        'dob': '10/11/2003',
        'gender': 'Male',
        'cgpa': 7.8,
        'branch': 'ECE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 1,
        'attendance': 80.0,
        'class10th': {'board': 'State Board', 'percentage': 88.0, 'year': 2019},
        'class12th': {'board': 'State Board', 'percentage': 82.0, 'year': 2021},
        'skills': ['C++', 'Embedded Systems', 'MATLAB', 'Python', 'IoT'],
        'projects': ['Smart Home Automation', 'Drone Navigation System'],
        'about': 'ECE student interested in embedded systems and IoT.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_004',
        'email': 'sneha.gupta@nitp.edu',
        'name': 'Sneha Gupta',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543213',
        'dob': '05/06/2003',
        'gender': 'Female',
        'cgpa': 8.9,
        'branch': 'CSE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 88.0,
        'class10th': {'board': 'CBSE', 'percentage': 91.0, 'year': 2019},
        'class12th': {'board': 'CBSE', 'percentage': 87.5, 'year': 2021},
        'skills': ['Python', 'TensorFlow', 'Data Science', 'SQL', 'Tableau'],
        'projects': ['Stock Price Predictor', 'Sentiment Analysis Tool', 'Customer Churn Model'],
        'certifications': [{'name': 'TensorFlow Developer', 'issuer': 'Google', 'url': ''}, {'name': 'Data Science Specialization', 'issuer': 'Coursera', 'url': ''}],
        'socialLinks': {'linkedin': 'https://linkedin.com/in/sneha-gupta', 'leetcode': 'https://leetcode.com/sneha_gupta'},
        'resumeUrl': 'https://drive.google.com/file/d/sample4',
        'about': 'Aspiring Data Scientist with strong analytical skills.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_005',
        'email': 'vikram.singh@nitp.edu',
        'name': 'Vikram Singh',
        'role': 'student',
        'collegeId': 'college_main',
        'gender': 'Male',
        'cgpa': 6.5,
        'branch': 'ME',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 1,
        'totalBacklogs': 3,
        'attendance': 72.0,
        'skills': ['AutoCAD', 'SolidWorks', 'Python', 'MATLAB'],
        'projects': ['CNC Machine Optimizer'],
        'about': 'Mechanical engineering student with a passion for automation.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_006',
        'email': 'ananya.reddy@nitp.edu',
        'name': 'Ananya Reddy',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543215',
        'dob': '01/01/2004',
        'gender': 'Female',
        'cgpa': 9.4,
        'branch': 'CSE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 97.0,
        'class10th': {'board': 'CBSE', 'percentage': 98.6, 'year': 2020},
        'class12th': {'board': 'CBSE', 'percentage': 96.4, 'year': 2022},
        'skills': ['Flutter', 'Dart', 'React Native', 'Firebase', 'Node.js', 'MongoDB'],
        'projects': ['Food Delivery App', 'Social Media Clone', 'Task Manager with AI'],
        'certifications': [{'name': 'Meta React Native', 'issuer': 'Meta', 'url': ''}],
        'workExperience': [{'company': 'Microsoft (Intern)', 'role': 'Mobile Dev Intern', 'duration': '2 months', 'description': 'Built Outlook mobile features'}],
        'socialLinks': {'linkedin': 'https://linkedin.com/in/ananya-reddy', 'github': 'https://github.com/ananyareddy', 'portfolio': 'https://ananyareddy.dev'},
        'resumeUrl': 'https://drive.google.com/file/d/sample6',
        'about': 'Top of the class. Passionate about cross-platform mobile development.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_007',
        'email': 'karan.mehta@nitp.edu',
        'name': 'Karan Mehta',
        'role': 'student',
        'collegeId': 'college_main',
        'gender': 'Male',
        'cgpa': 7.2,
        'branch': 'CSE',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 78.0,
        'skills': ['JavaScript', 'React', 'Node.js', 'HTML', 'CSS'],
        'projects': ['Portfolio Website', 'Blog Platform'],
        'about': 'Frontend developer exploring full-stack.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
      {
        'id': 'student_008',
        'email': 'neha.joshi@nitp.edu',
        'name': 'Neha Joshi',
        'role': 'student',
        'collegeId': 'college_main',
        'phone': '9876543217',
        'dob': '19/12/2003',
        'gender': 'Female',
        'cgpa': 8.0,
        'branch': 'IT',
        'semester': 8,
        'graduationYear': 2026,
        'activeBacklogs': 0,
        'totalBacklogs': 0,
        'attendance': 85.0,
        'class10th': {'board': 'CBSE', 'percentage': 90.0, 'year': 2019},
        'class12th': {'board': 'CBSE', 'percentage': 85.0, 'year': 2021},
        'skills': ['Java', 'Kotlin', 'Android', 'Firebase', 'SQL'],
        'projects': ['Attendance Tracker App', 'Library Management System'],
        'resumeUrl': 'https://drive.google.com/file/d/sample8',
        'about': 'Android developer with a keen interest in mobile-first solutions.',
        'placementStatus': 'not_placed',
        'offersReceived': 0,
      },
    ];
    for (var s in students) {
      final id = s.remove('id');
      await _db.collection('users').doc(id as String).set(s);
    }
  }

  // ======================== RECRUITERS ========================
  static Future<void> _seedRecruiters() async {
    final recruiters = [
      {'id': 'recruiter_google', 'email': 'hr@google.com', 'name': 'Sunita Kapoor', 'role': 'recruiter', 'accountStatus': 'approved', 'companyName': 'Google'},
      {'id': 'recruiter_microsoft', 'email': 'talent@microsoft.com', 'name': 'Rajesh Nair', 'role': 'recruiter', 'accountStatus': 'approved', 'companyName': 'Microsoft'},
      {'id': 'recruiter_infosys', 'email': 'campus@infosys.com', 'name': 'Meera Iyer', 'role': 'recruiter', 'accountStatus': 'approved', 'companyName': 'Infosys'},
      {'id': 'recruiter_startup', 'email': 'hiring@novatech.io', 'name': 'Amit Jain', 'role': 'recruiter', 'accountStatus': 'pending', 'companyName': 'NovaTech Solutions'},
    ];
    for (var r in recruiters) {
      final id = r.remove('id');
      await _db.collection('users').doc(id as String).set(r);
    }
  }

  // ======================== JOBS ========================
  static Future<void> _seedJobs() async {
    final jobs = [
      {
        'id': 'job_google_sde',
        'recruiterId': 'recruiter_google', 'company': 'Google', 'companyId': 'company_google',
        'role': 'Software Engineer (SDE-1)',
        'description': 'Join Google\'s core search team. Work on distributed systems serving billions.',
        'requiredCgpa': 8.0, 'requiredSkills': ['Python', 'Java', 'Data Structures', 'System Design'],
        'branchEligibility': 'CSE, IT', 'status': 'approved',
        'location': 'Bangalore', 'salary': '₹25 LPA', 'jobType': 'Full-Time', 'ctcLpa': 25.0,
        'rounds': ['Applied', 'Online Assessment', 'Technical Interview 1', 'Technical Interview 2', 'HR Round'],
        'documentUrls': ['https://careers.google.com/sde1-jd.pdf'],
        'openPositions': 5,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 20))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
      {
        'id': 'job_google_intern',
        'recruiterId': 'recruiter_google', 'company': 'Google', 'companyId': 'company_google',
        'role': 'STEP Intern (Summer 2026)',
        'description': 'A 12-week summer internship on real Google products.',
        'requiredCgpa': 7.5, 'requiredSkills': ['Python', 'C++', 'Algorithms'],
        'branchEligibility': 'CSE', 'status': 'approved',
        'location': 'Hyderabad', 'salary': '₹80K/month', 'jobType': 'Intern', 'ctcLpa': 9.6,
        'rounds': ['Applied', 'Coding Challenge', 'Technical Phone Screen', 'Project Match'],
        'documentUrls': [], 'openPositions': 10,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
      },
      {
        'id': 'job_microsoft_sde',
        'recruiterId': 'recruiter_microsoft', 'company': 'Microsoft', 'companyId': 'company_microsoft',
        'role': 'Software Development Engineer',
        'description': 'Build Azure cloud services at massive scale.',
        'requiredCgpa': 7.0, 'requiredSkills': ['Java', 'Spring Boot', 'Docker', 'AWS'],
        'branchEligibility': 'CSE, IT, ECE', 'status': 'approved',
        'location': 'Noida', 'salary': '₹22 LPA', 'jobType': 'Full-Time', 'ctcLpa': 22.0,
        'rounds': ['Applied', 'Online Test', 'Group Discussion', 'Tech Interview', 'Managerial Round'],
        'documentUrls': [], 'openPositions': 8,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'job_infosys_analyst',
        'recruiterId': 'recruiter_infosys', 'company': 'Infosys', 'companyId': 'company_infosys',
        'role': 'Systems Engineer',
        'description': 'Enterprise solutions for global clients. Training at Mysore campus.',
        'requiredCgpa': 6.0, 'requiredSkills': ['SQL', 'Java', 'Communication'],
        'branchEligibility': '', 'status': 'approved',
        'location': 'Mysore / Pune', 'salary': '₹6.5 LPA', 'jobType': 'Full-Time', 'ctcLpa': 6.5,
        'rounds': ['Applied', 'Aptitude Test', 'Technical Interview', 'HR Interview'],
        'documentUrls': [], 'openPositions': 50,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 45))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
      },
      {
        'id': 'job_infosys_intern',
        'recruiterId': 'recruiter_infosys', 'company': 'Infosys', 'companyId': 'company_infosys',
        'role': 'InStep Intern (Data Science)',
        'description': 'Real-world data science problems with mentorship.',
        'requiredCgpa': 7.5, 'requiredSkills': ['Python', 'Data Science', 'SQL', 'Machine Learning'],
        'branchEligibility': 'CSE, IT', 'status': 'approved',
        'location': 'Bangalore', 'salary': '₹40K/month', 'jobType': 'Intern', 'ctcLpa': 4.8,
        'rounds': ['Applied', 'Resume Screening', 'Case Study', 'Final Interview'],
        'documentUrls': [], 'openPositions': 15,
        'deadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 25))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      },
      {
        'id': 'job_startup_flutter',
        'recruiterId': 'recruiter_startup', 'company': 'NovaTech Solutions', 'companyId': 'company_novatech',
        'role': 'Flutter Developer',
        'description': 'AI-powered EdTech startup. Build our mobile experience from scratch.',
        'requiredCgpa': 0.0, 'requiredSkills': ['Flutter', 'Dart', 'Firebase', 'REST APIs'],
        'branchEligibility': '', 'status': 'pending',
        'location': 'Remote', 'salary': '₹8 LPA + ESOPs', 'jobType': 'Full-Time', 'ctcLpa': 8.0,
        'rounds': ['Applied', 'Take-Home Assignment', 'Technical Discussion', 'Culture Fit'],
        'documentUrls': [], 'openPositions': 3,
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
    final apps = [
      {'id': 'student_001_job_google_sde', 'studentId': 'student_001', 'jobId': 'job_google_sde', 'status': 'Technical Interview 1', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_002_job_google_sde', 'studentId': 'student_002', 'jobId': 'job_google_sde', 'status': 'Technical Interview 2', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_004_job_google_sde', 'studentId': 'student_004', 'jobId': 'job_google_sde', 'status': 'Online Assessment', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_006_job_google_sde', 'studentId': 'student_006', 'jobId': 'job_google_sde', 'status': 'HR Round', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_007_job_google_sde', 'studentId': 'student_007', 'jobId': 'job_google_sde', 'status': 'Rejected', 'rejectionFeedback': 'Needs stronger DSA fundamentals.', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
      {'id': 'student_001_job_google_intern', 'studentId': 'student_001', 'jobId': 'job_google_intern', 'status': 'Coding Challenge', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},
      {'id': 'student_006_job_google_intern', 'studentId': 'student_006', 'jobId': 'job_google_intern', 'status': 'Technical Phone Screen', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},
      {'id': 'student_002_job_microsoft_sde', 'studentId': 'student_002', 'jobId': 'job_microsoft_sde', 'status': 'Tech Interview', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_003_job_microsoft_sde', 'studentId': 'student_003', 'jobId': 'job_microsoft_sde', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)))},
      {'id': 'student_007_job_microsoft_sde', 'studentId': 'student_007', 'jobId': 'job_microsoft_sde', 'status': 'Online Test', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_008_job_microsoft_sde', 'studentId': 'student_008', 'jobId': 'job_microsoft_sde', 'status': 'Group Discussion', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'id': 'student_003_job_infosys_analyst', 'studentId': 'student_003', 'jobId': 'job_infosys_analyst', 'status': 'Technical Interview', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)))},
      {'id': 'student_005_job_infosys_analyst', 'studentId': 'student_005', 'jobId': 'job_infosys_analyst', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)))},
      {'id': 'student_007_job_infosys_analyst', 'studentId': 'student_007', 'jobId': 'job_infosys_analyst', 'status': 'Aptitude Test', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4)))},
      {'id': 'student_008_job_infosys_analyst', 'studentId': 'student_008', 'jobId': 'job_infosys_analyst', 'status': 'Rejected', 'rejectionFeedback': 'Could not clear aptitude round.', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5)))},
      {'id': 'student_004_job_infosys_intern', 'studentId': 'student_004', 'jobId': 'job_infosys_intern', 'status': 'Case Study', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6)))},
      {'id': 'student_001_job_infosys_intern', 'studentId': 'student_001', 'jobId': 'job_infosys_intern', 'status': 'Applied', 'appliedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))},
    ];
    for (var a in apps) {
      final id = a.remove('id');
      await _db.collection('applications').doc(id as String).set(a);
    }
  }

  // ======================== INTERVIEWS ========================
  static Future<void> _seedInterviews() async {
    final interviews = [
      {'jobId': 'job_google_sde', 'studentId': 'student_001', 'roundName': 'Technical Interview 1', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2, hours: 10))), 'venue': 'Google Meet', 'mode': 'online', 'meetingLink': 'https://meet.google.com/abc', 'notes': 'DSA + System Design'},
      {'jobId': 'job_google_sde', 'studentId': 'student_002', 'roundName': 'Technical Interview 2', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3, hours: 14))), 'venue': 'Google Meet', 'mode': 'online', 'meetingLink': 'https://meet.google.com/xyz', 'notes': 'Deep dive past projects'},
      {'jobId': 'job_google_sde', 'studentId': 'student_006', 'roundName': 'HR Round', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5, hours: 11))), 'venue': 'Room 301', 'mode': 'offline', 'notes': 'Bring originals'},
      {'jobId': 'job_microsoft_sde', 'studentId': 'student_002', 'roundName': 'Tech Interview', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4, hours: 9))), 'venue': 'MS Teams', 'mode': 'online', 'meetingLink': 'https://teams.microsoft.com/meet/123'},
      {'jobId': 'job_infosys_analyst', 'studentId': 'student_003', 'roundName': 'Technical Interview', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1, hours: 15))), 'venue': 'Seminar Hall B', 'mode': 'offline', 'notes': 'Panel interview'},
      {'jobId': 'job_infosys_intern', 'studentId': 'student_004', 'roundName': 'Case Study', 'dateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 6, hours: 10))), 'venue': 'Zoom', 'mode': 'online', 'meetingLink': 'https://zoom.us/j/987'},
    ];
    for (var i in interviews) {
      await _db.collection('interviews').add(i);
    }
  }

  // ======================== OFFERS ========================
  static Future<void> _seedOffers() async {
    // Give Ananya (top student) a pending Google offer
    await _db.collection('offers').doc('offer_ananya_google').set({
      'jobId': 'job_google_sde',
      'studentId': 'student_006',
      'company': 'Google',
      'role': 'Software Engineer (SDE-1)',
      'ctcLpa': 25.0,
      'offerLetterUrl': 'https://drive.google.com/offer-letter-google',
      'status': 'pending',
      'offeredAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'responseDeadline': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'tier': 'Super Dream',
    });
  }

  // ======================== ANNOUNCEMENTS ========================
  static Future<void> _seedAnnouncements() async {
    final announcements = [
      {
        'title': 'Google On-Campus Drive — 2025-26 Batch',
        'body': 'Google will be visiting our campus for SDE-1 and Intern roles on April 20-21. Eligible students should have CGPA ≥ 8.0, no active backlogs, CSE/IT branch only.\n\nPrepare DSA from GeeksForGeeks and Neetcode 150.',
        'priority': 'urgent',
        'targetAudience': 'students',
        'attachmentUrls': ['https://careers.google.com/jd.pdf'],
        'createdBy': 'Placement Cell',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'title': 'Microsoft Pre-Placement Talk',
        'body': 'Microsoft will conduct a Pre-Placement Talk (PPT) on April 15 at 3 PM in Seminar Hall A. All branches are welcome. Learn about life at Microsoft and the roles available.',
        'priority': 'normal',
        'targetAudience': 'all',
        'attachmentUrls': [],
        'createdBy': 'Placement Cell',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
      },
      {
        'title': 'Resume Submission Deadline — All Students',
        'body': 'All students must upload their updated resume to the platform by April 18. Students without a resume will not be eligible for upcoming drives.',
        'priority': 'urgent',
        'targetAudience': 'students',
        'attachmentUrls': [],
        'createdBy': 'Placement Cell',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
      },
      {
        'title': 'Recruiter Portal Update',
        'body': 'Recruiters can now extend formal offers to candidates directly from the Applicants tab. Use the "Extend Offer" button on final-round candidates.',
        'priority': 'normal',
        'targetAudience': 'recruiters',
        'attachmentUrls': [],
        'createdBy': 'Placement Cell',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
    ];
    for (var a in announcements) {
      await _db.collection('announcements').add(a);
    }
  }

  // ======================== NOTIFICATIONS ========================
  static Future<void> _seedNotifications() async {
    final notifications = [
      {'userId': 'student_001', 'title': 'Application Updated', 'body': 'Your Google SDE-1 application → Technical Interview 1', 'type': 'status_change', 'read': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3)))},
      {'userId': 'student_001', 'title': 'Interview Scheduled', 'body': 'Google SDE-1 — Technical Interview 1 on Google Meet', 'type': 'interview', 'read': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2)))},
      {'userId': 'student_002', 'title': 'Application Updated', 'body': 'Your Google SDE-1 application → Technical Interview 2', 'type': 'status_change', 'read': true, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))},
      {'userId': 'student_006', 'title': '🎉 You received an offer!', 'body': 'Google has extended an offer for SDE-1 — 25.0 LPA!', 'type': 'offer', 'read': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5)))},
      {'userId': 'student_007', 'title': 'Application Rejected', 'body': 'Google SDE-1 rejected.\nFeedback: Needs stronger DSA fundamentals.', 'type': 'status_change', 'read': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 8)))},
      {'userId': 'student_004', 'title': 'Interview Scheduled', 'body': 'Infosys InStep Intern — Case Study on Zoom', 'type': 'interview', 'read': false, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1)))},
      {'userId': 'recruiter_google', 'title': 'Job Approved', 'body': 'Your "SDE-1 at Google" has been approved!', 'type': 'job_approved', 'read': true, 'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3)))},
    ];
    for (var n in notifications) {
      await _db.collection('notifications').add(n);
    }
  }

  // ======================== CLEAR ALL ========================
  static Future<void> clearAll() async {
    await _clearCollection('interviews');
    await _clearCollection('notifications');
    await _clearCollection('announcements');
    await _clearCollection('offers');
    await _clearCollection('companies');

    final appIds = ['student_001_job_google_sde', 'student_002_job_google_sde', 'student_004_job_google_sde', 'student_006_job_google_sde', 'student_007_job_google_sde', 'student_001_job_google_intern', 'student_006_job_google_intern', 'student_002_job_microsoft_sde', 'student_003_job_microsoft_sde', 'student_007_job_microsoft_sde', 'student_008_job_microsoft_sde', 'student_003_job_infosys_analyst', 'student_005_job_infosys_analyst', 'student_007_job_infosys_analyst', 'student_008_job_infosys_analyst', 'student_004_job_infosys_intern', 'student_001_job_infosys_intern'];
    for (var id in appIds) { await _db.collection('applications').doc(id).delete(); }

    final jobIds = ['job_google_sde', 'job_google_intern', 'job_microsoft_sde', 'job_infosys_analyst', 'job_infosys_intern', 'job_startup_flutter'];
    for (var id in jobIds) { await _db.collection('jobs').doc(id).delete(); }

    final userIds = ['student_001', 'student_002', 'student_003', 'student_004', 'student_005', 'student_006', 'student_007', 'student_008', 'recruiter_google', 'recruiter_microsoft', 'recruiter_infosys', 'recruiter_startup'];
    for (var id in userIds) { await _db.collection('users').doc(id).delete(); }

    await _db.collection('colleges').doc('college_main').delete();
  }

  static Future<void> _clearCollection(String name) async {
    final snap = await _db.collection(name).get();
    for (var doc in snap.docs) { await doc.reference.delete(); }
  }
}
