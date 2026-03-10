/// register_screen.dart — Écran d'inscription HAP Mobile
///
/// Permet à un nouveau locataire de créer un compte.
/// Inclut un champ d'autocomplete pour la commune (via search_communes.php).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _nomCtrl             = TextEditingController();
  final _prenomCtrl          = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _telephoneCtrl       = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _rueCtrl             = TextEditingController();
  final _communeCtrl         = TextEditingController();

  bool   _obscurePassword        = true;
  bool   _obscureConfirmPassword = true;
  DateTime? _selectedDate;
  int?   _selectedCommuneId;
  List<Map<String, dynamic>> _communes = [];

  // ── Couleurs du thème HAP ────────────────────────────────────────────────
  static const Color _bg      = Color(0xFF1a1a2e);
  static const Color _surface = Color(0xFF16213e);
  static const Color _accent  = Color(0xFFe94560);

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telephoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _rueCtrl.dispose();
    _communeCtrl.dispose();
    super.dispose();
  }

  // ── Recherche de communes ─────────────────────────────────────────────────

  /// Interroge l'API search_communes.php et met à jour la liste [_communes].
  Future<void> _searchCommunes(String query) async {
    if (query.length < 2) {
      setState(() => _communes = []);
      return;
    }
    try {
      final data = await ApiService.get(
        ApiConfig.communes,
        params: {'q': query},
      ) as List<dynamic>;
      setState(() {
        _communes = data.cast<Map<String, dynamic>>();
      });
    } catch (_) {
      setState(() => _communes = []);
    }
  }

  // ── Sélection de la date de naissance ─────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accent,
              onPrimary: Colors.white,
              surface: _surface,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Soumission du formulaire ───────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les mots de passe ne correspondent pas.'),
          backgroundColor: _accent,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.register({
      'nom':            _nomCtrl.text.trim(),
      'prenom':         _prenomCtrl.text.trim(),
      'email':          _emailCtrl.text.trim(),
      'password':       _passwordCtrl.text,
      'telephone':      _telephoneCtrl.text.trim(),
      'date_naissance': _selectedDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
          : '',
      'rue':        _rueCtrl.text.trim(),
      'id_commune': _selectedCommuneId ?? 0,
    });

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? "Erreur lors de l'inscription."),
          backgroundColor: _accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
        title: const Text(
          'Créer un compte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Nom & Prénom ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Nom',
                        controller: _nomCtrl,
                        hint: 'Dupont',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        label: 'Prénom',
                        controller: _prenomCtrl,
                        hint: 'Jean',
                        icon: Icons.badge_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Email ─────────────────────────────────────────────────────
                _buildField(
                  label: 'Email',
                  controller: _emailCtrl,
                  hint: 'jean.dupont@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Téléphone ─────────────────────────────────────────────────
                _buildField(
                  label: 'Téléphone',
                  controller: _telephoneCtrl,
                  hint: '06 12 34 56 78',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // ── Date de naissance ─────────────────────────────────────────
                _buildLabel('Date de naissance'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            color: Colors.white38, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.white24,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Rue ───────────────────────────────────────────────────────
                _buildField(
                  label: 'Rue',
                  controller: _rueCtrl,
                  hint: '12 rue de la Paix',
                  icon: Icons.home_outlined,
                ),
                const SizedBox(height: 16),

                // ── Commune (autocomplete) ─────────────────────────────────────
                _buildLabel('Commune'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _communeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    'Rechercher une commune…',
                    const Icon(Icons.location_city_outlined,
                        color: Colors.white38),
                  ),
                  onChanged: _searchCommunes,
                ),
                if (_communes.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accent.withAlpha(76)),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _communes.length > 5 ? 5 : _communes.length,
                      itemBuilder: (context, index) {
                        final c = _communes[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${c['nom_commune']} (${c['cp_commune']})',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                          onTap: () {
                            setState(() {
                              _communeCtrl.text =
                                  '${c['nom_commune']} (${c['cp_commune']})';
                              _selectedCommuneId = c['id_commune'] as int?;
                              _communes = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Mot de passe ──────────────────────────────────────────────
                _buildPasswordField(
                  label: 'Mot de passe',
                  controller: _passwordCtrl,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirmer le mot de passe ──────────────────────────────────
                _buildPasswordField(
                  label: 'Confirmer le mot de passe',
                  controller: _confirmPasswordCtrl,
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // ── Bouton S'inscrire ─────────────────────────────────────────
                ElevatedButton(
                  onPressed: auth.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "S'inscrire",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Lien connexion ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ? ',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            hint,
            Icon(icon, color: Colors.white38),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            '••••••••',
            const Icon(Icons.lock_outline, color: Colors.white38),
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, Icon prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: _surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: _accent),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
