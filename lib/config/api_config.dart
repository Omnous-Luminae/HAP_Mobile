/// api_config.dart — URLs des endpoints PHP de l'API HAP Mobile
///
/// Modifiez [baseUrl] selon l'environnement :
///   - Émulateur Android : 10.0.2.2 pointe vers localhost de la machine hôte
///   - Simulateur iOS    : localhost
///   - Production        : votre domaine réel

class ApiConfig {
  // ── URL de base ────────────────────────────────────────────────────────────
  /// Émulateur Android (10.0.2.2 = localhost de la machine hôte)
  static const String baseUrl = 'http://10.0.2.2:8080';

  // static const String baseUrl = 'http://localhost:8080'; // Simulateur iOS
  // static const String baseUrl = 'https://ton-domaine.fr'; // Production

  /// Préfixe commun au projet PHP
  static const String _projectPath =
      '$baseUrl/Projet_HAP(House_After_Party)';

  // ── Auth mobile ────────────────────────────────────────────────────────────
  static const String login    = '$_projectPath/api/mobile/auth_login.php';
  static const String register = '$_projectPath/api/mobile/auth_register.php';
  static const String me       = '$_projectPath/api/mobile/auth_me.php';
  static const String logout   = '$_projectPath/api/mobile/auth_logout.php';

  // ── Ressources ─────────────────────────────────────────────────────────────
  static const String biens        = '$_projectPath/api/mobile/get_biens_mobile.php';
  static const String communes     = '$_projectPath/api/search_communes.php';
  static const String favoris      = '$_projectPath/api/favoris.php';
  static const String reservations = '$_projectPath/api/get_reservations.php';
  static const String calcCost     = '$_projectPath/api/calculate_reservation_cost.php';

  // ── API publique française (autocomplete adresses) ─────────────────────────
  /// Pas de clé API nécessaire — usage libre.
  static const String adresseGouv = 'https://api-adresse.data.gouv.fr/search/';
}
