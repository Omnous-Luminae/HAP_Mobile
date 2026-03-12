<?php
/**
 * create_reservation.php — Création d'une réservation (API Mobile HAP)
 *
 * Méthode : POST (JSON body)
 * Headers : Authorization: Bearer <token>
 *
 * Body :
 *   {
 *     "id_biens":    <int>,
 *     "date_debut":  "YYYY-MM-DD",
 *     "date_fin":    "YYYY-MM-DD"
 *   }
 *
 * Réponse succès :
 *   {
 *     "success":        true,
 *     "id_reservation": <int>,
 *     "total_cost":     <float>,
 *     "tarif_semaine":  <float>,
 *     "nb_nuits":       <int>
 *   }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['POST', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';
require_once __DIR__ . '/../../config/jwt_config.php';
require_once __DIR__ . '/../../classes/JWTHelper.php';

// ── Auth JWT ───────────────────────────────────────────────────────────────
$authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
if (empty($authHeader) && function_exists('apache_request_headers')) {
    $h = apache_request_headers();
    $authHeader = $h['Authorization'] ?? '';
}

if (empty($authHeader) || !preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token manquant ou mal formé.']);
    exit;
}

$payload = \JWTHelper::decode($m[1], JWT_SECRET);
if ($payload === false) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token invalide ou expiré.']);
    exit;
}

$idLocataire = (int) ($payload['id_locataire'] ?? 0);
if ($idLocataire <= 0) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token corrompu.']);
    exit;
}

// ── Lecture du body JSON ───────────────────────────────────────────────────
$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Corps JSON invalide.']);
    exit;
}

$idBiens   = isset($input['id_biens'])   ? (int) $input['id_biens']     : 0;
$dateDebut = trim($input['date_debut']   ?? '');
$dateFin   = trim($input['date_fin']     ?? '');

if ($idBiens <= 0 || !$dateDebut || !$dateFin) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètres id_biens, date_debut, date_fin requis.']);
    exit;
}

// Validation des dates
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateDebut) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $dateFin)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Format de date invalide (YYYY-MM-DD attendu).']);
    exit;
}

$dtDebut = new DateTime($dateDebut);
$dtFin   = new DateTime($dateFin);

if ($dtDebut >= $dtFin) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'La date de début doit être avant la date de fin.']);
    exit;
}

if ($dtDebut < new DateTime('today')) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'La date de début ne peut pas être dans le passé.']);
    exit;
}

$nbNuits = (int) $dtDebut->diff($dtFin)->days;
if ($nbNuits < 1) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'La durée minimale est de 1 nuit.']);
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

// ── Vérification que le bien existe et est valide ──────────────────────────
$stmtBien = $pdo->prepare("SELECT id_biens FROM biens WHERE id_biens = :id AND validated = 1");
$stmtBien->execute([':id' => $idBiens]);
if (!$stmtBien->fetch()) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Bien introuvable ou non disponible.']);
    exit;
}

// ── Vérification de disponibilité (pas de chevauchement) ──────────────────
$stmtCheck = $pdo->prepare("
    SELECT COUNT(*) AS nb
    FROM reservation
    WHERE id_biens = :id
      AND date_debut_reservation < :fin
      AND date_fin_reservation   > :debut
");
$stmtCheck->execute([':id' => $idBiens, ':debut' => $dateDebut, ':fin' => $dateFin]);
$conflict = (int) $stmtCheck->fetchColumn();

if ($conflict > 0) {
    http_response_code(409);
    echo json_encode(['success' => false, 'message' => 'Ces dates sont déjà réservées pour ce bien.']);
    exit;
}

// ── Calcul du tarif applicable ─────────────────────────────────────────────
// Recherche du tarif pour la semaine ISO du début de réservation (année courante ou future)
$anneeDebut  = (int) $dtDebut->format('o'); // ISO year
$semaineDebut = (int) $dtDebut->format('W'); // ISO week

$stmtTarif = $pdo->prepare("
    SELECT id_Tarif, tarif
    FROM tarif
    WHERE id_biens = :id
      AND (
        (année_Tarif = :annee AND semaine_Tarif = :semaine)
        OR (année_Tarif = :annee AND semaine_Tarif <= :semaine)
        OR (année_Tarif < :annee)
      )
    ORDER BY
        ABS(année_Tarif - :annee) ASC,
        ABS(semaine_Tarif - :semaine) ASC
    LIMIT 1
");
$stmtTarif->execute([
    ':id'      => $idBiens,
    ':annee'   => $anneeDebut,
    ':semaine' => $semaineDebut,
]);
$tarif = $stmtTarif->fetch(PDO::FETCH_ASSOC);

// Fallback : prendre n'importe quel tarif du bien
if (!$tarif) {
    $stmtTarif2 = $pdo->prepare("SELECT id_Tarif, tarif FROM tarif WHERE id_biens = :id ORDER BY id_Tarif ASC LIMIT 1");
    $stmtTarif2->execute([':id' => $idBiens]);
    $tarif = $stmtTarif2->fetch(PDO::FETCH_ASSOC);
}

// Si aucun tarif, utiliser une valeur par défaut (0)
$idTarif     = $tarif ? (int)   $tarif['id_Tarif'] : 1;
$tarifAnnuel = $tarif ? (float) $tarif['tarif']    : 0.0;

// Coût total : tarif hebdomadaire × (nb nuits / 7)
$totalCost = round($tarifAnnuel * ($nbNuits / 7), 2);

// ── Insertion de la réservation ────────────────────────────────────────────
try {
    $stmtInsert = $pdo->prepare("
        INSERT INTO reservation
            (date_debut_reservation, date_fin_reservation, id_locataire, id_biens, id_Tarif, total_cost)
        VALUES
            (:debut, :fin, :locataire, :biens, :tarif, :cost)
    ");
    $stmtInsert->execute([
        ':debut'     => $dateDebut,
        ':fin'       => $dateFin,
        ':locataire' => $idLocataire,
        ':biens'     => $idBiens,
        ':tarif'     => $idTarif,
        ':cost'      => $totalCost,
    ]);
    $idReservation = (int) $pdo->lastInsertId();
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la création de la réservation.']);
    exit;
}

echo json_encode([
    'success'        => true,
    'id_reservation' => $idReservation,
    'total_cost'     => $totalCost,
    'tarif_semaine'  => $tarifAnnuel,
    'nb_nuits'       => $nbNuits,
]);
