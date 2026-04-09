import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

/// Allows recruiters to manage their company profile visible to students.
class RecruiterCompanyProfile extends StatefulWidget {
  const RecruiterCompanyProfile({super.key});

  @override
  State<RecruiterCompanyProfile> createState() => _RecruiterCompanyProfileState();
}

class _RecruiterCompanyProfileState extends State<RecruiterCompanyProfile> {
  final _nameC = TextEditingController();
  final _industryC = TextEditingController();
  final _websiteC = TextEditingController();
  final _descC = TextEditingController();
  final _hqC = TextEditingController();
  final _empCountC = TextEditingController();
  bool _isLoading = false;
  String? _companyDocId;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  void _loadCompany() async {
    final user = context.read<AuthService>().currentUser;
    final companyName = user?.companyName;
    if (companyName == null || companyName.isEmpty) return;
    _nameC.text = companyName;

    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .where('name', isEqualTo: companyName)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _companyDocId = doc.id;
      final data = doc.data();
      setState(() {
        _industryC.text = data['industry'] ?? '';
        _websiteC.text = data['website'] ?? '';
        _descC.text = data['description'] ?? '';
        _hqC.text = data['headquarters'] ?? '';
        _empCountC.text = data['employeeCount'] ?? '';
      });
    }
  }

  void _save() async {
    setState(() => _isLoading = true);
    final Map<String, dynamic> data = {
      'name': _nameC.text,
      'industry': _industryC.text,
      'website': _websiteC.text.isNotEmpty ? _websiteC.text : null,
      'description': _descC.text,
      'headquarters': _hqC.text.isNotEmpty ? _hqC.text : null,
      'employeeCount': _empCountC.text.isNotEmpty ? _empCountC.text : null,
    };

    try {
      if (_companyDocId != null) {
        await FirebaseFirestore.instance.collection('companies').doc(_companyDocId).update(data);
      } else {
        data['avgRating'] = 0.0;
        data['pastVisitYears'] = [];
        final ref = await FirebaseFirestore.instance.collection('companies').add(data);
        _companyDocId = ref.id;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Company Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('This info is visible to students and the placement cell.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),

          _field(_nameC, 'Company Name'),
          _field(_industryC, 'Industry (e.g. Technology / SaaS)'),
          _field(_websiteC, 'Careers Website'),
          TextField(
            controller: _descC,
            decoration: const InputDecoration(labelText: 'Company Description', border: OutlineInputBorder()),
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_hqC, 'Headquarters')),
            const SizedBox(width: 12),
            Expanded(child: _field(_empCountC, 'Employee Count')),
          ]),

          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Company Profile'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose(); _industryC.dispose(); _websiteC.dispose(); _descC.dispose();
    _hqC.dispose(); _empCountC.dispose();
    super.dispose();
  }
}
