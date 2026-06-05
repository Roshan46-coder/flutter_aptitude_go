import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'password_reset_request_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isAccountInactive = false;
  bool _isResending = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
      _isAccountInactive = false;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (result['success'] == true) {
        // Navigation is handled automatically by the MaterialApp home router observing ApiClient.isAuthenticated
      } else {
        final error = result['error'] as String? ?? 'Login failed';
        final inactive = error.toLowerCase().contains('inactive') ||
            error.toLowerCase().contains('verify');
        setState(() {
          _errorMessage = error;
          _isAccountInactive = inactive;
        });
      }
    }
  }

  void _resendEmail() async {
    final email = _usernameController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address above first.')),
      );
      return;
    }
    setState(() => _isResending = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.resendVerificationEmail(email);
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? result['message'] ?? 'Verification email sent!'
              : result['error'] ?? 'Failed to resend.'),
          backgroundColor: result['success'] == true ? Colors.green.shade700 : Colors.red.shade700,
        ),
      );
    }
  }

  void _showSettingsDialog() {
    final api = Provider.of<ApiClient>(context, listen: false);
    final urlController = TextEditingController(text: api.baseUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Backend Server Settings"),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: "API Base URL",
              hintText: "http://127.0.0.1:8000/api/",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                api.updateBaseUrl(urlController.text.trim());
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App branding logo
                  Icon(
                    Icons.offline_bolt_rounded,
                    size: 80,
                    color: AppTheme.neonPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aptitude GO",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Accelerate your career preparation",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.livesRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.livesRed, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          if (_isAccountInactive) ...[
                            const SizedBox(height: 10),
                            _isResending
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple),
                                  )
                                : TextButton.icon(
                                    onPressed: _resendEmail,
                                    icon: const Icon(Icons.email_outlined, size: 16, color: AppTheme.neonPurple),
                                    label: const Text(
                                      'Resend Verification Email',
                                      style: TextStyle(color: AppTheme.neonPurple, fontSize: 13),
                                    ),
                                  ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: "Username or Email",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? "Username required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: "Password",
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Password required" : null,
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: api.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: api.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Log In",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordResetRequestScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("New to Aptitude GO? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Get Started",
                          style: TextStyle(
                            color: AppTheme.neonPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
