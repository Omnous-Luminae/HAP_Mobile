<?php

/**
 * auth_register.php — Endpoint d'inscription mobile (JWT)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/api/mobile/auth_register.php
 *
 * Méthode  : POST
 * Body JSON : {
 *   "nom", "prenom", "email", "password",
 *   "telephone", "date_naissance", "rue", "id_commune"
 * }
 * Réponse  : { "success": true, "token": "...", "user": { ... } }
 *             ou { "success": false, "message": "..." }
 */

// ── En-têtes CORS + JSON ───────────────────────────────────────────────────
require_once __DIR__ . '/../../config/cors.php'; // NOSONAR - API procédurale sans autoloader
hapApplyCors(['POST', 'OPTIONS']);

// ── Chargement des dépendances ─────────────────────────────────────────────
require_once __DIR__ . '/../../config/db.php'; // NOSONAR - API procédurale sans autoloader
require_once __DIR__ . '/../../config/jwt_config.php'; // NOSONAR - API procédurale sans autoloader
$jwtHelperPath = __DIR__ . '/../../classes/' . 'JWTHelper.php';
require_once $jwtHelperPath; // NOSONAR - API procédurale sans autoloader
$pdo = getPDO();

// ── Lecture du corps JSON ──────────────────────────────────────────────────
$input = json_decode(file_get_contents('php://input'), true);

$nom            = trim($input['nom']            ?? '');
$prenom         = trim($input['prenom']         ?? '');
$email          = trim($input['email']          ?? '');
$password       = trim($input['password']       ?? '');
$telephone      = trim($input['telephone']      ?? '');
$date_naissance = trim($input['date_naissance'] ?? '');
$rue            = trim($input['rue']            ?? '');
$id_commune     = (int) ($input['id_commune']   ?? 0);

// ── Validation des champs obligatoires ────────────────────────────────────
if (empty($nom) || empty($prenom) || empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Nom, prénom, email et mot de passe sont obligatoires.']);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Adresse email invalide.']);
    exit;
}

if (strlen($password) < 8) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Le mot de passe doit contenir au moins 8 caractères.']);
    exit;
}


// ── Migration schema (varchar(20) → varchar(255)) ──────────────────────────
hapEnsureAuthSchema($pdo);

// ── Vérification unicité de l'email ───────────────────────────────────────
$stmt = $pdo->prepare('SELECT id_locataire FROM Locataire WHERE email_locataire = :email LIMIT 1');
$stmt->execute([':email' => $email]);
if ($stmt->fetch()) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'Cette adresse email est déjà utilisée.']);
    exit;
}

// ── Insertion du nouveau locataire ─────────────────────────────────────────
$hashedPassword = password_hash($password, PASSWORD_BCRYPT);

$stmt = $pdo->prepare(
    'INSERT INTO Locataire
        (nom_locataire, prenom_locataire, email_locataire, password_locataire,
         telephone_locataire, date_naissance, rue_locataire, id_commune)
     VALUES
        (:nom, :prenom, :email, :password, :telephone, :date_naissance, :rue, :id_commune)'
);
$stmt->execute([
    ':nom'            => $nom,
    ':prenom'         => $prenom,
    ':email'          => $email,
    ':password'       => $hashedPassword,
    ':telephone'      => $telephone,
    ':date_naissance' => $date_naissance ?: null,
    ':rue'            => $rue,
    ':id_commune'     => $id_commune ?: null,
]);

$newId = (int) $pdo->lastInsertId();

// ── Génération du JWT ──────────────────────────────────────────────────────
$now     = time();
$payload = [
    'id_locataire' => $newId,
    'email'        => $email,
    'nom'          => $nom,
    'prenom'       => $prenom,
    'iat'          => $now,
    'exp'          => $now + JWT_EXPIRY,
];

$token = \JWTHelper::encode($payload, JWT_SECRET);

// ── Réponse ────────────────────────────────────────────────────────────────
http_response_code(201);
echo json_encode([
    'success' => true,
    'token'   => $token,
    'user'    => [
        'id'        => $newId,
        'nom'       => $nom,
        'prenom'    => $prenom,
        'email'     => $email,
        'telephone' => $telephone,
    ],
]);
