<?php

/**
 * auth_me.php — Endpoint de récupération du profil connecté (JWT)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/api/mobile/auth_me.php
 *
 * Méthode          : GET
 * Header requis    : Authorization: Bearer <token>
 * Réponse          : { "success": true, "user": { ... } }
 *                    ou { "success": false, "message": "Token invalide" }
 */

// ── En-têtes CORS + JSON ───────────────────────────────────────────────────
require_once __DIR__ . '/../../config/cors.php'; // NOSONAR - API procédurale sans autoloader
hapApplyCors(['GET', 'OPTIONS']);

// ── Chargement des dépendances ─────────────────────────────────────────────
require_once __DIR__ . '/../../config/db.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../config/jwt_config.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../classes/JWTHelper.php'; // NOSONAR - API procédurale sans autoloader
$pdo = getPDO();

// ── Extraction du token depuis le header Authorization ─────────────────────
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

// Support pour les serveurs Apache qui n'exposent pas HTTP_AUTHORIZATION
if (empty($authHeader) && function_exists('apache_request_headers')) {
    $headers    = apache_request_headers();
    $authHeader = $headers['Authorization'] ?? '';
}

if (empty($authHeader) || !preg_match('/^Bearer\s+(.+)$/i', $authHeader, $matches)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token manquant ou mal formé.']);
    exit;
}

$token = $matches[1];

// ── Vérification et décodage du JWT ───────────────────────────────────────
$payload = \JWTHelper::decode($token, JWT_SECRET);
if ($payload === false) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token invalide ou expiré.']);
    exit;
}

$idLocataire = (int) ($payload['id_locataire'] ?? 0);


// ── Récupération des infos complètes du locataire (avec commune) ───────────
$stmt = $pdo->prepare(
    'SELECT l.id_locataire,
            l.nom_locataire,
            l.prenom_locataire,
            l.email_locataire,
            l.telephone_locataire,
            l.date_naissance,
            l.rue_locataire,
            l.complement_locataire,
            l.id_commune,
            c.nom_commune,
            c.cp_commune
     FROM   Locataire l
     LEFT JOIN Commune c ON c.id_commune = l.id_commune
     WHERE  l.id_locataire = :id
     LIMIT  1'
);
$stmt->execute([':id' => $idLocataire]);
$locataire = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$locataire) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Compte introuvable.']);
    exit;
}

// ── Réponse ────────────────────────────────────────────────────────────────
echo json_encode([
    'success' => true,
    'user'    => [
        'id'           => (int) $locataire['id_locataire'],
        'nom'          => $locataire['nom_locataire'],
        'prenom'       => $locataire['prenom_locataire'],
        'email'        => $locataire['email_locataire'],
        'telephone'    => $locataire['telephone_locataire'],
        'date_naissance' => $locataire['date_naissance'],
        'rue'          => $locataire['rue_locataire'],
        'complement'   => $locataire['complement_locataire'],
        'id_commune'   => $locataire['id_commune'] ? (int) $locataire['id_commune'] : null,
        'nom_commune'  => $locataire['nom_commune'],
        'cp_commune'   => $locataire['cp_commune'],
    ],
]);
