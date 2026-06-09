import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class AdminLoginDialog extends StatefulWidget {
  const AdminLoginDialog({super.key});

  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog>
    with TickerProviderStateMixin {
  late AnimationController _fadeScaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();

    // Fade and Scale entry animation
    _fadeScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeScaleController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeScaleController, curve: Curves.easeOutBack),
    );

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _fadeScaleController.forward();
  }

  @override
  void dispose() {
    _fadeScaleController.dispose();
    _shakeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = "Password is required";
      });
      _triggerShake();
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    // Simulated short delay for high quality professional feel
    await Future.delayed(const Duration(milliseconds: 600));

    if (password == 'ammaachan46') {
      if (mounted) {
        final api = Provider.of<ApiClient>(context, listen: false);
        await api.loginAsAdmin();
        if (mounted) {
          // Close dialog first, navigation is triggered automatically because HomeScreen senses standard ApiClient state update
          Navigator.of(context).pop();
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = "Invalid Administrator Password";
          _isLoggingIn = false;
        });
        _triggerShake();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.black.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.offline_bolt_rounded,
                      size: 64,
                      color: AppTheme.neonPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Administrator Access",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Restricted System Area",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 28),

                  // Password field with Shake animation support
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      // Sine wave calculation for horizontal translation shake
                      final double val = _shakeAnimation.value;
                      final double translation =
                          16 * sin(val * 4 * pi) * (1.0 - val);
                      return Transform.translate(
                        offset: Offset(translation, 0),
                        child: child,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Enter Admin Password",
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.neonPurple,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppTheme.livesRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.12),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoggingIn ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
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
