<?php

/**
 * auth_logout.php — Endpoint de déconnexion mobile (JWT stateless)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/api/mobile/auth_logout.php
 *
 * Méthode  : POST
 * Header   : Authorization: Bearer <token>
 * Réponse  : { "success": true }
 *
 * Note JWT : les tokens JWT sont stateless — la vraie déconnexion est gérée
 * côté client (suppression du token dans shared_preferences).
 * Ce fichier ajoute optionnellement le token dans une table de blacklist
 * pour invalider les tokens avant leur expiration naturelle.
 */

// ── En-têtes CORS + JSON ───────────────────────────────────────────────────
require_once __DIR__ . '/../../config/cors.php'; // NOSONAR - API procédurale sans autoloader
hapApplyCors(['POST', 'OPTIONS']);

// ── Chargement des dépendances ─────────────────────────────────────────────
require_once __DIR__ . '/../../config/db.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../config/jwt_config.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../classes/JWTHelper.php'; // NOSONAR - API procédurale sans autoloader

// ── Extraction et vérification du token ───────────────────────────────────
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (empty($authHeader) && function_exists('apache_request_headers')) {
    $headers    = apache_request_headers();
    $authHeader = $headers['Authorization'] ?? '';
}

if (!empty($authHeader) && preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
    $token   = $matches[1];
    $payload = \JWTHelper::decode($token, JWT_SECRET);

    if ($payload !== false) {
        // ── Ajout du token dans la blacklist ──────────────────────────────
        try {
            $pdo = new PDO(
                'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8',
                DB_USER,
                DB_PASS,
                [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
            );

            // Crée la table si elle n'existe pas encore
            $pdo->exec(
                'CREATE TABLE IF NOT EXISTS jwt_blacklist (
                    id         INT AUTO_INCREMENT PRIMARY KEY,
                    token_hash VARCHAR(64)  NOT NULL UNIQUE,
                    expires_at DATETIME     NOT NULL,
                    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_token_hash (token_hash),
                    INDEX idx_expires_at (expires_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
            );

            // Stocke le hash SHA-256 du token (pas le token brut pour limiter la taille)
            $tokenHash = hash('sha256', $token);
            $expiresAt = date('Y-m-d H:i:s', $payload['exp'] ?? time());

            $stmt = $pdo->prepare(
                'INSERT IGNORE INTO jwt_blacklist (token_hash, expires_at) VALUES (:hash, :exp)'
            );
            $stmt->execute([':hash' => $tokenHash, ':exp' => $expiresAt]);

            // Nettoyage des tokens expirés (maintenance légère)
            $pdo->exec('DELETE FROM jwt_blacklist WHERE expires_at < NOW()');

        } catch (PDOException $e) {
            // On continue même si la blacklist échoue — le client supprimera quand même son token
        }
    }
}

// ── Réponse ────────────────────────────────────────────────────────────────
// Le logout côté JWT est toujours considéré comme réussi :
// Flutter supprimera le token de shared_preferences.
echo json_encode(['success' => true, 'message' => 'Déconnexion effectuée.']);
