import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool isCompany;
  final String? currentStatus;
  final String? interestedField;
  final String? hiringFocus;

  const RegisterScreen({
    super.key,
    required this.isCompany,
    this.currentStatus,
    this.interestedField,
    this.hiringFocus,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _orgController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    final result = await api.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      isCompany: widget.isCompany,
      currentStatus: widget.currentStatus,
      interestedField: widget.interestedField,
      hiringFocus: widget.hiringFocus,
      organization: _orgController.text.trim(),
    );

    if (mounted) {
      if (result['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: _emailController.text.trim(),
              purpose: 'verify',
            ),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiClient>(context);
    final accentColor = widget.isCompany ? AppTheme.neonBlue : AppTheme.neonPurple;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Create your account",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isCompany
                        ? "Join as a company and discover top talent"
                        : "Join as a candidate and sharpen your skills",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 30),

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

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(hintText: "First Name"),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(hintText: "Last Name"),
                          validator: (val) =>
                              val == null || val.trim().isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: "Username",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? "Username required" : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Email required";
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return "Invalid email address";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _orgController,
                    decoration: InputDecoration(
                      hintText: widget.isCompany ? "Company Name" : "College / University",
                      prefixIcon: const Icon(Icons.apartment_outlined),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? "This field is required" : null,
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
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Password required";
                      if (val.length < 8) return "Password must be at least 8 characters";
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: api.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
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
                            "Register",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
