/// favoris_screen.dart — Écran Favoris (placeholder)
import 'package:flutter/material.dart';

/// Écran Favoris — bientôt disponible.
class FavorisScreen extends StatelessWidget {
  const FavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('❤️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Favoris',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bientôt disponible',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
