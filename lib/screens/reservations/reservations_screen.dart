// ═════════════════════════════════════════════════════════════════════════════
// reservations_screen.dart — Liste des réservations avec annulation
// ═════════════════════════════════════════════════════════════════════════════

/// reservations_screen.dart — Liste des réservations de l'utilisateur connecté
///
/// - Charge les réservations via ReservationService.getMesReservations()
/// - Affiche les cartes avec statut (à venir / en cours / terminé)
/// - Bouton annuler sur les réservations "à venir" uniquement
/// - Pull-to-refresh

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../models/reservation.dart';
import '../../providers/auth_provider.dart';
import '../../services/reservation_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late Future<List<Reservation>> _future;

  @override
  void initState() {
    super.initState();
    _future = ReservationService.getMesReservations();
  }

  void _refresh() => setState(() {
        _future = ReservationService.getMesReservations();
      });

  Future<void> _annuler(Reservation r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Annuler la réservation',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous annuler la réservation pour "${r.bien.nomBiens}" du ${_fmt(r.dateDebut)} au ${_fmt(r.dateFin)} ?',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler la réservation',
                style: TextStyle(color: Color(0xFFe94560))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await ReservationService.cancelReservation(
        idReservation: r.idReservation,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Réservation annulée.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFe94560),
        ),
      );
    }
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso);
      return DateFormat('d MMM yyyy', 'fr_FR').format(d);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Mes réservations',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Reservation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _accent));
          }
          if (snap.hasError) {
            return _buildError(
                snap.error.toString().replaceFirst('Exception: ', ''));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) return _buildEmpty();
          return RefreshIndicator(
            color: _accent,
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _ReservationCard(
                reservation: list[i],
                onTap: () => context.push('/bien/${list[i].bien.idBiens}'),
                onAnnuler: list[i].statut == StatutReservation.aVenir
                    ? () => _annuler(list[i])
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📅', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('Aucune réservation',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Vos futures réservations apparaîtront ici.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.search),
                label: const Text('Explorer les biens'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refresh,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent, foregroundColor: Colors.white),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}

// ── Carte réservation ──────────────────────────────────────────────────────

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  final VoidCallback? onAnnuler;

  const _ReservationCard({
    required this.reservation,
    required this.onTap,
    this.onAnnuler,
  });

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  @override
  Widget build(BuildContext context) {
    final r    = reservation;
    final fmt  = DateFormat('d MMM yyyy', 'fr_FR');
    final fmtM = NumberFormat.currency(
        locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    final debut = DateTime.tryParse(r.dateDebut) ?? DateTime.now();
    final fin   = DateTime.tryParse(r.dateFin)   ?? DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo + statut
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 140,
                    width: double.infinity,
                    child: r.bien.photo != null && r.bien.photo!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ApiConfig.photoUrl(r.bien.photo),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _fallbackPhoto(),
                          )
                        : _fallbackPhoto(),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatutBadge(statut: r.statut),
                ),
              ],
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.bien.nomBiens,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (r.bien.nomCommune != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: _accent),
                        const SizedBox(width: 4),
                        Text(r.bien.nomCommune!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoChip(Icons.calendar_today, fmt.format(debut)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 14, color: Colors.white38),
                      ),
                      _infoChip(Icons.calendar_today, fmt.format(fin)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${r.nbNuits} nuit${r.nbNuits > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                      Text(
                        fmtM.format(r.totalCost),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // Bouton annuler — visible uniquement pour "à venir"
                  if (onAnnuler != null) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onAnnuler,
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Annuler la réservation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: const BorderSide(color: Color(0xFFe94560)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackPhoto() => Container(
        color: const Color(0xFF0d1020),
        child:
            const Center(child: Text('🏠', style: TextStyle(fontSize: 48))),
      );

  Widget _infoChip(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

// ── Badge statut ───────────────────────────────────────────────────────────

class _StatutBadge extends StatelessWidget {
  final StatutReservation statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statut) {
      StatutReservation.aVenir  => ('À venir',  Colors.blue.shade400),
      StatutReservation.enCours => ('En cours', Colors.green.shade400),
      StatutReservation.termine => ('Terminé',  Colors.grey.shade500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}