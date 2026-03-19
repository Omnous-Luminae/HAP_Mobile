/// favoris_screen.dart — Écran Favoris HAP Mobile
///
/// - Charge les favoris via FavorisService.getFavoris()
/// - Affiche les biens en grille 2 colonnes
/// - Bouton cœur pour retirer un favori avec feedback immédiat
/// - Clic sur une carte → BienDetailScreen
/// - Pull-to-refresh, état vide, gestion erreur

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/favoris_service.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  List<Map<String, dynamic>> _favoris = [];
  bool _loading = true;
  String? _error;

  // IDs en cours de suppression (pour désactiver le bouton pendant l'appel)
  final Set<int> _removing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        setState(() { _error = 'Connectez-vous pour voir vos favoris.'; _loading = false; });
        return;
      }
      final data = await FavorisService.getFavoris(token: token);
      setState(() { _favoris = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _retirer(int idBiens) async {
    setState(() => _removing.add(idBiens));
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      await FavorisService.retirerFavori(idBiens: idBiens, token: token);
      setState(() => _favoris.removeWhere((f) => f['id_biens'] == idBiens));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retiré des favoris.'),
          backgroundColor: Color(0xFF16213e),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFe94560),
        ),
      );
    } finally {
      if (mounted) setState(() => _removing.remove(idBiens));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Mes favoris',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFe94560)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe94560),
                    foregroundColor: Colors.white),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_favoris.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              const Text('Aucun favori',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Appuyez sur le cœur d\'un bien pour l\'ajouter ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.search),
                label: const Text('Explorer les biens'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
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
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFFe94560),
      backgroundColor: const Color(0xFF16213e),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _favoris.length,
        itemBuilder: (_, i) {
          final f = _favoris[i];
          final id = f['id_biens'] as int;
          return _FavoriCard(
            favori: f,
            isRemoving: _removing.contains(id),
            onTap: () => context.push('/bien/$id'),
            onRetirer: () => _retirer(id),
          );
        },
      ),
    );
  }
}

// ── Carte favori ───────────────────────────────────────────────────────────

class _FavoriCard extends StatelessWidget {
  final Map<String, dynamic> favori;
  final bool isRemoving;
  final VoidCallback onTap;
  final VoidCallback onRetirer;

  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  const _FavoriCard({
    required this.favori,
    required this.isRemoving,
    required this.onTap,
    required this.onRetirer,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl   = ApiConfig.photoUrl(favori['photo'] as String?);
    final note       = (favori['note_moyenne'] as num?)?.toDouble();
    final nbAvis     = favori['nb_avis'] as int? ?? 0;
    final tarif      = (favori['tarif_semaine'] as num?)?.toDouble() ?? 0.0;
    final nomBiens   = favori['nom_biens'] as String? ?? '';
    final commune    = favori['nom_commune'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo + bouton retirer
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                // Bouton cœur
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: isRemoving ? null : onRetirer,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        shape: BoxShape.circle,
                      ),
                      child: isRemoving
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.favorite,
                              color: Color(0xFFe94560), size: 16),
                    ),
                  ),
                ),
              ],
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomBiens,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (commune != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 $commune',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 4),
                  if (note != null)
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: note,
                          itemBuilder: (_, __) => const Icon(
                              Icons.star, color: Color(0xFFFFD700)),
                          itemCount: 5,
                          itemSize: 11,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '($nbAvis)',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '${tarif.toStringAsFixed(0)} € / sem.',
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF0f3460),
        child:
            const Center(child: Text('🏠', style: TextStyle(fontSize: 32))),
      );
}