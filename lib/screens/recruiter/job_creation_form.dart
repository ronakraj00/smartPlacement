import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class JobCreationForm extends StatefulWidget {
  const JobCreationForm({super.key});

  @override
  State<JobCreationForm> createState() => _JobCreationFormState();
}

class _JobCreationFormState extends State<JobCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _descController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _skillsController = TextEditingController();
  final _branchController = TextEditingController();
  
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _jobTypeController = TextEditingController();
  final _documentController = TextEditingController();
  final _openPositionsController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _ctcController = TextEditingController();
  DateTime? _selectedDeadline;
  
  final List<TextEditingController> _roundControllers = [];
  bool _isLoading = false;

  void _addRound() {
    setState(() => _roundControllers.add(TextEditingController()));
  }

  void _removeRound(int index) {
    setState(() {
      _roundControllers[index].dispose();
      _roundControllers.removeAt(index);
    });
  }

  void _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    List<String> skills = _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> docs = _documentController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    List<String> roundsList = ['Applied'];
    roundsList.addAll(_roundControllers.map((c) => c.text.trim()).where((r) => r.isNotEmpty));

    try {
      await FirebaseFirestore.instance.collection('jobs').add({
        'recruiterId': user.id,
        'company': _companyController.text,
        'role': _roleController.text,
        'description': _descController.text,
        'requiredCgpa': double.tryParse(_cgpaController.text) ?? 0.0,
        'requiredSkills': skills,
        'branchEligibility': _branchController.text,
        'status': 'pending',
        'location': _locationController.text,
        'salary': _salaryController.text,
        'jobType': _jobTypeController.text,
        'rounds': roundsList,
        'documentUrls': docs,
        'createdAt': FieldValue.serverTimestamp(),
        'openPositions': int.tryParse(_openPositionsController.text) ?? 0,
        'deadline': _selectedDeadline != null ? Timestamp.fromDate(_selectedDeadline!) : null,
        'ctcLpa': double.tryParse(_ctcController.text) ?? 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job submitted for Admin Verification!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Job')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Job Role', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Job Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              const Text('Logistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _jobTypeController,
                      decoration: const InputDecoration(labelText: 'Job Type (e.g. Intern)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(labelText: 'Salary (CTC/Stipend)', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ctcController,
                      decoration: const InputDecoration(labelText: 'CTC (LPA, numeric)', hintText: 'e.g. 12.5', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _openPositionsController,
                      decoration: const InputDecoration(labelText: 'Open Positions', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _deadlineController,
                      decoration: const InputDecoration(labelText: 'Application Deadline', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 14)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDeadline = picked;
                            _deadlineController.text = '${picked.day}/${picked.month}/${picked.year}';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Eligibility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cgpaController,
                decoration: const InputDecoration(labelText: 'Required CGPA', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'Required Skills (comma separated)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(labelText: 'Branch Eligibility (e.g. CSE, ECE)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),

              const Text('Interview Pipeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Define the sequence of rounds. "Applied" is included by default.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              ...List.generate(_roundControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _roundControllers[index],
                          decoration: InputDecoration(labelText: 'Round ${index + 1} Name', border: const OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeRound(index),
                      ),
                    ],
                  ),
                );
              }),
              ElevatedButton.icon(
                onPressed: _addRound,
                icon: const Icon(Icons.add),
                label: const Text('Add Pipeline Round'),
              ),
              const SizedBox(height: 24),

              const Text('Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _documentController,
                decoration: const InputDecoration(labelText: 'Attachment Links (PDFs, GDrive URLs - comma separated)', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitJob,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                      child: const Text('Submit Job for Admin Approval', style: TextStyle(fontSize: 16)),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _descController.dispose();
    _cgpaController.dispose();
    _skillsController.dispose();
    _branchController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _jobTypeController.dispose();
    _documentController.dispose();
    _openPositionsController.dispose();
    _deadlineController.dispose();
    for (var c in _roundControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
