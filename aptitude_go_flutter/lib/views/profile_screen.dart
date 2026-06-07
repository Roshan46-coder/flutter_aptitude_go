import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'edit_profile_screen.dart';
import 'recruiter_profile_screen.dart';
import 'candidate_recruiter_view.dart';

class ProfileScreen extends StatefulWidget {
  final String? username;
  const ProfileScreen({super.key, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() { _isLoading = true; _error = null; });
    final api = Provider.of<ApiClient>(context, listen: false);
    final endpoint = widget.username != null
        ? 'profile/${widget.username}/'
        : 'profile/';
    try {
      final response = await api.get(endpoint);
      if (mounted) setState(() { _profileData = response.data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load profile.'; _isLoading = false; });
    }
  }

  Future<void> _uploadCertificate() async {
    final api = Provider.of<ApiClient>(context, listen: false);

    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    if (!mounted) return;

    final titleController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Certificate Title'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'e.g. AWS Cloud Practitioner'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Upload')),
        ],
      ),
    );

    if (confirmed != true || titleController.text.isEmpty) return;
    if (!mounted) return;

    // Show uploading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 14),
            Text('Uploading certificate…'),
          ],
        ),
        duration: Duration(seconds: 8),
      ),
    );

    String? localPath;
    try {
      // Save file locally for offline viewing
      final appDir = await getApplicationDocumentsDirectory();
      final certDir = Directory('${appDir.path}/certificates');
      if (!await certDir.exists()) {
        await certDir.create(recursive: true);
      }
      localPath = '${certDir.path}/${file.name}';
      await File(file.path!).copy(localPath);
    } catch (_) {}

    bool success = false;
    try {
      // 1. Try real server upload (multipart)
      final formData = FormData.fromMap({
        'title': titleController.text.trim(),
        'file': await MultipartFile.fromFile(file.path!, filename: file.name),
      });
      await api.dio.post('${api.baseUrl}profile/upload-certificate/', data: formData);
      success = true;
    } catch (_) {
      // 2. Fall back to local Hive storage
      try {
        final resp = await api.post('profile/upload-certificate/', data: {
          'title': titleController.text.trim(),
          'filename': file.name,
          'local_path': localPath,
        });
        success = resp.data['success'] == true;
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate added successfully!'),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
      _fetchProfile(); // Refresh immediately
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          backgroundColor: AppTheme.livesRed,
        ),
      );
    }
  }

  Future<void> _deleteCertificate(int id) async {
    final api = Provider.of<ApiClient>(context, listen: false);

    // Confirm before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Certificate?'),
        content: const Text('This certificate will be permanently removed from your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.livesRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await api.post('profile/delete-certificate/$id/');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate removed.'),
            backgroundColor: AppTheme.emeraldGreen,
          ),
        );
        _fetchProfile();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove certificate.'),
            backgroundColor: AppTheme.livesRed,
          ),
        );
      }
    }
  }

  void _openCertificateFile(Map<String, dynamic> cert) {
    final fileUrl = cert['file_url'] as String? ?? cert['local_path'] as String? ?? '';
    if (fileUrl.isEmpty) return;
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

  Future<void> _deleteAccount() async {
    // Capture context-dependent objects before any async gap
    final api = Provider.of<ApiClient>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(_error!)),
      );
    }

    final user = Map<String, dynamic>.from(_profileData?['user'] as Map? ?? {});
    final isCompany = user['is_company'] == true;

    if (isCompany) {
      if (widget.username == null) {
        return const RecruiterProfileScreen(hideAppBar: false);
      } else {
        return CandidateRecruiterView(
          username: widget.username!,
          recruiterName: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (widget.username == null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
                if (result == true) _fetchProfile();
              },
            ),
            IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfile,
        color: AppTheme.neonPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildProfileContent(user),
        ),
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> user) {
    final attempts = (_profileData!['attempts'] as List?) ?? [];
    final catStats = (_profileData!['category_stats'] as List?) ?? [];
    final certs = (_profileData!['certificates'] as List?) ?? [];
    final isOwnProfile = widget.username == null;
    final isCandidate = user['is_company'] is bool ? !user['is_company'] : true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Header Card
        _buildProfileHeader(user),
        const SizedBox(height: 20),

        // Stats row
        _buildStatsRow(user),
        const SizedBox(height: 20),

        // Social links
        if ((user['linkedin_url'] ?? '').isNotEmpty || (user['github_url'] ?? '').isNotEmpty) ...[
          _buildSocialLinks(user),
          const SizedBox(height: 20),
        ],

        // Performance chart (only for candidates)
        if (isCandidate) ...[
          _buildScoreChart(attempts),
          const SizedBox(height: 20),
        ],

        // Category performance
        if (isCandidate) ...[
          _buildCategoryStats(catStats),
          const SizedBox(height: 20),
        ],

        // Certificates section (own profile only)
        if (isOwnProfile && isCandidate) ...[
          _buildCertificatesSection(certs),
          const SizedBox(height: 20),
        ],

        // Danger zone (own profile only)
        if (isOwnProfile) ...[
          _buildDangerZone(),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    // Read equipped cosmetic flags (set by store purchase)
    final api = Provider.of<ApiClient>(context, listen: false);
    final sessionUser = api.currentUser ?? {};
    final hasGoldenFrame = sessionUser['has_golden_frame'] == true;
    final hasProAvatar   = sessionUser['has_pro_avatar']   == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasGoldenFrame
              ? const Color(0xFFFFD700)
              : AppTheme.divider,
          width: hasGoldenFrame ? 2.2 : 1,
        ),
        boxShadow: hasGoldenFrame
            ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.25), blurRadius: 18, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          // Avatar with optional golden ring
          Stack(
            alignment: Alignment.center,
            children: [
              if (hasGoldenFrame)
                Container(
                  width: 108, height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.45), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                ),
              hasProAvatar
                  ? Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ),
                      child: user['avatar_url'] != null
                          ? ClipOval(child: Image.network(user['avatar_url'], fit: BoxFit.cover))
                          : const Icon(Icons.person_rounded, color: Colors.white, size: 52),
                    )
                  : CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                      backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                      child: user['avatar_url'] == null
                          ? const Icon(Icons.person, color: AppTheme.neonPurple, size: 48)
                          : null,
                    ),
              // PRO badge
              if (hasProAvatar)
                Positioned(
                  bottom: 2, right: hasGoldenFrame ? 6 : 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cardBg, width: 1.5),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isEmpty
                    ? user['username'] ?? ''
                    : '${user['first_name']} ${user['last_name']}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (hasGoldenFrame) ...[
                const SizedBox(width: 6),
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 20),
              ],
            ],
          ),
          Text(
            '@${user['username'] ?? ''}',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
          if ((user['organization'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apartment_outlined, size: 14, color: Colors.white30),
                const SizedBox(width: 4),
                Text(user['organization'], style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ],
          if ((user['current_status'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 14, color: Colors.white30),
                const SizedBox(width: 4),
                Text(user['current_status'], style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ],
          if ((user['interested_field'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 14, color: Colors.white30),
                const SizedBox(width: 4),
                Text('Interested: ${user['interested_field']}',
                    style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Level ${user['level'] ?? 1}',
              style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> user) {
    return Row(
      children: [
        _statCard('${user['coins'] ?? 0}', 'Coins', Icons.monetization_on, AppTheme.goldAccent),
        const SizedBox(width: 12),
        _statCard('${user['lives'] ?? 0}/5', 'Lives', Icons.favorite, AppTheme.livesRed),
        const SizedBox(width: 12),
        _statCard('${user['exp'] ?? 0}', 'XP', Icons.stars, AppTheme.neonPurple),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Social Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          if ((user['linkedin_url'] ?? '').isNotEmpty)
            _linkRow(Icons.link, 'LinkedIn', user['linkedin_url']),
          if ((user['github_url'] ?? '').isNotEmpty)
            _linkRow(Icons.code, 'GitHub', user['github_url']),
        ],
      ),
    );
  }

  Widget _linkRow(IconData icon, String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.neonBlue),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(color: AppTheme.neonBlue, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreChart(List<dynamic> attempts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Score History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: attempts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_outlined, color: Colors.white24, size: 36),
                        const SizedBox(height: 8),
                        Text('No attempts yet',
                            style: TextStyle(color: Colors.white24, fontSize: 13)),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: AppTheme.divider, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: Colors.transparent),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: attempts.asMap().entries.map((e) =>
                              FlSpot(e.key.toDouble(),
                                  (e.value['score'] as num?)?.toDouble() ?? 0)).toList(),
                          isCurved: true,
                          color: AppTheme.neonPurple,
                          barWidth: 2.5,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.neonPurple.withValues(alpha: 0.08),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats(List<dynamic> catStats) {
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
          const Text('Category Averages', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          if (catStats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.pie_chart_outline, color: Colors.white24, size: 36),
                    const SizedBox(height: 8),
                    Text('No category data yet',
                        style: TextStyle(color: Colors.white24, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            ...catStats.map((stat) {
              final avg = (stat['avg_score'] as num?)?.toDouble() ?? 0;
              final max = 10.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(stat['category_name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        ),
                        Text('${avg.toStringAsFixed(1)}/10',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neonPurple)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (avg / max).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        avg >= 7 ? AppTheme.emeraldGreen : (avg >= 4 ? AppTheme.neonBlue : AppTheme.livesRed),
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCertificatesSection(List<dynamic> certs) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Certificates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                onPressed: _uploadCertificate,
                icon: const Icon(Icons.add, size: 16, color: AppTheme.neonPurple),
                label: const Text('Add', style: TextStyle(color: AppTheme.neonPurple, fontSize: 13)),
              ),
            ],
          ),
          if (certs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No certificates uploaded yet.', style: TextStyle(color: Colors.white30, fontSize: 13)),
            )
          else
            ...certs.map((cert) {
              final localPath = cert['local_path'] as String? ?? '';
              final isImage = cert['is_image'] == true;
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => _openCertificateFile(cert),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                        color: AppTheme.neonPurple, size: 22,
                      ),
                    ),
                    title: Text(cert['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text(_formatDate(cert['uploaded_at']),
                        style: const TextStyle(fontSize: 11, color: Colors.white30)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
                        onPressed: () => _openCertificateFile(cert),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 20),
                        onPressed: () => _deleteCertificate(cert['id']),
                      ),
                    ]),
                  ),
                  if (isImage && localPath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(localPath),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
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

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }
}
