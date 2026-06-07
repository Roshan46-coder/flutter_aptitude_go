import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _userData = {};
  List<dynamic> _attempts = [];
  List<dynamic> _catStats = [];
  List<dynamic> _uploadedCertificates = [];
  int _profileScore = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    final user = api.currentUser;
    if (user == null) return;

    final username = user['username'] as String? ?? 'current_user';
    final saved = HiveDatabase.instance.getCandidateProfile(username);
    setState(() {
      _userData = Map<String, dynamic>.from(user);
      _profile = Map<String, dynamic>.from(saved);
      _profileScore = (user['profile_score'] as num?)?.toInt() ?? _completionPct();
      _attempts = [];
      _catStats = [];
      _isLoading = false;
    });

    try {
      final resp = await api.get('profile/');
      if (mounted) {
        final d = resp.data;
        final u = d['user'] as Map? ?? {};
        setState(() {
          _userData.addAll(Map<String, dynamic>.from(u));
          _attempts = (d['attempts'] as List?) ?? [];
          _catStats = (d['category_stats'] as List?) ?? [];
          _profileScore = (u['profile_score'] as num?)?.toInt() ?? _profileScore;
          final certs = d['certificates'] as List?;
          if (certs != null && certs.isNotEmpty) {
            _uploadedCertificates = certs;
          }
        });
      }
    } catch (_) {}

    try {
      final dataResp = await api.get('profile/data/');
      if (mounted) {
        final d = dataResp.data;
        final serverProfile = d['profile_data'] as Map? ?? {};
        if (serverProfile.isNotEmpty) {
          setState(() {
            serverProfile.forEach((k, v) {
              if (v != null && (v is! List || v.isNotEmpty) && (v is! String || v.isNotEmpty)) {
                _profile[k] = v;
              }
            });
            _profileScore = (d['profile_score'] as num?)?.toInt() ?? _profileScore;
          });
        }
      }
    } catch (_) {}

    try {
      final certResp = await api.get('profile/certificates/');
      if (mounted) {
        setState(() {
          final certs = certResp.data['certificates'] as List?;
          if (certs != null && certs.isNotEmpty) {
            _uploadedCertificates = certs;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final user = Provider.of<ApiClient>(context, listen: false).currentUser;
    if (user == null) return;
    final username = user['username'] as String? ?? 'current_user';
    await HiveDatabase.instance.saveCandidateProfile(username, _profile);

    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final resp = await api.post('profile/data/save/', data: {'profile_data': _profile});
      if (mounted) {
        final d = resp.data;
        setState(() {
          _profileScore = (d['profile_score'] as num?)?.toInt() ?? _profileScore;
        });
        api.updateCurrentUser({'profile_score': _profileScore});
        HiveDatabase.instance.updateCurrentUser({'profile_score': _profileScore});
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved'), backgroundColor: AppTheme.emeraldGreen),
      );
    }
  }

  int _completionPct() {
    int total = 0, filled = 0;
    if ((_profile['headline'] ?? '').isNotEmpty) filled++;
    if ((_profile['bio'] ?? '').isNotEmpty) filled++;
    if ((_profile['location'] ?? '').isNotEmpty) filled++;
    if ((_profile['phone'] ?? '').isNotEmpty) filled++;
    if ((_userData['avatar_url'] ?? '').isNotEmpty) filled++;
    if ((_profile['education'] as List?)?.isNotEmpty ?? false) filled++;
    if ((_profile['skills'] as List?)?.isNotEmpty ?? false) filled++;
    if ((_profile['projects'] as List?)?.isNotEmpty ?? false) filled++;
    if ((_profile['experience'] as List?)?.isNotEmpty ?? false) filled++;
    if ((_profile['certifications'] as List?)?.isNotEmpty ?? false) filled++;
    if ((_profile['resume_path'] ?? '').isNotEmpty) filled++;
    if ((_profile['portfolio_url'] ?? '').isNotEmpty) filled++;
    total = 12;
    return total > 0 ? (filled * 100 ~/ total) : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.save_outlined), tooltip: 'Save', onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCompletionBar(),
            const SizedBox(height: 16),
            _buildQuickOverview(),
            const SizedBox(height: 16),
            _buildPersonalInfo(),
            const SizedBox(height: 16),
            _buildEducation(),
            const SizedBox(height: 16),
            _buildSkills(),
            const SizedBox(height: 16),
            _buildProjects(),
            const SizedBox(height: 16),
            _buildExperience(),
            const SizedBox(height: 16),
            _buildCertificatesSection(),
            const SizedBox(height: 16),
            _buildResumePortfolio(),
            const SizedBox(height: 16),
            _buildCareerPrefs(),
            const SizedBox(height: 16),
            _buildAchievements(),
            const SizedBox(height: 16),
            _buildAssessmentPerformance(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(radius: 48, backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                  backgroundImage: _userData['avatar_url'] != null ? NetworkImage(_userData['avatar_url']) : null,
                  child: _userData['avatar_url'] == null ? const Icon(Icons.person, color: AppTheme.neonPurple, size: 48) : null,
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.neonPurple, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('${_userData['first_name'] ?? ''} ${_userData['last_name'] ?? ''}'.trim().isEmpty
              ? '@${_userData['username'] ?? ''}'
              : '${_userData['first_name']} ${_userData['last_name']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('@${_userData['username'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCompletionBar() {
    final pct = _completionPct();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Row(
        children: [
          const Icon(Icons.pie_chart_outline, color: AppTheme.neonPurple, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Profile Completion', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppTheme.divider, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonPurple), minHeight: 6)),
          ])),
          const SizedBox(width: 12),
          Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.neonPurple)),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final avDir = Directory('${appDir.path}/avatars');
      if (!await avDir.exists()) await avDir.create(recursive: true);
      final dest = '${avDir.path}/${file.name}';
      await File(file.path!).copy(dest);
      Provider.of<ApiClient>(context, listen: false).updateCurrentUser({'avatar_url': dest});
      HiveDatabase.instance.updateCurrentUser({'avatar_url': dest});
      setState(() => _userData['avatar_url'] = dest);
    } catch (_) {}
  }

  Widget _buildQuickOverview() {
    final expCount = (_profile['experience'] as List?)?.length ?? 0;
    final skillCount = (_profile['skills'] as List?)?.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          _overviewCard('Profile Score', '$_profileScore%', Icons.pie_chart, AppTheme.neonPurple),
          const SizedBox(width: 8),
          _overviewCard('Level', '${_userData['level'] ?? 1}', Icons.bolt, AppTheme.goldAccent),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _overviewCard('Experience', '$expCount roles', Icons.work_outline, AppTheme.neonBlue),
          const SizedBox(width: 8),
          _overviewCard('Skills', '$skillCount', Icons.psychology_outlined, AppTheme.emeraldGreen),
        ]),
      ]),
    );
  }

  Widget _overviewCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  // ── PERSONAL INFO ──────────────────────────────────────────────────────────

  Widget _buildPersonalInfo() {
    return _sectionCard('Personal Information', Icons.person_outline, () => _editPersonalInfo(), [
      _infoRow('Headline', _profile['headline'] ?? 'Not set'),
      _infoRow('Location', _profile['location'] ?? 'Not set'),
      _infoRow('Phone', _profile['phone'] ?? 'Not set'),
      _infoRow('Email', _userData['email'] ?? ''),
      _infoRow('Bio', _profile['bio'] ?? 'Not set'),
    ]);
  }

  Future<void> _editPersonalInfo() async {
    final headlineC = TextEditingController(text: _profile['headline'] ?? '');
    final locC = TextEditingController(text: _profile['location'] ?? '');
    final phoneC = TextEditingController(text: _profile['phone'] ?? '');
    final bioC = TextEditingController(text: _profile['bio'] ?? '');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: const Text('Edit Personal Info'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: headlineC, decoration: const InputDecoration(hintText: 'Professional Headline')),
        const SizedBox(height: 12),
        TextField(controller: locC, decoration: const InputDecoration(hintText: 'Location')),
        const SizedBox(height: 12),
        TextField(controller: phoneC, decoration: const InputDecoration(hintText: 'Phone Number'), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(controller: bioC, decoration: const InputDecoration(hintText: 'Short Bio / About Me'), maxLines: 3),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      setState(() {
        _profile['headline'] = headlineC.text.trim();
        _profile['location'] = locC.text.trim();
        _profile['phone'] = phoneC.text.trim();
        _profile['bio'] = bioC.text.trim();
      });
    }
  }

  // ── EDUCATION ──────────────────────────────────────────────────────────────

  Widget _buildEducation() {
    final list = List<Map<String, dynamic>>.from((_profile['education'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    return _sectionCard('Education', Icons.school_outlined, null, [
      ...list.map((e) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text(e['institution'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${e['degree'] ?? ''} · ${e['branch'] ?? ''}\n${e['start_year'] ?? ''} - ${e['grad_year'] ?? ''} · GPA: ${e['gpa'] ?? '-'}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editEducation(list.indexOf(e))),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.livesRed), onPressed: () {
            setState(() { list.removeAt(list.indexOf(e)); _profile['education'] = list; });
          }),
        ]),
      )),
      TextButton.icon(
        onPressed: () => _addEducation(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Education'),
      ),
    ]);
  }

  Future<void> _addEducation() => _editEducation(-1);

  Future<void> _editEducation(int index) async {
    final list = List<Map<String, dynamic>>.from((_profile['education'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final isNew = index < 0 || index >= list.length;
    final item = isNew ? <String, dynamic>{} : Map<String, dynamic>.from(list[index]);
    final instC = TextEditingController(text: item['institution'] ?? '');
    final degC = TextEditingController(text: item['degree'] ?? '');
    final brC = TextEditingController(text: item['branch'] ?? '');
    final gpaC = TextEditingController(text: item['gpa'] ?? '');
    final syC = TextEditingController(text: item['start_year'] ?? '');
    final gyC = TextEditingController(text: item['grad_year'] ?? '');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: Text(isNew ? 'Add Education' : 'Edit Education'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: instC, decoration: const InputDecoration(hintText: 'Institution Name')),
        const SizedBox(height: 10),
        TextField(controller: degC, decoration: const InputDecoration(hintText: 'Degree')),
        const SizedBox(height: 10),
        TextField(controller: brC, decoration: const InputDecoration(hintText: 'Branch / Specialization')),
        const SizedBox(height: 10),
        TextField(controller: gpaC, decoration: const InputDecoration(hintText: 'CGPA / GPA'), keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: syC, decoration: const InputDecoration(hintText: 'Start Year'), keyboardType: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: gyC, decoration: const InputDecoration(hintText: 'Grad Year'), keyboardType: TextInputType.number)),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      final updated = {
        'institution': instC.text.trim(), 'degree': degC.text.trim(), 'branch': brC.text.trim(),
        'gpa': gpaC.text.trim(), 'start_year': syC.text.trim(), 'grad_year': gyC.text.trim(),
      };
      if (isNew) { list.add(updated); } else { list[index] = updated; }
      setState(() => _profile['education'] = list);
    }
  }

  // ── SKILLS ─────────────────────────────────────────────────────────────────

  Widget _buildSkills() {
    final list = List<Map<String, dynamic>>.from((_profile['skills'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    return _sectionCard('Skills', Icons.psychology_outlined, null, [
      Wrap(spacing: 8, runSpacing: 8, children: list.map((s) => Chip(
        label: Text('${s['name'] ?? ''}', style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () { setState(() { list.remove(s); _profile['skills'] = list; }); },
        backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.12),
        side: BorderSide.none,
      )).toList()),
      TextButton.icon(
        onPressed: () => _addSkill(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Skill'),
      ),
    ]);
  }

  Future<void> _addSkill() async {
    final nameC = TextEditingController();
    final levels = ['Beginner', 'Intermediate', 'Advanced', 'Expert'];
    String selectedLevel = 'Intermediate';
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: const Text('Add Skill'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(hintText: 'Skill name')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: selectedLevel, isExpanded: true, decoration: const InputDecoration(hintText: 'Proficiency'),
          items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) { if (v != null) selectedLevel = v; },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ));
    if (result == true && nameC.text.trim().isNotEmpty) {
      final list = List<Map<String, dynamic>>.from((_profile['skills'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
      list.add({'name': nameC.text.trim(), 'level': selectedLevel});
      setState(() => _profile['skills'] = list);
    }
  }

  // ── PROJECTS ───────────────────────────────────────────────────────────────

  Widget _buildProjects() {
    final list = List<Map<String, dynamic>>.from((_profile['projects'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    return _sectionCard('Projects', Icons.folder_outlined, null, [
      ...list.map((p) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${p['role'] ?? ''} · ${p['techs'] ?? ''}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editProject(list.indexOf(p))),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.livesRed), onPressed: () {
            setState(() { list.removeAt(list.indexOf(p)); _profile['projects'] = list; });
          }),
        ]),
      )),
      TextButton.icon(onPressed: () => _addProject(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Project')),
    ]);
  }

  Future<void> _addProject() => _editProject(-1);

  Future<void> _editProject(int index) async {
    final list = List<Map<String, dynamic>>.from((_profile['projects'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final isNew = index < 0 || index >= list.length;
    final item = isNew ? <String, dynamic>{} : Map<String, dynamic>.from(list[index]);
    final tc = TextEditingController(text: item['title'] ?? '');
    final dc = TextEditingController(text: item['description'] ?? '');
    final techC = TextEditingController(text: item['techs'] ?? '');
    final roleC = TextEditingController(text: item['role'] ?? '');
    final ghC = TextEditingController(text: item['github'] ?? '');
    final liveC = TextEditingController(text: item['live_demo'] ?? '');
    final durC = TextEditingController(text: item['duration'] ?? '');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: Text(isNew ? 'Add Project' : 'Edit Project'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: tc, decoration: const InputDecoration(hintText: 'Project Title')),
        const SizedBox(height: 10),
        TextField(controller: dc, decoration: const InputDecoration(hintText: 'Description'), maxLines: 3),
        const SizedBox(height: 10),
        TextField(controller: techC, decoration: const InputDecoration(hintText: 'Technologies (comma separated)')),
        const SizedBox(height: 10),
        TextField(controller: roleC, decoration: const InputDecoration(hintText: 'Your Role')),
        const SizedBox(height: 10),
        TextField(controller: ghC, decoration: const InputDecoration(hintText: 'GitHub Link')),
        const SizedBox(height: 10),
        TextField(controller: liveC, decoration: const InputDecoration(hintText: 'Live Demo Link')),
        const SizedBox(height: 10),
        TextField(controller: durC, decoration: const InputDecoration(hintText: 'Duration (e.g. Jan 2024 - Mar 2024)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      final updated = {'title': tc.text.trim(), 'description': dc.text.trim(), 'techs': techC.text.trim(),
        'role': roleC.text.trim(), 'github': ghC.text.trim(), 'live_demo': liveC.text.trim(), 'duration': durC.text.trim()};
      if (isNew) { list.add(updated); } else { list[index] = updated; }
      setState(() => _profile['projects'] = list);
    }
  }

  // ── EXPERIENCE ─────────────────────────────────────────────────────────────

  Widget _buildExperience() {
    final list = List<Map<String, dynamic>>.from((_profile['experience'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    return _sectionCard('Experience', Icons.work_outline, null, [
      ...list.map((e) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text('${e['position'] ?? ''} @ ${e['company'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${e['duration'] ?? ''}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editExperience(list.indexOf(e))),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.livesRed), onPressed: () {
            setState(() { list.removeAt(list.indexOf(e)); _profile['experience'] = list; });
          }),
        ]),
      )),
      TextButton.icon(onPressed: () => _addExperience(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Experience')),
    ]);
  }

  Future<void> _addExperience() => _editExperience(-1);

  Future<void> _editExperience(int index) async {
    final list = List<Map<String, dynamic>>.from((_profile['experience'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    final isNew = index < 0 || index >= list.length;
    final item = isNew ? <String, dynamic>{} : Map<String, dynamic>.from(list[index]);
    final coC = TextEditingController(text: item['company'] ?? '');
    final posC = TextEditingController(text: item['position'] ?? '');
    final durC = TextEditingController(text: item['duration'] ?? '');
    final respC = TextEditingController(text: item['responsibilities'] ?? '');
    final achC = TextEditingController(text: item['achievements'] ?? '');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: Text(isNew ? 'Add Experience' : 'Edit Experience'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: coC, decoration: const InputDecoration(hintText: 'Company Name')),
        const SizedBox(height: 10),
        TextField(controller: posC, decoration: const InputDecoration(hintText: 'Position')),
        const SizedBox(height: 10),
        TextField(controller: durC, decoration: const InputDecoration(hintText: 'Duration (e.g. Jun 2023 - Present)')),
        const SizedBox(height: 10),
        TextField(controller: respC, decoration: const InputDecoration(hintText: 'Responsibilities'), maxLines: 3),
        const SizedBox(height: 10),
        TextField(controller: achC, decoration: const InputDecoration(hintText: 'Achievements'), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      final updated = {'company': coC.text.trim(), 'position': posC.text.trim(), 'duration': durC.text.trim(),
        'responsibilities': respC.text.trim(), 'achievements': achC.text.trim()};
      if (isNew) { list.add(updated); } else { list[index] = updated; }
      setState(() => _profile['experience'] = list);
    }
  }

  // ── CERTIFICATES (BACKEND FILE UPLOADS) ─────────────────────────────────────

  Widget _buildCertificatesSection() {
    return _sectionCard('Certificates', Icons.verified_outlined, null, [
      if (_uploadedCertificates.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Text('No Certificates Uploaded', style: TextStyle(color: Colors.white24))),
        )
      else
        ...(_uploadedCertificates.asMap().entries.map((entry) {
          final c = Map<String, dynamic>.from(entry.value);
          final fileUrl = c['file_url'] ?? '';
          final fileName = c['title'] ?? 'Certificate';
          final fileType = (c['file_type'] ?? '').toString().toUpperCase();
          final uploadedAt = c['uploaded_at'] ?? '';
          final isImage = c['is_image'] == true;
          final formattedDate = uploadedAt.toString().length >= 10 ? uploadedAt.toString().substring(0, 10) : uploadedAt.toString();
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.neonPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isImage ? Icons.image_outlined : Icons.description_outlined,
                    color: AppTheme.neonPurple, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$fileType · $formattedDate', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ]),
                ),
                if (fileUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.neonBlue),
                    onPressed: () => _openCertificate(fileUrl),
                    tooltip: 'View',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: AppTheme.livesRed),
                  onPressed: () => _deleteCertificate(c['id']),
                  tooltip: 'Delete',
                ),
              ],
            ),
          );
        })),
      const SizedBox(height: 4),
      TextButton.icon(
        onPressed: _uploadCertificate,
        icon: const Icon(Icons.upload_file, size: 18),
        label: const Text('Upload Certificate'),
      ),
    ]);
  }

  Future<void> _uploadCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    final file = result.files.first;
    final nameC = TextEditingController(text: file.name.split('.').first);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Upload Certificate'),
        content: TextField(
          controller: nameC,
          decoration: const InputDecoration(hintText: 'Certificate Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Upload')),
        ],
      ),
    );
    if (confirmed != true || nameC.text.trim().isEmpty) return;
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      await api.uploadFile(
        'profile/upload-certificate/',
        file.path!,
        'file',
        extraFields: {'title': nameC.text.trim()},
      );
    } catch (_) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/certificates/${file.name}';
        await File(file.path!).copy(localPath);
        final api = Provider.of<ApiClient>(context, listen: false);
        await api.post('profile/upload-certificate/', data: {
          'title': nameC.text.trim(),
          'filename': file.name,
          'local_path': localPath,
        });
      } catch (_) {}
    }
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final certResp = await api.get('profile/certificates/');
      if (mounted) {
        setState(() {
          _uploadedCertificates = (certResp.data['certificates'] as List?) ?? [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate uploaded'), backgroundColor: AppTheme.emeraldGreen),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteCertificate(int certId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Certificate'),
        content: const Text('Are you sure you want to delete this certificate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.livesRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      await api.post('profile/delete-certificate/$certId/');
      final certResp = await api.get('profile/certificates/');
      if (mounted) {
        setState(() {
          _uploadedCertificates = (certResp.data['certificates'] as List?) ?? [];
        });
      }
    } catch (_) {}
  }

  void _openCertificate(String fileUrl) {
    final isImage = ['.jpg', '.jpeg', '.png', '.webp', '.gif']
        .any((ext) => fileUrl.toLowerCase().endsWith(ext));
    if (isImage) {
      Widget imageWidget;
      if (fileUrl.startsWith('http')) {
        imageWidget = Image.network(fileUrl, fit: BoxFit.contain);
      } else {
        imageWidget = Image.file(File(fileUrl), fit: BoxFit.contain);
      }
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
          ),
        ),
      );
      return;
    }
    final api = Provider.of<ApiClient>(context, listen: false);
    final base = api.baseUrl.replaceAll('/api/', '');
    final fullUrl = fileUrl.startsWith('http') ? fileUrl : '$base$fileUrl';
    launchUrl(Uri.parse(fullUrl), mode: LaunchMode.externalApplication);
  }

  // ── RESUME & PORTFOLIO ─────────────────────────────────────────────────────

  Widget _buildResumePortfolio() {
    return _sectionCard('Resume & Portfolio', Icons.description_outlined, () => _editResumePortfolio(), [
      _infoRow('Resume', _profile['resume_path']?.isNotEmpty == true ? 'Uploaded' : 'Not uploaded'),
      _infoRow('Portfolio', _profile['portfolio_url'] ?? 'Not set'),
      _infoRow('GitHub', _profile['github_url'] ?? _userData['github_url'] ?? 'Not set'),
      _infoRow('LinkedIn', _profile['linkedin_url'] ?? _userData['linkedin_url'] ?? 'Not set'),
    ]);
  }

  Future<void> _editResumePortfolio() async {
    final pc = TextEditingController(text: _profile['portfolio_url'] ?? '');
    final gc = TextEditingController(text: _profile['github_url'] ?? _userData['github_url'] ?? '');
    final lc = TextEditingController(text: _profile['linkedin_url'] ?? _userData['linkedin_url'] ?? '');
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: const Text('Resume & Portfolio'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ElevatedButton.icon(onPressed: () async {
          final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
          if (res != null && res.files.isNotEmpty && res.files.first.path != null) {
            final appDir = await getApplicationDocumentsDirectory();
            final rDir = Directory('${appDir.path}/resumes');
            if (!await rDir.exists()) await rDir.create(recursive: true);
            final dest = '${rDir.path}/${res.files.first.name}';
            await File(res.files.first.path!).copy(dest);
            setState(() => _profile['resume_path'] = dest);
            if (ctx.mounted) Navigator.pop(ctx);
          }
        }, icon: const Icon(Icons.upload_file, size: 18), label: Text(_profile['resume_path']?.isNotEmpty == true ? 'Replace Resume' : 'Upload Resume')),
        const SizedBox(height: 12),
        TextField(controller: pc, decoration: const InputDecoration(hintText: 'Portfolio Website URL')),
        const SizedBox(height: 10),
        TextField(controller: gc, decoration: const InputDecoration(hintText: 'GitHub Profile URL')),
        const SizedBox(height: 10),
        TextField(controller: lc, decoration: const InputDecoration(hintText: 'LinkedIn Profile URL')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      setState(() {
        _profile['portfolio_url'] = pc.text.trim();
        _profile['github_url'] = gc.text.trim();
        _profile['linkedin_url'] = lc.text.trim();
      });
    }
  }

  // ── CAREER PREFERENCES ─────────────────────────────────────────────────────

  Widget _buildCareerPrefs() {
    return _sectionCard('Career Preferences', Icons.trending_up, () => _editCareerPrefs(), [
      _infoRow('Preferred Roles', (_profile['preferred_roles'] as List?)?.join(', ') ?? 'Not set'),
      _infoRow('Location', _profile['preferred_location'] ?? 'Not set'),
      _infoRow('Expected Salary', _profile['expected_salary'] ?? 'Not set'),
      _infoRow('Employment Type', _profile['employment_type'] ?? 'Not set'),
      _infoRow('Availability', _profile['availability'] ?? 'Not set'),
    ]);
  }

  Future<void> _editCareerPrefs() async {
    final rolesC = TextEditingController(text: (_profile['preferred_roles'] as List?)?.join(', ') ?? '');
    final locC = TextEditingController(text: _profile['preferred_location'] ?? '');
    final salC = TextEditingController(text: _profile['expected_salary'] ?? '');
    final empTypes = ['Internship', 'Full-Time', 'Part-Time', 'Freelance'];
    final availTypes = ['Immediately', '15 Days', '1 Month', '3 Months'];
    final savedEmp = _profile['employment_type'] as String?;
    final savedAvail = _profile['availability'] as String?;
    String empType = (savedEmp != null && empTypes.contains(savedEmp)) ? savedEmp : empTypes[0];
    String avail = (savedAvail != null && availTypes.contains(savedAvail)) ? savedAvail : availTypes[0];
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: const Text('Career Preferences'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: rolesC, decoration: const InputDecoration(hintText: 'Preferred Roles (comma separated)')),
        const SizedBox(height: 10),
        TextField(controller: locC, decoration: const InputDecoration(hintText: 'Preferred Location')),
        const SizedBox(height: 10),
        TextField(controller: salC, decoration: const InputDecoration(hintText: 'Expected Salary'), keyboardType: TextInputType.text),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: empType, isExpanded: true, decoration: const InputDecoration(hintText: 'Employment Type'),
          items: empTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) { if (v != null) empType = v; },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: avail, isExpanded: true, decoration: const InputDecoration(hintText: 'Availability'),
          items: availTypes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
          onChanged: (v) { if (v != null) avail = v; },
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ));
    if (result == true) {
      setState(() {
        _profile['preferred_roles'] = rolesC.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        _profile['preferred_location'] = locC.text.trim();
        _profile['expected_salary'] = salC.text.trim();
        _profile['employment_type'] = empType;
        _profile['availability'] = avail;
      });
    }
  }

  // ── ACHIEVEMENTS ───────────────────────────────────────────────────────────

  Widget _buildAchievements() {
    final list = List<Map<String, dynamic>>.from((_profile['achievements'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    return _sectionCard('Achievements', Icons.emoji_events_outlined, null, [
      ...list.map((a) => ListTile(
        dense: true, contentPadding: EdgeInsets.zero,
        title: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('${a['type'] ?? ''} · ${a['date'] ?? ''}'),
        trailing: IconButton(icon: const Icon(Icons.delete, size: 18, color: AppTheme.livesRed), onPressed: () {
          setState(() { list.removeAt(list.indexOf(a)); _profile['achievements'] = list; });
        }),
      )),
      TextButton.icon(onPressed: _addAchievement, icon: const Icon(Icons.add, size: 18), label: const Text('Add Achievement')),
    ]);
  }

  Future<void> _addAchievement() async {
    final tc = TextEditingController();
    final types = ['Award', 'Hackathon', 'Competition', 'Publication', 'Badge'];
    String type = types[0];
    final dc = TextEditingController();
    final result = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardBg, title: const Text('Add Achievement'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: tc, decoration: const InputDecoration(hintText: 'Title')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: type, isExpanded: true, decoration: const InputDecoration(hintText: 'Type'),
          items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) { if (v != null) type = v; },
        ),
        const SizedBox(height: 10),
        TextField(controller: dc, decoration: const InputDecoration(hintText: 'Description / Date')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ));
    if (result == true && tc.text.trim().isNotEmpty) {
      final list = List<Map<String, dynamic>>.from((_profile['achievements'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
      list.add({'title': tc.text.trim(), 'type': type, 'date': dc.text.trim()});
      setState(() => _profile['achievements'] = list);
    }
  }

  // ── ASSESSMENT PERFORMANCE ─────────────────────────────────────────────────

  Widget _buildAssessmentPerformance() {
    final avgScore = _catStats.isEmpty ? 0.0 : (_catStats.fold<double>(0, (s, e) => s + ((e['avg_score'] as num?)?.toDouble() ?? 0)) / _catStats.length);
    final totalAttempts = _attempts.length;
    final latestPct = _attempts.isEmpty ? 0.0 : ((_attempts.last['percentage'] as num?)?.toDouble() ?? 0);
    return _sectionCard('Assessment Performance', Icons.assessment_outlined, null, [
      SizedBox(
        height: 140,
        child: _attempts.isEmpty
            ? const Center(child: Text('No attempts yet', style: TextStyle(color: Colors.white24)))
            : LineChart(LineChartData(
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.divider, strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent)),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [LineChartBarData(
                  spots: _attempts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['percentage'] as num?)?.toDouble() ?? 0)).toList(),
                  isCurved: true, color: AppTheme.neonPurple, barWidth: 2.5,
                  belowBarData: BarAreaData(show: true, color: AppTheme.neonPurple.withValues(alpha: 0.08)),
                  dotData: const FlDotData(show: false),
                )],
              )),
      ),
      const SizedBox(height: 12),
      Row(children: [
        _statChip('Avg Score', avgScore.toStringAsFixed(1), AppTheme.neonPurple),
        const SizedBox(width: 8),
        _statChip('Attempts', '$totalAttempts', AppTheme.neonBlue),
        const SizedBox(width: 8),
        _statChip('Latest', '${latestPct.toStringAsFixed(0)}%', AppTheme.emeraldGreen),
      ]),
    ]);
  }

  // ── HELPERS ─────────────────────────────────────────────────────────────────

  Widget _sectionCard(String title, IconData icon, VoidCallback? onEdit, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(icon, color: AppTheme.neonPurple, size: 20), const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
          if (onEdit != null) IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.white70)))],
    ));
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }
}
