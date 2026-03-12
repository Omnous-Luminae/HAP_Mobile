/// api_config.dart — URLs des endpoints PHP de l'API HAP Mobile
///
/// Par défaut, l'API pointe vers un serveur PHP local lancé sur le port 8080.
/// Vous pouvez surcharger la base URL à l'exécution avec :
///   flutter run --dart-define=API_BASE_URL=http://<host>:<port>

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ── URL de base ────────────────────────────────────────────────────────────
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Base URL calculée à l'exécution :
  /// - web local   -> localhost:8080
  /// - mobile/emul -> 10.0.2.2:8080
  /// - surcharge   -> --dart-define=API_BASE_URL=...
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }

  /// Préfixe commun de l'API dans ce dépôt.
  static String get _projectPath => '$baseUrl/php_api';

  // ── Auth mobile ────────────────────────────────────────────────────────────
  static String get login => '$_projectPath/api/mobile/auth_login.php';
  static String get register => '$_projectPath/api/mobile/auth_register.php';
  static String get me => '$_projectPath/api/mobile/auth_me.php';
  static String get logout => '$_projectPath/api/mobile/auth_logout.php';

  // ── Ressources ─────────────────────────────────────────────────────────────
  static String get biens => '$_projectPath/api/mobile/get_biens_mobile.php';
  static String get communes => '$_projectPath/api/search_communes.php';
  static String get favoris => '$_projectPath/api/favoris.php';
  static String get reservations => '$_projectPath/api/get_reservations.php';
  static String get calcCost => '$_projectPath/api/calculate_reservation_cost.php';

  // ── API publique française (autocomplete adresses) ─────────────────────────
  /// Pas de clé API nécessaire — usage libre.
  static const String adresseGouv = 'https://api-adresse.data.gouv.fr/search/';
}
