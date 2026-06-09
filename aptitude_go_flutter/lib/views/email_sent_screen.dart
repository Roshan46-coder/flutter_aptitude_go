import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class EmailSentScreen extends StatefulWidget {
  final String email;

  const EmailSentScreen({super.key, required this.email});

  @override
  State<EmailSentScreen> createState() => _EmailSentScreenState();
}

class _EmailSentScreenState extends State<EmailSentScreen> {
  bool _isVerifying = false;
  bool _isVerified = false;

  Future<void> _verifyNow() async {
    setState(() => _isVerifying = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.verifyEmailLocally(widget.email);
    if (mounted) {
      setState(() {
        _isVerifying = false;
        _isVerified = result['success'] == true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  _isVerified ? Icons.verified_rounded : Icons.mark_email_read_outlined,
                  size: 90,
                  color: _isVerified ? AppTheme.emeraldGreen : AppTheme.neonPurple,
                ),
                const SizedBox(height: 28),
                Text(
                  _isVerified ? "Email Verified!" : "Verify your email",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  _isVerified
                      ? "Your account is now active. You can log in."
                      : "We have sent a verification link to ${widget.email}. Please verify to activate your account.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
                if (!_isVerified)
                  Text(
                    "Since this is a local app, tap \"Verify Now\" to activate your account.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                  ),
                const SizedBox(height: 48),
                if (!_isVerified)
                  ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emeraldGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Verify Now",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                if (!_isVerified) const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isVerified ? AppTheme.emeraldGreen : AppTheme.neonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isVerified ? "Log In" : "Return to Login",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
