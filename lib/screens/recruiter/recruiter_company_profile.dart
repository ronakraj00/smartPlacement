import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Premium company profile editor for recruiters.
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
  bool _isSaved = false;
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
    setState(() { _isLoading = true; _isSaved = false; });
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
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company profile saved! ✅')));
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.business_rounded, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Company Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Visible to students & placement cell', style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ),
                if (_isSaved) Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Fields
          _sectionLabel('Basic Information'),
          const SizedBox(height: 10),
          _premiumField(_nameC, 'Company Name', Icons.business),
          _premiumField(_industryC, 'Industry', Icons.category_rounded, hint: 'e.g. Technology / SaaS'),
          _premiumField(_websiteC, 'Careers Website', Icons.language_rounded, hint: 'https://...'),

          const SizedBox(height: 20),
          _sectionLabel('About Company'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: TextField(
              controller: _descC,
              decoration: const InputDecoration(
                labelText: 'Company Description',
                alignLabelWithHint: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 5,
            ),
          ),

          const SizedBox(height: 20),
          _sectionLabel('Additional Details'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _premiumField(_hqC, 'Headquarters', Icons.location_city_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _premiumField(_empCountC, 'Employees', Icons.people_rounded, hint: 'e.g. 50,000+')),
          ]),

          const SizedBox(height: 28),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _premiumField(TextEditingController c, String label, IconData icon, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameC.dispose(); _industryC.dispose(); _websiteC.dispose();
    _descC.dispose(); _hqC.dispose(); _empCountC.dispose();
    super.dispose();
  }
}
