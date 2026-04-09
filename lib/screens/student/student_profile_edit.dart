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
  final _cgpaController = TextEditingController();
  final _branchController = TextEditingController();
  final _skillsController = TextEditingController();
  final _projectsController = TextEditingController();
  final _resumeUrlController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthService>().currentUser;
      if (user != null) {
        _cgpaController.text = user.cgpa?.toString() ?? '';
        _branchController.text = user.branch ?? '';
        _skillsController.text = (user.skills ?? []).join(', ');
        _projectsController.text = (user.projects ?? []).join(', ');
        _resumeUrlController.text = user.resumeUrl ?? '';
        _aboutController.text = user.about ?? '';
      }
    });
  }

  double _getProfileCompleteness() {
    int filled = 0;
    int total = 6;
    if (_cgpaController.text.isNotEmpty) filled++;
    if (_branchController.text.isNotEmpty) filled++;
    if (_skillsController.text.isNotEmpty) filled++;
    if (_projectsController.text.isNotEmpty) filled++;
    if (_resumeUrlController.text.isNotEmpty) filled++;
    if (_aboutController.text.isNotEmpty) filled++;
    return filled / total;
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final projectsList = _projectsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'cgpa': double.tryParse(_cgpaController.text),
        'branch': _branchController.text,
        'skills': skillsList,
        'projects': projectsList,
        'resumeUrl': _resumeUrlController.text.isNotEmpty ? _resumeUrlController.text : null,
        'about': _aboutController.text.isNotEmpty ? _aboutController.text : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Completeness Bar
          StatefulBuilder(
            builder: (context, setBarState) {
              double completeness = _getProfileCompleteness();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profile Completeness: ${(completeness * 100).toInt()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: completeness,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: Colors.grey.shade200,
                    color: completeness == 1.0 ? Colors.green : Colors.deepPurple,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          const Text('About Me', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _aboutController,
            decoration: const InputDecoration(
              hintText: 'Brief introduction about yourself...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          const Text('Academic Information', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cgpaController,
                  decoration: const InputDecoration(labelText: 'CGPA', border: OutlineInputBorder()),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _branchController,
                  decoration: const InputDecoration(labelText: 'Branch (e.g. CSE)', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _skillsController,
            decoration: const InputDecoration(
              labelText: 'Skills (comma separated)',
              hintText: 'e.g., Flutter, Kotlin, Firebase',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _projectsController,
            decoration: const InputDecoration(
              labelText: 'Projects (comma separated)',
              hintText: 'e.g., Chat App, E-Commerce Site',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Resume', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _resumeUrlController,
            decoration: const InputDecoration(
              labelText: 'Resume Link (Google Drive URL)',
              hintText: 'https://drive.google.com/...',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Save Profile', style: TextStyle(fontSize: 16)),
                )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cgpaController.dispose();
    _branchController.dispose();
    _skillsController.dispose();
    _projectsController.dispose();
    _resumeUrlController.dispose();
    _aboutController.dispose();
    super.dispose();
  }
}
