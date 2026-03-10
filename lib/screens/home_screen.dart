/// home_screen.dart — Écran d'accueil HAP Mobile (après connexion)
///
/// Affiche un message de bienvenue et permet la déconnexion.
/// À compléter avec la liste des biens disponibles à la location.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color _bg     = Color(0xFF1a1a2e);
  static const Color _accent = Color(0xFFe94560);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        elevation: 0,
        title: const Text(
          'HAP Mobile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // ── Bouton de déconnexion ──────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Message de bienvenue ───────────────────────────────────────
              Text(
                'Bienvenue, ${user?.prenom ?? 'Invité'} !',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Découvrez nos biens festifs disponibles à la location.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // ── Placeholder liste de biens ────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _accent.withAlpha(51),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.house_outlined,
                          color: _accent,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'La liste des biens arrive bientôt…',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
