import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_placement/models/job_model.dart';

class JobService {
  static const String _baseUrl = 'https://api.smartplacement.example.com';

  Future<List<JobModel>> getJobs() async {
    // TODO: Replace with real API endpoint
    await Future<void>.delayed(const Duration(seconds: 1));
    return _mockJobs;
  }

  Future<JobModel?> getJobById(String id) async {
    // TODO: Replace with real API endpoint
    await Future<void>.delayed(const Duration(milliseconds: 500));
    try {
      return _mockJobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> applyToJob(String jobId, String userId) async {
    // TODO: Replace with real API endpoint
    final response = await http.post(
      Uri.parse('$_baseUrl/jobs/$jobId/apply'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static final List<JobModel> _mockJobs = [
    JobModel(
      id: '1',
      title: 'Flutter Developer',
      company: 'TechCorp',
      location: 'Mumbai, India',
      description:
          'Looking for an experienced Flutter developer to join our mobile team.',
      salary: '₹8-15 LPA',
      requirements: ['Flutter', 'Dart', 'REST APIs', '2+ years experience'],
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
      isRemote: true,
    ),
    JobModel(
      id: '2',
      title: 'Backend Engineer',
      company: 'StartupXYZ',
      location: 'Bangalore, India',
      description: 'Join our fast-growing startup as a backend engineer.',
      salary: '₹10-18 LPA',
      requirements: ['Node.js', 'PostgreSQL', 'Docker', '3+ years experience'],
      postedAt: DateTime.now().subtract(const Duration(days: 5)),
      isRemote: false,
    ),
  ];
}
