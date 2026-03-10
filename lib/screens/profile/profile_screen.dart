/// profile_screen.dart — Écran Profil (placeholder)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

/// Écran Profil avec option de déconnexion.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _accent = Color(0xFFe94560);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👤', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              user != null
                  ? '${user.prenom} ${user.nom}'
                  : 'Profil',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user?.email != null) ...[
              const SizedBox(height: 6),
              Text(
                user!.email,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
