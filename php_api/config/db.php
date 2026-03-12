<?php
/**
 * db.php - Configuration de connexion MySQL pour l'API mobile.
 *
 * Priorite des valeurs:
 * 1) Variables d'environnement
 * 2) Valeurs par defaut locales (XAMPP)
 */

if (!defined('DB_HOST')) {
    define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
}

if (!defined('DB_NAME')) {
    define('DB_NAME', getenv('DB_NAME') ?: 'project_hap');
}

if (!defined('DB_USER')) {
    define('DB_USER', getenv('DB_USER') ?: 'root');
}

if (!defined('DB_PASS')) {
    define('DB_PASS', getenv('DB_PASS') !== false ? getenv('DB_PASS') : '');
}
