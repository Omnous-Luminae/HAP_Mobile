/// profile_screen.dart — Écran Profil complet HAP Mobile
///
/// 3 onglets via TabBar :
///   0 → Infos personnelles (lecture seule, édition nécessite endpoint PHP)
///   1 → Historique réservations (appel get_mes_reservations.php)
///   2 → Paramètres (déconnexion)

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── Couleurs HAP ──────────────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(user: user),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: _accent,
                labelColor: _accent,
                unselectedLabelColor: Colors.white38,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Infos'),
                  Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Réservations'),
                  Tab(icon: Icon(Icons.settings_outlined, size: 18), text: 'Paramètres'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _InfosTab(user: user),
            _ReservationsTab(),
            _ParametresTab(),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EN-TÊTE PROFIL
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final initiales = user != null
        ? '${(user.prenom as String).isNotEmpty ? user.prenom[0] : ''}${(user.nom as String).isNotEmpty ? user.nom[0] : ''}'.toUpperCase()
        : '?';

    return Container(
      color: _surface,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        children: [
          // Avatar initiales
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accent.withAlpha(40),
              border: Border.all(color: _accent, width: 2),
            ),
            child: Center(
              child: Text(
                initiales,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nom complet
          Text(
            user != null ? '${user.prenom} ${user.nom}' : 'Invité',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          if (user?.email != null)
            Text(
              user!.email as String,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),

          // Commune
          if (user?.nomCommune != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📍 ', style: TextStyle(fontSize: 12)),
                Text(
                  '${user!.cpCommune ?? ''} ${user.nomCommune}'.trim(),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET 1 — INFOS PERSONNELLES
// ══════════════════════════════════════════════════════════════════════════════

class _InfosTab extends StatelessWidget {
  final dynamic user;
  static const Color _surface = Color(0xFF16213e);

  const _InfosTab({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
        child: Text(
          'Connectez-vous pour voir vos informations.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: 'Identité'),
        _InfoRow(icon: Icons.person_outline,    label: 'Prénom',     value: user.prenom as String),
        _InfoRow(icon: Icons.person_outline,    label: 'Nom',        value: user.nom as String),
        _InfoRow(icon: Icons.email_outlined,    label: 'Email',      value: user.email as String),
        if (user.telephone != null)
          _InfoRow(icon: Icons.phone_outlined,  label: 'Téléphone',  value: user.telephone as String),
        if (user.dateNaissance != null)
          _InfoRow(icon: Icons.cake_outlined,   label: 'Naissance',  value: _formatDate(user.dateNaissance as String)),

        const SizedBox(height: 16),
        _SectionTitle(title: 'Adresse'),
        if (user.rue != null)
          _InfoRow(icon: Icons.home_outlined,   label: 'Rue',        value: user.rue as String),
        if (user.complement != null)
          _InfoRow(icon: Icons.add_location_alt_outlined, label: 'Complément', value: user.complement as String),
        if (user.nomCommune != null)
          _InfoRow(icon: Icons.location_city_outlined, label: 'Commune',
            value: '${user.cpCommune ?? ''} ${user.nomCommune}'.trim()),

        const SizedBox(height: 24),

        // Bandeau info modification
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0f3460),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white38, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'La modification du profil sera disponible prochainement.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return iso;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFe94560),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _surface = Color(0xFF16213e);

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET 2 — HISTORIQUE RÉSERVATIONS
// ══════════════════════════════════════════════════════════════════════════════

class _ReservationsTab extends StatefulWidget {
  @override
  State<_ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends State<_ReservationsTab>
    with AutomaticKeepAliveClientMixin {
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        setState(() { _error = 'Non connecté.'; _loading = false; });
        return;
      }
      final response = await http.get(
        Uri.parse(ApiConfig.mesReservations),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _reservations = List<Map<String, dynamic>>.from(data['data']);
            _loading = false;
          });
          return;
        }
      }
      setState(() { _error = 'Impossible de charger les réservations.'; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Erreur réseau.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFe94560)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadReservations,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏖️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('Aucune réservation pour l\'instant.',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Explorez les biens disponibles !',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: _accent,
      backgroundColor: _surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          return _ReservationCard(reservation: _reservations[index]);
        },
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> reservation;

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  const _ReservationCard({required this.reservation});

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_cours': return const Color(0xFF4CAF50);
      case 'a_venir':  return const Color(0xFF2196F3);
      case 'termine':  return Colors.white38;
      default:         return Colors.white38;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'en_cours': return 'En cours';
      case 'a_venir':  return 'À venir';
      case 'termine':  return 'Terminé';
      default:         return statut;
    }
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return iso;
  }

  @override
  Widget build(BuildContext context) {
    final bien    = reservation['bien'] as Map<String, dynamic>;
    final statut  = reservation['statut'] as String;
    final photo   = ApiConfig.photoUrl(bien['photo'] as String?);
    final couleur = _statutColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: couleur.withAlpha(80), width: 1),
      ),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: couleur.withAlpha(25),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  _statutLabel(statut),
                  style: TextStyle(
                    color: couleur,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '#${reservation['id_reservation']}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),

          // Corps : photo + infos
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photo,
                          width: 72, height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _photoPh(),
                        )
                      : _photoPh(),
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bien['nom_biens'] as String? ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bien['nom_commune'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '📍 ${bien['nom_commune']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Dates
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                            color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(reservation['date_debut'])} → ${_formatDate(reservation['date_fin'])}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Nuits + coût
                      Row(
                        children: [
                          const Icon(Icons.nights_stay_outlined,
                            color: Colors.white38, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${reservation['nb_nuits']} nuit${(reservation['nb_nuits'] as int) > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '${(reservation['total_cost'] as double).toStringAsFixed(0)} €',
                            style: const TextStyle(
                              color: Color(0xFFe94560),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _photoPh() {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(child: Text('🏠', style: TextStyle(fontSize: 28))),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ONGLET 3 — PARAMÈTRES
// ══════════════════════════════════════════════════════════════════════════════

class _ParametresTab extends StatelessWidget {
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),

        // Déconnexion
        _SettingsTile(
          icon: Icons.logout,
          label: 'Se déconnecter',
          color: _accent,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: _surface,
                title: const Text('Déconnexion',
                  style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Voulez-vous vraiment vous déconnecter ?',
                  style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Annuler',
                      style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Déconnecter',
                      style: TextStyle(color: Color(0xFFe94560))),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            }
          },
        ),

        const SizedBox(height: 24),

        // Infos app
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text('HAP Mobile', style: TextStyle(
                color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text('Version 1.0.0', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  static const Color _surface = Color(0xFF16213e);

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withAlpha(120), size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DELEGATE TabBar persistant
// ══════════════════════════════════════════════════════════════════════════════

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  static const Color _surface = Color(0xFF16213e);

  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}