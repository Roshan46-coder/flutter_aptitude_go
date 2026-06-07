import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class CandidateRecruiterView extends StatefulWidget {
  final String username;
  final String? recruiterName;
  const CandidateRecruiterView({super.key, required this.username, this.recruiterName});

  @override
  State<CandidateRecruiterView> createState() => _CandidateRecruiterViewState();
}

class _CandidateRecruiterViewState extends State<CandidateRecruiterView> {
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);

    try {
      final resp = await api.get('profile/recruiter/data/${widget.username}/');
      if (mounted) {
        final d = resp.data;
        final serverProfile = d['recruiter_profile_data'] as Map? ?? {};
        final serverUser = d['user'] as Map? ?? {};
        final stats = d['stats'] as Map? ?? {};
        setState(() {
          _profile = Map<String, dynamic>.from(serverProfile);
          _userData = Map<String, dynamic>.from(serverUser);
          _stats = Map<String, dynamic>.from(stats);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _val(dynamic v) => (v?.toString() ?? '').trim();
  String _display(String key) => _val(_profile[key]).isNotEmpty ? _val(_profile[key]) : 'Not Provided';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.recruiterName ?? 'Recruiter Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.neonBlue)),
      );
    }

    final name = '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : '@${widget.username}';
    final avatarUrl = _userData['avatar_url']?.toString().isNotEmpty == true
        ? _userData['avatar_url'].toString() : null;
    final exams = _stats['total_exams_created'] ?? 0;
    final active = _stats['active_job_openings'] ?? 0;
    final hired = _stats['total_candidates_hired'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(avatarUrl, displayName),
            const SizedBox(height: 16),
            _buildStats(exams, active, hired),
            const SizedBox(height: 16),
            _infoCard('Contact Information', Icons.contact_mail_outlined, [
              _infoRow('Email', _userData['email'] ?? ''),
              _infoRow('Company Email', _display('company_email')),
              _infoRow('Phone', _display('phone')),
            ]),
            const SizedBox(height: 12),
            _infoCard('Company Details', Icons.business_outlined, [
              _infoRow('Company Name', _display('company_name')),
              _infoRow('Role / Designation', _display('designation')),
              _infoRow('Location', _display('location')),
              _infoRow('Website', _display('company_website')),
            ]),
            if (_val(_profile['company_description']).isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoCard('About Company', Icons.info_outline, [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_profile['company_description'],
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
                ),
              ]),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? avatarUrl, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        gradient: LinearGradient(
          colors: [AppTheme.neonBlue.withValues(alpha: 0.05), AppTheme.cardBg],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null
                ? (avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : FileImage(File(avatarUrl)))
                : null,
            child: avatarUrl == null
                ? const Icon(Icons.business, color: AppTheme.neonBlue, size: 52) : null,
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (_val(_profile['designation']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_profile['designation'], style: const TextStyle(color: AppTheme.neonBlue, fontSize: 15)),
            ),
          if (_val(_profile['company_name']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.neonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.business, size: 14, color: AppTheme.neonBlue),
                  const SizedBox(width: 6),
                  Text(_profile['company_name'], style: const TextStyle(color: AppTheme.neonBlue, fontSize: 13, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStats(dynamic exams, dynamic active, dynamic hired) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppTheme.neonBlue, size: 18),
              const SizedBox(width: 8),
              const Text('Recruiter Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            _statCard('Exams Created', '$exams', Icons.quiz_outlined, AppTheme.neonPurple),
            const SizedBox(width: 8),
            _statCard('Active Openings', '$active', Icons.work_outline, AppTheme.neonBlue),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('Candidates Hired', '$hired', Icons.person_add_alt, AppTheme.emeraldGreen),
            const SizedBox(width: 8),
            const Spacer(),
          ]),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
      ]),
    ));
  }

  Widget _infoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppTheme.neonBlue, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    final isMissing = value == 'Not Provided';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 140, child: Text('$label:', style: const TextStyle(color: Colors.white38, fontSize: 13))),
        Expanded(child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isMissing ? Colors.white24 : Colors.white70,
            fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
          ),
        )),
      ]),
    );
  }
}
