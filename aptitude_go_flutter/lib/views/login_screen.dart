import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'otp_verification_screen.dart';
import 'password_reset_request_screen.dart';
import 'role_selection_screen.dart';
import '../widgets/logo_gesture_detector.dart';
import '../widgets/admin_login_dialog.dart';

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
    debugPrint("🔵 LOGIN BTN: pressed with username='${_usernameController.text.trim()}'");
    if (!_formKey.currentState!.validate()) {
      debugPrint("🔵 LOGIN BTN: form validation failed");
      return;
    }
    
    setState(() {
      _errorMessage = null;
      _isAccountInactive = false;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    debugPrint("🔵 LOGIN BTN: calling api.login()...");
    final result = await api.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    debugPrint("🔵 LOGIN BTN: api.login() returned success=${result['success']}, error=${result['error']}");

    if (mounted) {
      if (result['success'] == true) {
        debugPrint("🔵 LOGIN BTN: Login successful — navigating to HomeScreen");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        final error = result['error'] as String? ?? 'Login failed';
        final inactive = error.toLowerCase().contains('inactive') ||
            error.toLowerCase().contains('verify');
        debugPrint("🔵 LOGIN BTN: Login failed — error='$error', inactive=$inactive");
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
    final result = await api.sendOtp(email: email, purpose: 'verify');
    if (mounted) {
      setState(() => _isResending = false);
      if (result['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: email, purpose: 'verify'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to resend.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showSettingsDialog() {
    final api = Provider.of<ApiClient>(context, listen: false);
    final urlController = TextEditingController(text: api.baseUrl);
    final testEmailController = TextEditingController();
    bool isTesting = false;
    String? testResult;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Backend Server Settings"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("API Server", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: "API Base URL",
                        hintText: "http://127.0.0.1:8000/api/",
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("Test Email Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: testEmailController,
                      decoration: const InputDecoration(
                        labelText: "Send test OTP to",
                        hintText: "your@email.com",
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (testResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: testResult!.contains('sent') || testResult!.contains('Success')
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          testResult!,
                          style: TextStyle(
                            fontSize: 12,
                            color: testResult!.contains('sent') || testResult!.contains('Success')
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isTesting
                            ? null
                            : () async {
                                final email = testEmailController.text.trim();
                                if (email.isEmpty) {
                                  setDialogState(() => testResult = 'Enter an email address first');
                                  return;
                                }
                                setDialogState(() {
                                  isTesting = true;
                                  testResult = 'Sending...';
                                });
                                final result = await api.testEmail(email);
                                setDialogState(() {
                                  isTesting = false;
                                  if (result['success'] == true) {
                                    testResult =
                                        'Sent! OTP: ${result['otp_debug'] ?? 'N/A'}\nCheck $email inbox/spam.';
                                  } else {
                                    testResult = 'Failed: ${result['error'] ?? 'Unknown error'}';
                                  }
                                });
                              },
                        icon: isTesting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.email_outlined, size: 18),
                        label: Text(isTesting ? 'Sending...' : 'Send Test Email'),
                      ),
                    ),
                  ],
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
                  LogoGestureDetector(
                    onTrigger: () async {
                      final api = Provider.of<ApiClient>(context, listen: false);
                      final nav = Navigator.of(context);
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const AdminLoginDialog(),
                      );
                      if (api.isAuthenticated) {
                        nav.pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Icon(
                      Icons.offline_bolt_rounded,
                      size: 80,
                      color: AppTheme.neonPurple,
                    ),
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
                                    icon: const Icon(Icons.verified_outlined, size: 16, color: AppTheme.neonPurple),
                                    label: const Text(
                                      'Verify Email with OTP',
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
                    child: Text(
                      "Forgot Password?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.onSurface.withValues(alpha: 0.38),
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
