import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onLogout});

  final VoidCallback onLogout;

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out successfully')));
      onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser!;
    final name = user.userMetadata?['full_name']?.toString() ?? user.email?.split('@').first ?? 'User';

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x226E7BFF),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x66101524),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome, $name',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: () => _signOut(context), icon: const Icon(Icons.logout)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x66101524),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x26FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Email: ${user.email ?? 'N/A'}'),
                      const SizedBox(height: 8),
                      Text('User ID: ${user.id}'),
                      const SizedBox(height: 8),
                      Text('Created At: ${user.createdAt}'),
                      const SizedBox(height: 8),
                      Text('Email Confirmed: ${user.emailConfirmedAt != null ? 'Yes' : 'No'}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
