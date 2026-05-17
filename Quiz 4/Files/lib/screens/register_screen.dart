import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _success = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _googleRegister() async {
    setState(() => _googleLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      if (mounted) {
        setState(() => _success = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully!')));
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: _success
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 58),
                const SizedBox(height: 10),
                const Text('Check your email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'We sent a confirmation link to your email address.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9DA4B8)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: widget.onBackToLogin, child: const Text('Back to Login')),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 36, color: Color(0xFF9AA6FF)),
                  const SizedBox(height: 10),
                  const Text('Create account', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Sign up to securely access your portal.', style: TextStyle(color: Color(0xFF9DA4B8))),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_loading || _googleLoading) ? null : _googleRegister,
                      icon: _googleLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'G',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0x22FFFFFF))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or sign up with email', style: TextStyle(color: Color(0xFF9DA4B8), fontSize: 12)),
                      ),
                      Expanded(child: Divider(color: Color(0x22FFFFFF))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email Address', hintText: 'name@university.edu'),
                    validator: (v) {
                      final t = (v ?? '').trim();
                      if (t.isEmpty) return 'Please enter a valid email address.';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(t)) return 'Please enter a valid email address.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', hintText: 'At least 6 characters'),
                    validator: (v) => (v ?? '').trim().length < 6 ? 'Password must be at least 6 characters.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    validator: (v) => (v ?? '').trim() != _password.text.trim() ? 'Passwords do not match.' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _register,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: widget.onBackToLogin, child: const Text('Sign in')),
                ],
              ),
            ),
    );
  }
}
