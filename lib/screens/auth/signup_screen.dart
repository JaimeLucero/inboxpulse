import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  const SignupScreen({super.key, required this.onNavigateToLogin});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await credential.user!.updateDisplayName(_nameController.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': _emailController.text.trim(),
        'displayName': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          return Row(
            children: [
              if (isWide) const Expanded(child: _SignupBrandPanel()),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: DotGridPainter())),
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!isWide) ...[
                                const IpWordmark(),
                                const SizedBox(height: 32),
                              ],
                              Text(
                                'Create your account',
                                style: GoogleFonts.figtree(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Start receiving Stripe reports in minutes',
                                style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 28),
                              if (_error != null) ...[
                                _ErrorBanner(message: _error!),
                                const SizedBox(height: 16),
                              ],
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _IpTextField(
                                      controller: _nameController,
                                      label: 'Full name',
                                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _IpTextField(
                                      controller: _emailController,
                                      label: 'Email address',
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _IpTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      obscureText: _obscurePassword,
                                      validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          size: 18,
                                          color: AppColors.textMuted,
                                        ),
                                        onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: _loading ? null : _signUp,
                                        child: _loading
                                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                            : const Text('Create account'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                  GestureDetector(
                                    onTap: widget.onNavigateToLogin,
                                    child: Text(
                                      'Sign in',
                                      style: GoogleFonts.figtree(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.accent,
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignupBrandPanel extends StatelessWidget {
  const _SignupBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071A12), Color(0xFF0B0B0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const IpWordmark(),
            const Spacer(),
            Text(
              'Your revenue,\nin your inbox.',
              style: GoogleFonts.figtree(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1.0,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Join founders and freelancers who get their Stripe metrics delivered automatically — no manual pulling of reports.',
              style: GoogleFonts.figtree(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 40),
            _SetupStep(step: '1', text: 'Create your account'),
            const SizedBox(height: 12),
            _SetupStep(step: '2', text: 'Connect your Stripe account'),
            const SizedBox(height: 12),
            _SetupStep(step: '3', text: 'Choose your metrics & schedule'),
            const Spacer(),
            Text('© 2025 InboxPulse', style: GoogleFonts.figtree(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String step;
  final String text;
  const _SetupStep({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.accentDim,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.accentMid),
          ),
          child: Center(
            child: Text(
              step,
              style: GoogleFonts.figtree(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(text, style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _IpTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _IpTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.figtree(fontSize: 14, color: AppColors.textPrimary),
      validator: validator,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: GoogleFonts.figtree(fontSize: 13, color: AppColors.error))),
        ],
      ),
    );
  }
}
