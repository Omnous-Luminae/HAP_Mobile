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

function getPDO(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8',
                DB_USER,
                DB_PASS,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'message' => 'Erreur de connexion à la base de données.',
                'error' => $e->getMessage()
            ]);
            exit;
        }
    }
    return $pdo;
}

/**
 * Mise a niveau schema: garantit une longueur suffisante pour les hashes.
 *
 * @param PDO $pdo Connexion PDO active.
 */
function hapEnsureAuthSchema(PDO $pdo): void
{
    static $alreadyChecked = false;
    if ($alreadyChecked) {
        return;
    }

    try {
        $rows = $pdo->query('DESCRIBE Locataire')->fetchAll(PDO::FETCH_ASSOC);
        foreach ($rows as $row) {
            if (($row['Field'] ?? '') === 'password_locataire') {
                $type = strtolower((string) ($row['Type'] ?? ''));
                if ($type === 'varchar(20)') {
                    $pdo->exec('ALTER TABLE Locataire MODIFY password_locataire VARCHAR(255) NOT NULL');
                }
                break;
            }
        }
    } catch (Throwable $e) {
        // Ne bloque pas l'API si la migration schema echoue.
    }

    $alreadyChecked = true;
}
