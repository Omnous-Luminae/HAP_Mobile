/// search_bar_widget.dart — Barre de recherche HAP Mobile
///
/// Champ de texte avec :
///   - Icône loupe
///   - Bouton filtres avec badge rouge si filtres actifs
///   - Debounce 500 ms pour limiter les appels API
///   - Style HAP (fond sombre, border radius 12)

import 'dart:async';

import 'package:flutter/material.dart';

/// Barre de recherche avec debounce et indicateur de filtres actifs.
class SearchBarWidget extends StatefulWidget {
  /// Valeur initiale du champ texte.
  final String initialValue;

  /// Nombre de filtres actifs (affiche un badge rouge si > 0).
  final int activeFiltersCount;

  /// Appelé après le debounce avec le texte saisi.
  final ValueChanged<String> onSearch;

  /// Appelé lors du tap sur le bouton filtres.
  final VoidCallback onFilterTap;

  const SearchBarWidget({
    super.key,
    this.initialValue = '',
    this.activeFiltersCount = 0,
    required this.onSearch,
    required this.onFilterTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  // ── Couleurs ──────────────────────────────────────────────────────────────
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
    // Update clear button visibility as user types
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value.trim());
    });
  }

  void _clearSearch() {
    _ctrl.clear();
    _debounce?.cancel();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ── Champ de recherche ─────────────────────────────────────────
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: _onTextChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un bien…',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 20,
                  ),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white38, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Bouton filtres ─────────────────────────────────────────────
          GestureDetector(
            onTap: widget.onFilterTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.activeFiltersCount > 0 ? _accent : _surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune,
                    color: widget.activeFiltersCount > 0
                        ? Colors.white
                        : Colors.white70,
                    size: 22,
                  ),
                ),

                // Badge rouge avec le nombre de filtres actifs
                if (widget.activeFiltersCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.activeFiltersCount}',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
