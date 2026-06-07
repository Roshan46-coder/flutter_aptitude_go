import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class RecruiterPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> profile;
  final Map<String, dynamic> stats;

  const RecruiterPreviewScreen({
    super.key,
    required this.userData,
    required this.profile,
    required this.stats,
  });

  String _val(dynamic v) => (v?.toString() ?? '').trim();
  String _display(String key) {
    final v = _val(profile[key]);
    return v.isNotEmpty ? v : 'Not Provided';
  }

  @override
  Widget build(BuildContext context) {
    final name = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : '@${userData['username'] ?? ''}';
    final avatarUrl = userData['avatar_url']?.toString().isNotEmpty == true
        ? userData['avatar_url'].toString() : null;
    final exams = stats['total_exams_created'] ?? 0;
    final active = stats['active_job_openings'] ?? 0;
    final hired = stats['total_candidates_hired'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.visibility, size: 12, color: AppTheme.goldAccent),
                  SizedBox(width: 4),
                  Text('Candidate View', style: TextStyle(fontSize: 10, color: AppTheme.goldAccent, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(avatarUrl, displayName),
            const SizedBox(height: 16),
            _buildStats(exams, active, hired),
            const SizedBox(height: 16),
            _infoCard('Contact', Icons.contact_mail_outlined, [
              _infoRow('Email', userData['email'] ?? ''),
              _infoRow('Company Email', _display('company_email')),
              _infoRow('Phone', _display('phone')),
            ]),
            const SizedBox(height: 12),
            _infoCard('Company', Icons.business_outlined, [
              _infoRow('Company Name', _display('company_name')),
              _infoRow('Designation', _display('designation')),
              _infoRow('Location', _display('location')),
              _infoRow('Website', _display('company_website')),
            ]),
            if (_val(profile['company_description']).isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoCard('About Company', Icons.info_outline, [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(profile['company_description'],
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
          if (_val(profile['designation']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(profile['designation'], style: const TextStyle(color: AppTheme.neonBlue, fontSize: 15)),
            ),
          if (_val(profile['company_name']).isNotEmpty)
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
                  Text(profile['company_name'], style: const TextStyle(color: AppTheme.neonBlue, fontSize: 13, fontWeight: FontWeight.w500)),
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
            _statCard('Hired', '$hired', Icons.person_add_alt, AppTheme.emeraldGreen),
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
        SizedBox(width: 130, child: Text('$label:', style: const TextStyle(color: Colors.white38, fontSize: 13))),
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
