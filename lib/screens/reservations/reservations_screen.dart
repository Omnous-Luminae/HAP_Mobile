/// reservations_screen.dart — Écran Réservations (placeholder)
import 'package:flutter/material.dart';

/// Écran Réservations — bientôt disponible.
class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📅', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Réservations',
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
