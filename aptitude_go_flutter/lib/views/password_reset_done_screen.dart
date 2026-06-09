import 'package:flutter/material.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';
import 'password_reset_confirm_screen.dart';

class PasswordResetDoneScreen extends StatefulWidget {
  final String email;
  const PasswordResetDoneScreen({super.key, required this.email});

  @override
  State<PasswordResetDoneScreen> createState() => _PasswordResetDoneScreenState();
}

class _PasswordResetDoneScreenState extends State<PasswordResetDoneScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _generateCode();
  }

  void _generateCode() {
    final token = HiveDatabase.instance.getVerificationToken(widget.email);
    if (token != null && token.length >= 6) {
      _generatedCode = token.substring(0, 6).toUpperCase();
    } else {
      _generatedCode = 'RESET${DateTime.now().millisecondsSinceEpoch % 10000}'.toUpperCase();
    }
  }

  void _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _error = null; _isLoading = true; });

    final enteredCode = _codeController.text.trim().toUpperCase();
    if (enteredCode == _generatedCode) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordResetConfirmScreen(email: widget.email),
          ),
        );
      }
    } else {
      setState(() { _error = 'Invalid reset code. Please try again.'; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
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
                  const Icon(Icons.mark_email_read_outlined, size: 80, color: AppTheme.neonPurple),
                  const SizedBox(height: 16),
                  Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a password reset code to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Local App: Your reset code is',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.60), fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          _generatedCode ?? '',
                          style: const TextStyle(
                            color: AppTheme.neonPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
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
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter reset code',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Reset code required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
