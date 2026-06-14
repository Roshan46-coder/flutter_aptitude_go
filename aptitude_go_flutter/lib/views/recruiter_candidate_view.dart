import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';
import 'inbox_screen.dart';

class RecruiterCandidateView extends StatefulWidget {
  final String username;
  const RecruiterCandidateView({super.key, required this.username});

  @override
  State<RecruiterCandidateView> createState() => _RecruiterCandidateViewState();
}

class _RecruiterCandidateViewState extends State<RecruiterCandidateView> {
  Map<String, dynamic> _candidateUser = {};
  Map<String, dynamic> _profile = {};
  List<dynamic> _candidateAttempts = [];
  List<dynamic> _candidateCertificates = [];
  bool _isLoading = true;
  bool _isLoadingCerts = false;
  bool _isLoadingAttempts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Phase 1: Load basic info from Hive cache instantly
    final users = HiveDatabase.instance.getUsers();
    final target = users.cast<Map<String, dynamic>?>().firstWhere(
      (u) => u?['username'] == widget.username,
      orElse: () => null,
    );

    // Load cached profile, certificates, and attempts from Hive
    final saved = HiveDatabase.instance.getCandidateProfile(widget.username);
    final cachedCerts = HiveDatabase.instance.getCachedCertificates(widget.username);
    final cachedAttempts = HiveDatabase.instance.getCachedAttempts(widget.username);

    if (mounted) {
      setState(() {
        _candidateUser = target ?? {};
        _profile = saved;
        if (cachedCerts.isNotEmpty) _candidateCertificates = cachedCerts;
        if (cachedAttempts.isNotEmpty) _candidateAttempts = cachedAttempts;
        _isLoading = false;
        // Start lazy loading heavy sections in background
        _isLoadingCerts = cachedCerts.isEmpty;
        _isLoadingAttempts = cachedAttempts.isEmpty;
      });
    }

    final api = Provider.of<ApiClient>(context, listen: false);

    // Phase 2: Fetch basic profile data (lightweight)
    try {
      final resp = await api.get('profile/data/${widget.username}/');
      if (mounted) {
        final d = resp.data is Map ? Map<String, dynamic>.from(resp.data) : {};
        final serverProfile = d['profile_data'] as Map? ?? {};
        if (serverProfile.isNotEmpty) {
          setState(() {
            serverProfile.forEach((k, v) {
              if (v != null && (v is! List || v.isNotEmpty) && (v is! String || v.isNotEmpty)) {
                _profile[k] = v;
              }
            });
            _candidateUser['profile_score'] = d['profile_score'];
          });
          HiveDatabase.instance.saveCandidateProfile(widget.username, _profile);
        }
      }
    } catch (_) {}

    // Phase 3: Fetch certificates in background (lazy load)
    _loadCertificates(api);

    // Phase 4: Fetch aptitude scores in background (lazy load)
    _loadAttempts(api);
  }

  Future<void> _loadCertificates(ApiClient api) async {
    if (!mounted) return;
    try {
      final certResp = await api.get('profile/certificates/${widget.username}/');
      if (mounted) {
        final data = certResp.data is Map ? Map<String, dynamic>.from(certResp.data) : {};
        final certs = data['certificates'] as List? ?? [];
        setState(() {
          _candidateCertificates = certs;
          _isLoadingCerts = false;
        });
        HiveDatabase.instance.saveCachedCertificates(widget.username, certs);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCerts = false);
    }
  }

  Future<void> _loadAttempts(ApiClient api) async {
    if (!mounted) return;
    try {
      final profileResp = await api.get('profile/${widget.username}/');
      if (mounted) {
        final d = profileResp.data is Map ? Map<String, dynamic>.from(profileResp.data) : {};
        final attempts = (d['attempts'] as List?) ?? [];
        final userData = d['user'] as Map?;
        // Fallback: capture certificates from profile API if cert endpoint returned empty
        final profileCerts = d['certificates'] as List? ?? [];
        setState(() {
          _candidateAttempts = attempts;
          _isLoadingAttempts = false;
          if (userData != null) {
            _candidateUser.addAll(Map<String, dynamic>.from(userData));
          }
          // If the dedicated cert endpoint has not loaded certs yet (still loading or returned empty),
          // use certs from the full profile response as fallback
          if (_candidateCertificates.isEmpty && profileCerts.isNotEmpty) {
            _candidateCertificates = profileCerts;
            _isLoadingCerts = false;
            HiveDatabase.instance.saveCachedCertificates(widget.username, profileCerts);
          }
        });
        HiveDatabase.instance.saveCachedAttempts(widget.username, attempts);
        if (userData != null) {
          HiveDatabase.instance.saveCandidateProfile(widget.username, _profile);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAttempts = false);
    }
  }

  int _completionPct() {
    int t = 0, f = 0;
    if ((_profile['headline'] ?? '').isNotEmpty) f++;
    if ((_profile['bio'] ?? '').isNotEmpty) f++;
    if ((_profile['location'] ?? '').isNotEmpty) f++;
    if ((_profile['phone'] ?? '').isNotEmpty) f++;
    if ((_profile['resume_path'] ?? '').isNotEmpty) f++;
    if ((_profile['portfolio_url'] ?? '').isNotEmpty) f++;
    if ((_profile['education'] as List?)?.isNotEmpty ?? false) f++;
    if ((_profile['skills'] as List?)?.isNotEmpty ?? false) f++;
    if ((_profile['projects'] as List?)?.isNotEmpty ?? false) f++;
    if ((_profile['experience'] as List?)?.isNotEmpty ?? false) f++;
    if ((_profile['certifications'] as List?)?.isNotEmpty ?? false) f++;
    if ((_profile['achievements'] as List?)?.isNotEmpty ?? false) f++;
    t = 12;
    return t > 0 ? (f * 100 ~/ t) : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: Text('@${widget.username}')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)));
    }
    return Scaffold(
      appBar: AppBar(title: Text('${_candidateUser['first_name'] ?? ''} ${_candidateUser['last_name'] ?? ''}'.trim().isEmpty
          ? '@${widget.username}' : '${_candidateUser['first_name']} ${_candidateUser['last_name']}')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildQuickOverview(),
              const SizedBox(height: 16),
              _buildProfessionalSummary(),
              const SizedBox(height: 16),
              _buildEducationTimeline(),
              const SizedBox(height: 16),
              _buildSkillsDashboard(),
              const SizedBox(height: 16),
              _buildProjectsPortfolio(),
              const SizedBox(height: 16),
              _buildWorkExperience(),
              const SizedBox(height: 16),
              _buildCertificationsDisplay(),
              const SizedBox(height: 16),
              _buildPerformanceAnalytics(),
              const SizedBox(height: 16),
              _buildAchievementsSection(),
              const SizedBox(height: 32),
            ]),
          ),
          _buildStickyActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasResume = (_profile['resume_path'] ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          colors: [AppTheme.neonPurple.withValues(alpha: 0.05), Theme.of(context).cardColor],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        CircleAvatar(radius: 44,
          backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
          backgroundImage: _candidateUser['avatar_url'] != null ? NetworkImage(_candidateUser['avatar_url']) : null,
          child: _candidateUser['avatar_url'] == null
              ? const Icon(Icons.person, color: AppTheme.neonPurple, size: 44) : null,
        ),
        const SizedBox(height: 12),
        Text('${_candidateUser['first_name'] ?? ''} ${_candidateUser['last_name'] ?? ''}'.trim().isEmpty
            ? '@${widget.username}' : '${_candidateUser['first_name']} ${_candidateUser['last_name']}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if ((_profile['headline'] ?? '').isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(_profile['headline'], style: const TextStyle(color: AppTheme.neonPurple, fontSize: 14))),
        if ((_candidateUser['email'] ?? '').isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.email_outlined, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30)), const SizedBox(width: 4),
            Flexible(child: Text(_candidateUser['email'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13), overflow: TextOverflow.ellipsis)),
          ])),
        if ((_profile['location'] ?? '').isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30)), const SizedBox(width: 4),
            Flexible(child: Text(_profile['location'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38), fontSize: 13), overflow: TextOverflow.ellipsis)),
          ])),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (_profile['availability'] ?? '') == 'Immediately'
                ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
                : AppTheme.neonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(_profile['availability'] ?? 'Not specified',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: (_profile['availability'] ?? '') == 'Immediately' ? AppTheme.emeraldGreen : AppTheme.neonBlue)),
        ),
        if (hasResume) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {/* Resume download */},
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download Resume', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.neonPurple),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildQuickOverview() {
    final pct = (_candidateUser['profile_score'] as num?)?.toInt() ?? _completionPct();
    final expCount = (_profile['experience'] as List?)?.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Row(children: [
          _overviewCard('Profile Score', '$pct%', Icons.pie_chart, AppTheme.neonPurple),
          const SizedBox(width: 8),
          _overviewCard('Level', '${HiveDatabase.levelInfo(_candidateUser['exp'] ?? 0)[0]}', Icons.bolt, AppTheme.goldAccent),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _overviewCard('Experience', '$expCount roles', Icons.work_outline, AppTheme.neonBlue),
          const SizedBox(width: 8),
          _overviewCard('Skills', '${(_profile['skills'] as List?)?.length ?? 0}', Icons.psychology_outlined, AppTheme.emeraldGreen),
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
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _buildProfessionalSummary() {
    final bio = _profile['bio'] ?? '';
    final fields = _candidateUser['interested_field'] ?? '';
    final status = _candidateUser['current_status'] ?? '';
    if (bio.isEmpty && fields.isEmpty && status.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Professional Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        if (bio.isNotEmpty) Text(bio, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.70), height: 1.4)),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: _tag(status, AppTheme.neonBlue)),
        if (fields.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: _tag('Interested: $fields', AppTheme.neonPurple)),
      ]),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildEducationTimeline() {
    final list = List<Map<String, dynamic>>.from((_profile['education'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Education', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...list.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(margin: const EdgeInsets.only(top: 4), width: 10, height: 10,
              decoration: const BoxDecoration(color: AppTheme.neonPurple, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['institution'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${e['degree'] ?? ''} · ${e['branch'] ?? ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54))),
              Text('${e['start_year'] ?? ''} - ${e['grad_year'] ?? ''} · GPA: ${e['gpa'] ?? '-'}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.30))),
            ])),
          ]),
        )),
      ]),
    );
  }

  Widget _buildSkillsDashboard() {
    final list = List<Map<String, dynamic>>.from((_profile['skills'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    if (list.isEmpty) return const SizedBox.shrink();
    final levelColors = {'Beginner': Colors.blue, 'Intermediate': AppTheme.neonBlue, 'Advanced': AppTheme.neonPurple, 'Expert': AppTheme.goldAccent};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: list.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (levelColors[s['level']] ?? AppTheme.neonBlue).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (levelColors[s['level']] ?? AppTheme.neonBlue).withValues(alpha: 0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(s['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Text('· ${s['level'] ?? ''}', style: TextStyle(fontSize: 10, color: levelColors[s['level']] ?? AppTheme.neonBlue)),
          ]),
        )).toList()),
      ]),
    );
  }

  Widget _buildProjectsPortfolio() {
    final list = List<Map<String, dynamic>>.from((_profile['projects'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...list.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if ((p['description'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(p['description'], style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))),
            if ((p['role'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Role: ${p['role']}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)))),
            if ((p['techs'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: _tag('${p['techs']}', AppTheme.neonBlue)),
            if ((p['github'] ?? '').isNotEmpty || (p['live_demo'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                if ((p['github'] ?? '').isNotEmpty)
                  TextButton.icon(onPressed: () {/* open link */}, icon: const Icon(Icons.code, size: 14), label: const Text('GitHub', style: TextStyle(fontSize: 11))),
                if ((p['live_demo'] ?? '').isNotEmpty)
                  TextButton.icon(onPressed: () {/* open link */}, icon: const Icon(Icons.open_in_new, size: 14), label: const Text('Live Demo', style: TextStyle(fontSize: 11))),
              ]),
            ],
          ]),
        )),
      ]),
    );
  }

  Widget _buildWorkExperience() {
    final list = List<Map<String, dynamic>>.from((_profile['experience'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    if (list.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Work Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...list.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(margin: const EdgeInsets.only(top: 4), width: 10, height: 10,
              decoration: BoxDecoration(color: AppTheme.neonBlue, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e['position'] ?? ''} @ ${e['company'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(e['duration'] ?? '', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
              if ((e['responsibilities'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(e['responsibilities'], style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)))),
              if ((e['achievements'] ?? '').isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text('🏆 ${e['achievements']}', style: const TextStyle(fontSize: 11, color: AppTheme.goldAccent))),
            ])),
          ]),
        )),
      ]),
    );
  }

  Widget _buildCertificationsDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Uploaded Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        if (_isLoadingCerts)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple.withValues(alpha: 0.6))),
            ),
          )
        else if (_candidateCertificates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No certificates uploaded', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)))),
          )
        else
          ..._candidateCertificates.map((c) {
          final cm = Map<String, dynamic>.from(c);
          final fileUrl = cm['file_url'] ?? '';
          final fileName = cm['title'] ?? 'Certificate';
          final fileType = (cm['file_type'] ?? '').toString().toUpperCase();
          final uploadedAt = (cm['uploaded_at'] ?? '').toString();
          final date = uploadedAt.length >= 10 ? uploadedAt.substring(0, 10) : uploadedAt;
          final isImage = cm['is_image'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppTheme.emeraldGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(isImage ? Icons.image_outlined : Icons.description_outlined, color: AppTheme.emeraldGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('$fileType · $date', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
              ])),
              if (fileUrl.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.neonBlue),
                  onPressed: () => _openCertificateFile(fileUrl),
                  tooltip: 'View',
                ),
            ]),
          );
        }),
      ]),
    );
  }

  void _openCertificateFile(String fileUrl) {
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

  Widget _buildPerformanceAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.assessment_outlined, color: AppTheme.neonPurple, size: 20),
          const SizedBox(width: 8),
          const Text('Aptitude Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        if (_isLoadingAttempts)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple.withValues(alpha: 0.6))),
            ),
          )
        else if (_candidateAttempts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No Test Scores Available', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24)))),
          )
        else
          ...(_candidateAttempts.reversed.map((a) {
            final aMap = Map<String, dynamic>.from(a);
            final score = aMap['score'] ?? 0;
            final total = aMap['total_questions'] ?? 0;
            final pct = aMap['percentage'] ?? (total > 0 ? (score * 100 / total).roundToDouble() : 0.0);
            final category = aMap['category_name'] ?? 'General';
            final completedAt = (aMap['completed_at'] ?? '').toString();
            final date = completedAt.length >= 10 ? completedAt.substring(0, 10) : completedAt;
            final passed = (pct as num) >= 40;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: passed ? AppTheme.emeraldGreen.withValues(alpha: 0.15) : AppTheme.livesRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(passed ? 'PASS' : 'FAIL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: passed ? AppTheme.emeraldGreen : AppTheme.livesRed)),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _scoreChip('Score', '$score/$total', AppTheme.neonPurple),
                  const SizedBox(width: 6),
                  _scoreChip('Percentage', '${pct.toStringAsFixed(1)}%', AppTheme.neonBlue),
                  const SizedBox(width: 6),
                  _scoreChip('Date', date, Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                ]),
              ]),
            );
          })),
      ]),
    );
  }

  Widget _scoreChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)), overflow: TextOverflow.ellipsis),
      ]),
    ));
  }

  Widget _buildAchievementsSection() {
    final list = List<Map<String, dynamic>>.from((_profile['achievements'] as List?)?.map((e) => Map<String, dynamic>.from(e)) ?? []);
    if (list.isEmpty) return const SizedBox.shrink();
    final icons = {'Award': Icons.emoji_events, 'Hackathon': Icons.code, 'Competition': Icons.military_tech,
      'Publication': Icons.article, 'Badge': Icons.verified};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: list.map((a) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppTheme.goldAccent.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.15))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icons[a['type']] ?? Icons.star, size: 16, color: AppTheme.goldAccent),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['title'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              if ((a['type'] ?? '').isNotEmpty) Text(a['type'], style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38))),
            ]),
          ]),
        )).toList()),
      ]),
    );
  }

  Widget _buildStickyActions() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    conversationId: DateTime.now().millisecondsSinceEpoch,
                    otherUsername: widget.username,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emeraldGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }
}
