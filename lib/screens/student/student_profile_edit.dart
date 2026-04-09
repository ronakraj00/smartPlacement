import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class StudentProfileEdit extends StatefulWidget {
  const StudentProfileEdit({super.key});

  @override
  State<StudentProfileEdit> createState() => _StudentProfileEditState();
}

class _StudentProfileEditState extends State<StudentProfileEdit> {
  // Personal
  final _phoneC = TextEditingController();
  final _dobC = TextEditingController();
  final _addressC = TextEditingController();
  String _gender = '';
  // Academic
  final _cgpaC = TextEditingController();
  final _branchC = TextEditingController();
  final _semesterC = TextEditingController();
  final _gradYearC = TextEditingController();
  final _activeBacklogsC = TextEditingController();
  final _totalBacklogsC = TextEditingController();
  final _attendanceC = TextEditingController();
  // Education
  final _10boardC = TextEditingController();
  final _10pctC = TextEditingController();
  final _10yearC = TextEditingController();
  final _12boardC = TextEditingController();
  final _12pctC = TextEditingController();
  final _12yearC = TextEditingController();
  // Professional
  final _aboutC = TextEditingController();
  final _skillsC = TextEditingController();
  final _projectsC = TextEditingController();
  final _resumeUrlC = TextEditingController();
  // Social
  final _linkedinC = TextEditingController();
  final _githubC = TextEditingController();
  final _portfolioC = TextEditingController();
  final _leetcodeC = TextEditingController();
  // Certifications & Experience (stored as comma-sep for simplicity)
  final _certsC = TextEditingController();
  final _expC = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;
      _phoneC.text = user.phone ?? '';
      _dobC.text = user.dob ?? '';
      _addressC.text = user.address ?? '';
      _gender = user.gender ?? '';
      _cgpaC.text = user.cgpa?.toString() ?? '';
      _branchC.text = user.branch ?? '';
      _semesterC.text = user.semester?.toString() ?? '';
      _gradYearC.text = user.graduationYear?.toString() ?? '';
      _activeBacklogsC.text = user.activeBacklogs?.toString() ?? '0';
      _totalBacklogsC.text = user.totalBacklogs?.toString() ?? '0';
      _attendanceC.text = user.attendance?.toString() ?? '';
      _aboutC.text = user.about ?? '';
      _skillsC.text = (user.skills ?? []).join(', ');
      _projectsC.text = (user.projects ?? []).join(', ');
      _resumeUrlC.text = user.resumeUrl ?? '';
      // Education
      if (user.class10th != null) {
        _10boardC.text = user.class10th!['board'] ?? '';
        _10pctC.text = user.class10th!['percentage']?.toString() ?? '';
        _10yearC.text = user.class10th!['year']?.toString() ?? '';
      }
      if (user.class12th != null) {
        _12boardC.text = user.class12th!['board'] ?? '';
        _12pctC.text = user.class12th!['percentage']?.toString() ?? '';
        _12yearC.text = user.class12th!['year']?.toString() ?? '';
      }
      // Social
      if (user.socialLinks != null) {
        _linkedinC.text = user.socialLinks!['linkedin'] ?? '';
        _githubC.text = user.socialLinks!['github'] ?? '';
        _portfolioC.text = user.socialLinks!['portfolio'] ?? '';
        _leetcodeC.text = user.socialLinks!['leetcode'] ?? '';
      }
      // Certs & Exp
      if (user.certifications != null) {
        _certsC.text = user.certifications!.map((c) => c['name'] ?? '').join(', ');
      }
      if (user.workExperience != null) {
        _expC.text = user.workExperience!.map((e) => '${e['role']} at ${e['company']}').join(', ');
      }
      setState(() {});
    });
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      final skills = _skillsC.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final projects = _projectsC.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final certsRaw = _certsC.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final certs = certsRaw.map((c) => {'name': c, 'issuer': '', 'url': ''}).toList();
      final expRaw = _expC.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      final exps = expRaw.map((e) => {'company': e, 'role': '', 'duration': '', 'description': ''}).toList();

      Map<String, String> socialLinks = {};
      if (_linkedinC.text.isNotEmpty) socialLinks['linkedin'] = _linkedinC.text;
      if (_githubC.text.isNotEmpty) socialLinks['github'] = _githubC.text;
      if (_portfolioC.text.isNotEmpty) socialLinks['portfolio'] = _portfolioC.text;
      if (_leetcodeC.text.isNotEmpty) socialLinks['leetcode'] = _leetcodeC.text;

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'phone': _phoneC.text.isNotEmpty ? _phoneC.text : null,
        'dob': _dobC.text.isNotEmpty ? _dobC.text : null,
        'gender': _gender.isNotEmpty ? _gender : null,
        'address': _addressC.text.isNotEmpty ? _addressC.text : null,
        'cgpa': double.tryParse(_cgpaC.text),
        'branch': _branchC.text,
        'semester': int.tryParse(_semesterC.text),
        'graduationYear': int.tryParse(_gradYearC.text),
        'activeBacklogs': int.tryParse(_activeBacklogsC.text) ?? 0,
        'totalBacklogs': int.tryParse(_totalBacklogsC.text) ?? 0,
        'attendance': double.tryParse(_attendanceC.text),
        'about': _aboutC.text.isNotEmpty ? _aboutC.text : null,
        'skills': skills,
        'projects': projects,
        'resumeUrl': _resumeUrlC.text.isNotEmpty ? _resumeUrlC.text : null,
        'class10th': _10boardC.text.isNotEmpty ? {
          'board': _10boardC.text,
          'percentage': double.tryParse(_10pctC.text),
          'year': int.tryParse(_10yearC.text),
        } : null,
        'class12th': _12boardC.text.isNotEmpty ? {
          'board': _12boardC.text,
          'percentage': double.tryParse(_12pctC.text),
          'year': int.tryParse(_12yearC.text),
        } : null,
        'certifications': certs.isNotEmpty ? certs : null,
        'workExperience': exps.isNotEmpty ? exps : null,
        'socialLinks': socialLinks.isNotEmpty ? socialLinks : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    int completeness = user?.profileCompleteness ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: completeness / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          color: completeness >= 80 ? Colors.green : completeness >= 50 ? Colors.orange : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$completeness%', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: completeness >= 80 ? Colors.green : completeness >= 50 ? Colors.orange : Colors.red,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Personal Info
          _section('👤 Personal Information', [
            _field(_phoneC, 'Phone Number'),
            Row(children: [
              Expanded(child: _field(_dobC, 'Date of Birth (DD/MM/YYYY)')),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender.isNotEmpty ? _gender : null,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _gender = v ?? ''),
                ),
              ),
            ]),
            _field(_addressC, 'Address'),
          ]),

          // 2. Academic
          _section('🎓 Academic Information', [
            Row(children: [
              Expanded(child: _field(_cgpaC, 'CGPA', isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_branchC, 'Branch (CSE, ECE...)')),
            ]),
            Row(children: [
              Expanded(child: _field(_semesterC, 'Current Semester', isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_gradYearC, 'Graduation Year', isNum: true)),
            ]),
            Row(children: [
              Expanded(child: _field(_activeBacklogsC, 'Active Backlogs', isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_totalBacklogsC, 'Total Backlogs', isNum: true)),
            ]),
            _field(_attendanceC, 'Attendance (%)', isNum: true),
          ]),

          // 3. Education History
          _section('📚 Education History', [
            const Text('Class 10th', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _field(_10boardC, 'Board')),
              const SizedBox(width: 8),
              Expanded(child: _field(_10pctC, '%', isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_10yearC, 'Year', isNum: true)),
            ]),
            const SizedBox(height: 8),
            const Text('Class 12th', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: _field(_12boardC, 'Board')),
              const SizedBox(width: 8),
              Expanded(child: _field(_12pctC, '%', isNum: true)),
              const SizedBox(width: 8),
              Expanded(child: _field(_12yearC, 'Year', isNum: true)),
            ]),
          ]),

          // 4. About & Skills
          _section('💡 About & Skills', [
            TextField(
              controller: _aboutC,
              decoration: const InputDecoration(labelText: 'About Me', hintText: 'Brief intro...', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _field(_skillsC, 'Skills (comma separated)'),
            _field(_projectsC, 'Projects (comma separated)'),
            _field(_resumeUrlC, 'Resume Link (Google Drive URL)'),
          ]),

          // 5. Certifications & Experience
          _section('🏆 Certifications & Experience', [
            _field(_certsC, 'Certifications (comma separated names)'),
            _field(_expC, 'Work Experience (comma separated)'),
          ]),

          // 6. Social Links
          _section('🔗 Social Links', [
            _field(_linkedinC, 'LinkedIn URL'),
            _field(_githubC, 'GitHub URL'),
            _field(_portfolioC, 'Portfolio URL'),
            _field(_leetcodeC, 'LeetCode / Coding Profile URL'),
          ]),

          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  void dispose() {
    for (var c in [_phoneC, _dobC, _addressC, _cgpaC, _branchC, _semesterC, _gradYearC,
        _activeBacklogsC, _totalBacklogsC, _attendanceC, _10boardC, _10pctC, _10yearC,
        _12boardC, _12pctC, _12yearC, _aboutC, _skillsC, _projectsC, _resumeUrlC,
        _linkedinC, _githubC, _portfolioC, _leetcodeC, _certsC, _expC]) {
      c.dispose();
    }
    super.dispose();
  }
}
