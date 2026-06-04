import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email and password are required');
      return;
    }
    if (_isRegister && pass != _confirmCtrl.text.trim()) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isRegister) {
        await supabase.auth.signUp(email: email, password: pass);
        if (mounted) {
          setState(() => _error = 'Account created! Check your email to confirm.');
          _isRegister = false;
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await supabase.auth.signInWithOAuth(OAuthProvider.google);
    } catch (e) {
      if (mounted) setState(() => _error = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.face_retouching_natural, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 16),
              const Text('AI Attendance System',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.foreground)),
              const SizedBox(height: 6),
              const Text('Sign in to manage attendance with face recognition',
                  style: TextStyle(fontSize: 13, color: AppColors.mutedFg), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_isRegister ? 'Create account' : 'Welcome back',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(_isRegister ? 'Register a new admin account' : 'Sign in to your administrator account',
                        style: const TextStyle(fontSize: 13, color: AppColors.mutedFg)),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.absentBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.absent.withOpacity(0.3)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.absent, fontSize: 13)),
                      ),
                    // Google button
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 18, height: 18,
                        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20),
                      ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Divider()),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.mutedFg))),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    // Email
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'admin@school.edu',
                        prefixIcon: Icon(Icons.mail_outline, size: 18),
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, size: 18),
                        labelText: 'Password',
                      ),
                    ),
                    if (_isRegister) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, size: 18),
                          labelText: 'Confirm Password',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isRegister ? 'Create Account' : 'Sign In'),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: AppColors.mutedFg),
                            children: [
                              TextSpan(text: _isRegister ? "Already have an account? " : "Don't have an account? "),
                              TextSpan(
                                text: _isRegister ? 'Sign In' : 'Register',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Secured by Supabase Auth', style: TextStyle(fontSize: 11, color: AppColors.mutedFg)),
            ],
          ),
        ),
      ),
    );
  }
}
