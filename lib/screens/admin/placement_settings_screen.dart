import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/college_model.dart';

class PlacementSettingsScreen extends StatefulWidget {
  const PlacementSettingsScreen({super.key});

  @override
  State<PlacementSettingsScreen> createState() => _PlacementSettingsScreenState();
}

class _PlacementSettingsScreenState extends State<PlacementSettingsScreen> {
  final _nameC = TextEditingController();
  final _codeC = TextEditingController();
  final _addressC = TextEditingController();
  final _batchC = TextEditingController();
  final _maxOffersC = TextEditingController();
  final _dreamCtcC = TextEditingController();
  final _superDreamCtcC = TextEditingController();
  final _minCgpaC = TextEditingController();
  final _maxBacklogsC = TextEditingController();
  final _minAttendanceC = TextEditingController();
  bool _blockAfterDream = true;
  bool _isLoading = false;
  String? _collegeDocId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final snap = await FirebaseFirestore.instance.collection('colleges').limit(1).get();
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      _collegeDocId = doc.id;
      final college = CollegeModel.fromMap(doc.data(), doc.id);
      setState(() {
        _nameC.text = college.name;
        _codeC.text = college.code;
        _addressC.text = college.address ?? '';
        _batchC.text = college.placementBatch;
        _maxOffersC.text = '${college.policy.maxOffers}';
        _dreamCtcC.text = '${college.policy.dreamCtcThreshold}';
        _superDreamCtcC.text = '${college.policy.superDreamCtcThreshold}';
        _minCgpaC.text = '${college.policy.minCgpa}';
        _maxBacklogsC.text = '${college.policy.allowedActiveBacklogs}';
        _minAttendanceC.text = '${college.policy.minAttendance}';
        _blockAfterDream = college.policy.blockAfterDream;
      });
    } else {
      // Defaults
      _maxOffersC.text = '1';
      _dreamCtcC.text = '15.0';
      _superDreamCtcC.text = '25.0';
      _minCgpaC.text = '0.0';
      _maxBacklogsC.text = '0';
      _minAttendanceC.text = '0.0';
    }
  }

  void _saveSettings() async {
    setState(() => _isLoading = true);
    final data = {
      'name': _nameC.text,
      'code': _codeC.text,
      'address': _addressC.text,
      'placementBatch': _batchC.text,
      'policy': {
        'maxOffers': int.tryParse(_maxOffersC.text) ?? 1,
        'dreamCtcThreshold': double.tryParse(_dreamCtcC.text) ?? 15.0,
        'superDreamCtcThreshold': double.tryParse(_superDreamCtcC.text) ?? 25.0,
        'blockAfterDream': _blockAfterDream,
        'allowedActiveBacklogs': int.tryParse(_maxBacklogsC.text) ?? 0,
        'minCgpa': double.tryParse(_minCgpaC.text) ?? 0.0,
        'minAttendance': double.tryParse(_minAttendanceC.text) ?? 0.0,
      },
    };

    try {
      if (_collegeDocId != null) {
        await FirebaseFirestore.instance.collection('colleges').doc(_collegeDocId).update(data);
      } else {
        final ref = await FirebaseFirestore.instance.collection('colleges').add(data);
        _collegeDocId = ref.id;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
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
          // College Info
          _sectionTitle('🏫 College Information'),
          const SizedBox(height: 8),
          _field(_nameC, 'College Name', 'e.g. Indian Institute of Technology'),
          Row(
            children: [
              Expanded(child: _field(_codeC, 'College Code', 'e.g. IITP')),
              const SizedBox(width: 12),
              Expanded(child: _field(_batchC, 'Placement Batch', 'e.g. 2025-26')),
            ],
          ),
          _field(_addressC, 'Address', 'Full address'),
          const SizedBox(height: 24),

          // Placement Policy
          _sectionTitle('📋 Placement Policy Rules'),
          const SizedBox(height: 8),

          Card(
            color: Colors.deepPurple.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Company Tier Thresholds', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('CTC values (in LPA) that classify companies into tiers', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_dreamCtcC, '💎 Dream (LPA)', '15.0', isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_superDreamCtcC, '👑 Super Dream (LPA)', '25.0', isNumber: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: Colors.orange.withAlpha(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Rules', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _field(_maxOffersC, 'Max Offers per Student', '1', isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_maxBacklogsC, 'Max Active Backlogs', '0', isNumber: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _field(_minCgpaC, 'Min CGPA (Global)', '0.0', isNumber: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_minAttendanceC, 'Min Attendance %', '0', isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Block after Dream placement', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Students placed in Dream+ cannot apply to Normal tier', style: TextStyle(fontSize: 12)),
                    value: _blockAfterDream,
                    onChanged: (val) => setState(() => _blockAfterDream = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Settings'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));

  Widget _field(TextEditingController c, String label, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose(); _codeC.dispose(); _addressC.dispose(); _batchC.dispose();
    _maxOffersC.dispose(); _dreamCtcC.dispose(); _superDreamCtcC.dispose();
    _minCgpaC.dispose(); _maxBacklogsC.dispose(); _minAttendanceC.dispose();
    super.dispose();
  }
}
