import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';
import 'recruiter_preview_screen.dart';

class RecruiterProfileScreen extends StatefulWidget {
  final bool hideAppBar;
  const RecruiterProfileScreen({super.key, this.hideAppBar = false});

  @override
  State<RecruiterProfileScreen> createState() => _RecruiterProfileScreenState();
}

class _RecruiterProfileScreenState extends State<RecruiterProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _stats = {};

  final _phoneC = TextEditingController();
  final _designationC = TextEditingController();
  final _locationC = TextEditingController();
  final _descC = TextEditingController();
  final _companyC = TextEditingController();
  final _websiteC = TextEditingController();
  final _companyEmailC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneC.dispose();
    _designationC.dispose();
    _locationC.dispose();
    _descC.dispose();
    _companyC.dispose();
    _websiteC.dispose();
    _companyEmailC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    final user = api.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }

    final username = user['username'] as String? ?? '';
    final saved = HiveDatabase.instance.getRecruiterProfile(username);

    setState(() {
      _userData = Map<String, dynamic>.from(user);
      _profile = Map<String, dynamic>.from(saved);
    });

    try {
      final resp = await api.get('profile/recruiter/data/');
      if (mounted) {
        final d = resp.data;
        final serverProfile = d['recruiter_profile_data'] as Map? ?? {};
        final serverUser = d['user'] as Map? ?? {};
        final stats = d['stats'] as Map? ?? {};
        if (serverProfile.isNotEmpty) {
          setState(() {
            serverProfile.forEach((k, v) {
              if (v != null && (v is! List || v.isNotEmpty) && (v is! String || v.isNotEmpty)) {
                _profile[k] = v;
              }
            });
          });
        }
        if (serverUser.isNotEmpty) {
          setState(() => _userData.addAll(Map<String, dynamic>.from(serverUser)));
        }
        if (stats.isNotEmpty) {
          setState(() => _stats = Map<String, dynamic>.from(stats));
        }
        await HiveDatabase.instance.saveRecruiterProfile(username, _profile);
      }
    } catch (_) {}

    try {
      final dashResp = await api.get('recruiter/dashboard/');
      if (mounted) {
        final dashStats = dashResp.data['stats'] as Map? ?? {};
        setState(() {
          _stats.addAll(Map<String, dynamic>.from(dashStats));
        });
      }
    } catch (_) {}

    _fillControllers();
    if (mounted) setState(() => _isLoading = false);
  }

  void _fillControllers() {
    _phoneC.text = _profile['phone'] ?? '';
    _designationC.text = _profile['designation'] ?? '';
    _locationC.text = _profile['location'] ?? '';
    _descC.text = _profile['company_description'] ?? _profile['about'] ?? '';
    _companyC.text = _profile['company_name'] ?? _userData['organization'] ?? '';
    _websiteC.text = _profile['company_website'] ?? '';
    _companyEmailC.text = _profile['company_email'] ?? '';
  }

  bool _validateEmail(String? email) {
    if (email == null || email.isEmpty) return true;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return true;
    return RegExp(r'^\+?[\d\s\-\(\)]{7,20}$').hasMatch(phone);
  }

  void _enterEdit() {
    _fillControllers();
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    if (_companyC.text.trim().isEmpty) {
      _showSnack('Company name is required', AppTheme.livesRed);
      return;
    }
    if (!_validateEmail(_companyEmailC.text.trim())) {
      _showSnack('Please enter a valid email address', AppTheme.livesRed);
      return;
    }
    if (!_validatePhone(_phoneC.text.trim())) {
      _showSnack('Please enter a valid phone number', AppTheme.livesRed);
      return;
    }

    setState(() => _isSaving = true);

    final api = Provider.of<ApiClient>(context, listen: false);
    final user = api.currentUser;
    if (user == null) { setState(() => _isSaving = false); return; }
    final username = user['username'] as String? ?? '';

    final updated = <String, dynamic>{
      'phone': _phoneC.text.trim(),
      'designation': _designationC.text.trim(),
      'location': _locationC.text.trim(),
      'company_description': _descC.text.trim(),
      'company_name': _companyC.text.trim(),
      'company_website': _websiteC.text.trim(),
      'company_email': _companyEmailC.text.trim(),
    };

    await HiveDatabase.instance.saveRecruiterProfile(username, updated);
    api.updateCurrentUser({'organization': _companyC.text.trim()});
    HiveDatabase.instance.updateCurrentUser({'organization': _companyC.text.trim()});

    try {
      await api.post('profile/recruiter/data/save/', data: {'recruiter_profile_data': updated});
    } catch (_) {}

    try {
      final resp = await api.get('profile/recruiter/data/');
      if (mounted) {
        final d = resp.data;
        final stats = d['stats'] as Map? ?? {};
        setState(() {
          _stats = Map<String, dynamic>.from(stats);
        });
      }
    } catch (_) {}

    try {
      final dashResp = await api.get('recruiter/dashboard/');
      if (mounted) {
        final dashStats = dashResp.data['stats'] as Map? ?? {};
        setState(() {
          _stats.addAll(Map<String, dynamic>.from(dashStats));
        });
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _profile = updated;
      _isEditing = false;
      _isSaving = false;
    });
    _showSnack('Profile saved successfully', AppTheme.emeraldGreen);
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  void _cancelEdit() => setState(() => _isEditing = false);

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avDir = Directory('${appDir.path}/avatars');
      if (!await avDir.exists()) await avDir.create(recursive: true);
      final dest = '${avDir.path}/${result.files.first.name}';
      await File(result.files.first.path!).copy(dest);
      Provider.of<ApiClient>(context, listen: false).updateCurrentUser({'avatar_url': dest});
      HiveDatabase.instance.updateCurrentUser({'avatar_url': dest});
      setState(() => _userData['avatar_url'] = dest);
    } catch (_) {}
  }

  void _showPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecruiterPreviewScreen(
          userData: _userData,
          profile: _profile,
          stats: _stats,
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.livesRed),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.post('profile/delete-account/');
    await api.logout();
  }

  Future<void> _logout() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await api.logout();
  }

  String _val(dynamic v) => (v?.toString() ?? '').trim();
  String _display(String key) => _val(_profile[key]).isNotEmpty ? _val(_profile[key]) : 'Not Provided';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: widget.hideAppBar ? null : AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.neonBlue)),
      );
    }

    final name = '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : '@${_userData['username'] ?? ''}';
    final avatarUrl = _userData['avatar_url']?.toString().isNotEmpty == true
        ? _userData['avatar_url'].toString() : null;

    return Scaffold(
      appBar: widget.hideAppBar
          ? null
          : AppBar(
              title: Text(_isEditing ? 'Edit Profile' : displayName),
              actions: [
                if (_isEditing) ...[
                  IconButton(icon: const Icon(Icons.close), tooltip: 'Cancel', onPressed: _cancelEdit),
                  _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen))
                      : IconButton(icon: const Icon(Icons.check, color: AppTheme.emeraldGreen), tooltip: 'Save', onPressed: _save),
                ] else ...[
                  IconButton(icon: const Icon(Icons.visibility_outlined), tooltip: 'Preview as candidate', onPressed: _showPreview),
                  IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit Profile', onPressed: _enterEdit),
                  IconButton(icon: const Icon(Icons.logout_rounded), tooltip: 'Logout', onPressed: _logout),
                ],
              ],
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.hideAppBar) ...[
              _buildInlineActions(),
              const SizedBox(height: 16),
            ],
            _buildHeader(avatarUrl, displayName),
            const SizedBox(height: 16),
            if (_isEditing) _buildEditForm() else _buildProfileView(),
            const SizedBox(height: 24),
            if (!_isEditing) _buildDangerZone(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_isEditing) ...[
            TextButton.icon(
              onPressed: _cancelEdit,
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              label: const Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(height: 20, width: 1, color: AppTheme.divider),
            _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emeraldGreen))
                : TextButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, color: AppTheme.emeraldGreen, size: 18),
                    label: const Text('Save Changes', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
          ] else ...[
            TextButton.icon(
              onPressed: _showPreview,
              icon: const Icon(Icons.visibility_outlined, color: AppTheme.neonBlue, size: 18),
              label: const Text('Preview', style: TextStyle(color: AppTheme.neonBlue, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(height: 20, width: 1, color: AppTheme.divider),
            TextButton.icon(
              onPressed: _enterEdit,
              icon: const Icon(Icons.edit_outlined, color: AppTheme.neonPurple, size: 18),
              label: const Text('Edit Profile', style: TextStyle(color: AppTheme.neonPurple, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Container(height: 20, width: 1, color: AppTheme.divider),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, color: AppTheme.livesRed, size: 18),
              label: const Text('Logout', style: TextStyle(color: AppTheme.livesRed, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String? avatarUrl, String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          GestureDetector(
            onTap: _isEditing ? _pickAvatar : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.neonBlue.withValues(alpha: 0.1),
                  backgroundImage: avatarUrl != null
                      ? (avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : FileImage(File(avatarUrl)))
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.business, color: AppTheme.neonBlue, size: 50) : null,
                ),
                if (_isEditing)
                  Positioned(bottom: 0, right: 0, child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(color: AppTheme.neonBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (_val(_profile['designation']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_profile['designation'], style: const TextStyle(color: AppTheme.neonBlue, fontSize: 14)),
            ),
          if (_val(_profile['company_name']).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.business, size: 14, color: Colors.white38),
                const SizedBox(width: 4),
                Text(_profile['company_name'], style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ]),
            ),
          if (_isEditing)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tap Logo to Upload/Change Company Logo',
                style: TextStyle(color: Colors.white30, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        _buildStatCards(),
        const SizedBox(height: 16),
        _buildRecruitmentChart(),
        const SizedBox(height: 16),
        _infoCard('Contact Information', Icons.contact_mail_outlined, [
          _infoRow('Email', _userData['email'] ?? ''),
          _infoRow('Company Email', _display('company_email')),
          _infoRow('Phone', _display('phone')),
        ]),
        const SizedBox(height: 12),
        _infoCard('Company Details', Icons.business_outlined, [
          _infoRow('Company Name', _display('company_name')),
          _infoRow('Recruiter Name', '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim().isNotEmpty ? '${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim() : '@${_userData['username']}'),
          _infoRow('Role / Designation', _display('designation')),
          _infoRow('Location', _display('location')),
          _infoRow('Website', _display('company_website')),
        ]),
        if (_val(_profile['company_description']).isNotEmpty) ...[
          const SizedBox(height: 12),
          _infoCard('About Company', Icons.info_outline, [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_profile['company_description'], style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _buildStatCards() {
    final exams = _stats['total_exams_created'] ?? 0;
    final hired = _stats['total_candidates_hired'] ?? 0;
    final assessed = _stats['total_candidates'] ?? 0;
    final avgScore = _stats['avg_score'] ?? 0.0;
    final activeOpenings = _stats['active_job_openings'] ?? 0;

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
          const Text('Company Performance Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),
          Row(children: [
            _statCard('Exams Conducted', '$exams', Icons.quiz_outlined, AppTheme.neonPurple),
            const SizedBox(width: 8),
            _statCard('Candidates Recruited', '$hired', Icons.person_add_alt, AppTheme.emeraldGreen),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('Candidates Assessed', '$assessed', Icons.people_outline, AppTheme.neonBlue),
            const SizedBox(width: 8),
            _statCard('Average Score', '${((avgScore) as num).toStringAsFixed(1)}%', Icons.bar_chart, AppTheme.goldAccent),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('Active Openings', '$activeOpenings', Icons.work_outline, Colors.cyan),
            const SizedBox(width: 8),
            _statCard('Company Joining Date', _userData['date_joined'] != null ? _userData['date_joined'].toString().substring(0, 10) : '-', Icons.calendar_month_outlined, Colors.orange),
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
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildRecruitmentChart() {
    final assessedCount = _stats['total_candidates'] as int? ?? 12;
    final double m1 = (assessedCount * 0.15).clamp(1.0, 100.0);
    final double m2 = (assessedCount * 0.20).clamp(2.0, 100.0);
    final double m3 = (assessedCount * 0.10).clamp(1.0, 100.0);
    final double m4 = (assessedCount * 0.25).clamp(3.0, 100.0);
    final double m5 = (assessedCount * 0.30).clamp(4.0, 100.0);

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
              const Icon(Icons.bar_chart, color: AppTheme.neonPurple, size: 20),
              const SizedBox(width: 8),
              const Text('Monthly Candidate Assessments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                  getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[idx], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: m1, color: AppTheme.neonPurple, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: m2, color: AppTheme.neonBlue, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: m3, color: AppTheme.emeraldGreen, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: m4, color: AppTheme.goldAccent, width: 14, borderRadius: BorderRadius.circular(4))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: m5, color: AppTheme.neonPurple, width: 14, borderRadius: BorderRadius.circular(4))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
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
              const Icon(Icons.edit_outlined, color: AppTheme.neonBlue, size: 20),
              const SizedBox(width: 8),
              const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Company Information'),
          const SizedBox(height: 8),
          TextField(
            controller: _companyC,
            decoration: const InputDecoration(
              hintText: 'Company Name *',
              prefixIcon: Icon(Icons.business, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _designationC,
            decoration: const InputDecoration(
              hintText: 'Your Role / Designation',
              prefixIcon: Icon(Icons.badge_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Contact Details'),
          const SizedBox(height: 8),
          TextField(
            controller: _companyEmailC,
            decoration: const InputDecoration(
              hintText: 'Official Company Email',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneC,
            decoration: const InputDecoration(
              hintText: 'Contact Phone Number',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Location & Web'),
          const SizedBox(height: 8),
          TextField(
            controller: _locationC,
            decoration: const InputDecoration(
              hintText: 'Company Location',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _websiteC,
            decoration: const InputDecoration(
              hintText: 'Company Website URL (Optional)',
              prefixIcon: Icon(Icons.language_outlined, size: 20),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          const _SectionLabel('About Company'),
          const SizedBox(height: 8),
          TextField(
            controller: _descC,
            decoration: const InputDecoration(
              hintText: 'Describe your company, culture, and what you look for in candidates',
              alignLabelWithHint: true,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Update Profile', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelEdit,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel', style: TextStyle(fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
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

  Widget _buildDangerZone() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.livesRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Danger Zone', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.livesRed, fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_forever_rounded, color: AppTheme.livesRed),
            label: const Text('Delete Account', style: TextStyle(color: AppTheme.livesRed)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.livesRed),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white54, letterSpacing: 0.5,
    ));
  }
}
