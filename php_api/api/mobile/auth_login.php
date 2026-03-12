<?php

/**
 * auth_login.php — Endpoint d'authentification mobile (JWT)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/api/mobile/auth_login.php
 *
 * Méthode  : POST
 * Body JSON : { "email": "...", "password": "..." }
 * Réponse  : { "success": true, "token": "...", "user": { ... } }
 *             ou { "success": false, "message": "..." }
 */

// ── En-têtes CORS + JSON ───────────────────────────────────────────────────
require_once __DIR__ . '/../../config/cors.php'; // NOSONAR - API procédurale sans autoloader
hapApplyCors(['POST', 'OPTIONS']);

// ── Chargement des dépendances ─────────────────────────────────────────────
require_once __DIR__ . '/../../config/db.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../config/jwt_config.php'; // NOSONAR - API procédurale sans autoloader
$jwtHelperPath = __DIR__ . '/../../classes/JWTHelper.php';
require_once $jwtHelperPath; // NOSONAR - API procédurale sans autoloader

// ── Lecture du corps JSON ──────────────────────────────────────────────────
$input = json_decode(file_get_contents('php://input'), true);

$email    = trim($input['email']    ?? '');
$password = trim($input['password'] ?? '');

if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Email et mot de passe requis.']);
    exit;
}

// ── Connexion BDD ──────────────────────────────────────────────────────────
try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8',
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données.']);
    exit;
}

// ── Recherche du locataire ─────────────────────────────────────────────────
$stmt = $pdo->prepare(
    'SELECT id_locataire, nom_locataire, prenom_locataire, email_locataire,
            password_locataire, telephone_locataire
     FROM   Locataire
     WHERE  email_locataire = :email
     LIMIT  1'
);
$stmt->execute([':email' => $email]);
$locataire = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$locataire || !password_verify($password, $locataire['password_locataire'])) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect.']);
    exit;
}

// ── Génération du JWT ──────────────────────────────────────────────────────
$now     = time();
$payload = [
    'id_locataire' => (int) $locataire['id_locataire'],
    'email'        => $locataire['email_locataire'],
    'nom'          => $locataire['nom_locataire'],
    'prenom'       => $locataire['prenom_locataire'],
    'iat'          => $now,
    'exp'          => $now + JWT_EXPIRY,
];

$token = \JWTHelper::encode($payload, JWT_SECRET);

// ── Réponse ────────────────────────────────────────────────────────────────
echo json_encode([
    'success' => true,
    'token'   => $token,
    'user'    => [
        'id'        => (int) $locataire['id_locataire'],
        'nom'       => $locataire['nom_locataire'],
        'prenom'    => $locataire['prenom_locataire'],
        'email'     => $locataire['email_locataire'],
        'telephone' => $locataire['telephone_locataire'],
    ],
]);
