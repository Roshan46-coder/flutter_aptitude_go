import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _orgController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiClient>(context, listen: false);
    final user = api.currentUser;
    if (user != null) {
      _firstNameController.text = user['first_name'] ?? '';
      _lastNameController.text = user['last_name'] ?? '';
      _orgController.text = user['organization'] ?? '';
      _linkedinController.text = user['linkedin_url'] ?? '';
      _githubController.text = user['github_url'] ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _orgController.dispose();
    _linkedinController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _isLoading = true; });

    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.post('profile/edit/', data: {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'organization': _orgController.text.trim(),
        'linkedin_url': _linkedinController.text.trim(),
        'github_url': _githubController.text.trim(),
      });

      if (mounted) {
        if (response.data['success'] == true) {
          final updatedUser = response.data['user'];
          if (updatedUser is Map<String, dynamic>) {
            api.updateCurrentUser(updatedUser);
            HiveDatabase.instance.updateCurrentUser(updatedUser);
          } else {
            await api.checkAuthStatus();
          }
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() { _error = response.data['error'] ?? 'Update failed.'; _isLoading = false; });
        }
      }
    } catch (e) {
      setState(() { _error = 'Failed to update profile.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    final user = api.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (user != null)
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppTheme.neonPurple.withValues(alpha: 0.1),
                          backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                          child: user['avatar_url'] == null
                              ? const Icon(Icons.person, color: AppTheme.neonPurple, size: 48) : null,
                        ),
                        const SizedBox(height: 8),
                        Text('@${user['username'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.livesRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.livesRed), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(hintText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(hintText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _orgController,
                  decoration: const InputDecoration(
                    hintText: 'Organization',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _linkedinController,
                  decoration: const InputDecoration(
                    hintText: 'LinkedIn URL',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _githubController,
                  decoration: const InputDecoration(
                    hintText: 'GitHub URL',
                    prefixIcon: Icon(Icons.code),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
