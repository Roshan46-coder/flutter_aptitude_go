import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'verify' or 'reset'

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;
  bool _isLoading = false;
  bool _isVerified = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _debugOtp;

  int _countdown = 300; // 5 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSendOtp());
  }

  Future<void> _autoSendOtp() async {
    setState(() => _isSending = true);
    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.sendOtp(
      email: widget.email,
      purpose: widget.purpose,
    );
    if (mounted) {
      setState(() => _isSending = false);
      if (result['success'] == true) {
        final debugOtp = result['otp_debug'];
        if (debugOtp != null) {
          _debugOtp = debugOtp.toString();
          debugPrint('🔑 [OTP DEBUG] Initial OTP for ${widget.email}: $_debugOtp');
        }
      } else {
        _errorMessage = result['error'] ?? 'Failed to send OTP.';
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
        return;
      }
      setState(() => _countdown--);
    });
  }

  String get _otpCode =>
      _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otpCode.length == 6;

  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String get _formattedTime {
    final min = (_countdown ~/ 60).toString().padLeft(2, '0');
    final sec = (_countdown % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  bool get _isExpired => _countdown <= 0;

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.verifyOtp(
      email: widget.email,
      otp: _otpCode,
      purpose: widget.purpose,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        setState(() => _isVerified = true);
        _timer?.cancel();

          if (widget.purpose == 'verify') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Email verified successfully! You can now log in.'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(email: widget.email),
                ),
              );
            }
          }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Verification failed. Try again.';
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.sendOtp(
      email: widget.email,
      purpose: widget.purpose,
    );

    if (mounted) {
      setState(() => _isResending = false);

      if (result['success'] == true) {
        _countdown = 300;
        _startCountdown();
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();

        final debugOtp = result['otp_debug'];
        if (debugOtp != null) {
          _debugOtp = debugOtp.toString();
          debugPrint("🔑 [OTP DEBUG] OTP for ${widget.email}: $_debugOtp");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'OTP resent successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to resend OTP';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == 'verify' ? 'Verify Email' : 'Reset Password'),
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
                  Icon(
                    _isVerified ? Icons.verified_rounded : Icons.email_outlined,
                    size: 80,
                    color: _isVerified ? AppTheme.emeraldGreen : AppTheme.neonPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVerified
                        ? 'Verified!'
                        : (widget.purpose == 'verify'
                            ? 'Verify your email'
                            : 'Verify your identity'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isVerified
                        ? 'Your email has been verified successfully.'
                        : 'Enter the 6-digit code sent to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  if (_isSending) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: Column(
                        children: [
                          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple)),
                          SizedBox(height: 8),
                          Text('Sending OTP to your email...', style: TextStyle(fontSize: 13, color: AppTheme.neonPurple)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.livesRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.livesRed, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],



                  // OTP Input Boxes
                  if (!_isVerified)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 50,
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.neonPurple, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (value) => _onOtpDigitChanged(index, value),
                            validator: (value) {
                              if (value == null || value.isEmpty) return '';
                              return null;
                            },
                          ),
                        );
                      }),
                    ),

                  if (!_isVerified) ...[
                    const SizedBox(height: 24),

                    // Countdown Timer
                    Center(
                      child: Text(
                        _isExpired ? 'OTP expired' : 'Code expires in $_formattedTime',
                        style: TextStyle(
                          color: _isExpired ? AppTheme.livesRed : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    ElevatedButton(
                      onPressed: (_isLoading || !_isOtpComplete) ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    // Resend
                    Center(
                      child: _isResending
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple))
                          : TextButton(
                              onPressed: _isExpired ? _resendOtp : null,
                              child: Text(
                                _isExpired ? 'Resend OTP' : 'Resend OTP (wait until expired)',
                                style: TextStyle(
                                  color: _isExpired ? AppTheme.neonPurple : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],

                  // After verification - show success and navigate button
                  if (_isVerified) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Go to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
