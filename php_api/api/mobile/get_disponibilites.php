<?php
/**
 * get_disponibilites.php — Dates réservées d'un bien (API Mobile HAP)
 *
 * Méthode : GET
 * Paramètre : ?id_biens=<id>
 *
 * Réponse :
 *   {
 *     "success": true,
 *     "reserved_ranges": [
 *       { "debut": "2025-07-01", "fin": "2025-07-08" },
 *       ...
 *     ]
 *   }
 *
 * Utilisé par le calendrier pour griser les dates déjà réservées.
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';

$idBiens = isset($_GET['id_biens']) ? (int) $_GET['id_biens'] : 0;
if ($idBiens <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètre id_biens manquant.']);
    exit;
}

try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8',
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de connexion.']);
    exit;
}

// ── Réservations confirmées ────────────────────────────────────────────────
$stmtRes = $pdo->prepare("
    SELECT
        DATE_FORMAT(date_debut_reservation, '%Y-%m-%d') AS debut,
        DATE_FORMAT(date_fin_reservation,   '%Y-%m-%d') AS fin
    FROM reservation
    WHERE id_biens = :id
      AND date_fin_reservation >= CURDATE()
    ORDER BY date_debut_reservation ASC
");
$stmtRes->execute([':id' => $idBiens]);
$ranges = $stmtRes->fetchAll(PDO::FETCH_ASSOC);

// ── Semaines manuellement bloquées (admin) ────────────────────────────────
$stmtSem = $pdo->prepare("
    SELECT annee, semaine
    FROM semaine_indisponible
    WHERE id_biens = :id
");
$stmtSem->execute([':id' => $idBiens]);
$unavailableWeeks = $stmtSem->fetchAll(PDO::FETCH_ASSOC);

// Convertir semaines ISO → plages de dates lundi-dimanche
foreach ($unavailableWeeks as $w) {
    $dt = new DateTime();
    $dt->setISODate((int) $w['annee'], (int) $w['semaine']);
    $debut = $dt->format('Y-m-d');
    $dt->modify('+6 days');
    $fin = $dt->format('Y-m-d');
    if ($fin >= date('Y-m-d')) {
        $ranges[] = ['debut' => $debut, 'fin' => $fin];
    }
}

echo json_encode(['success' => true, 'reserved_ranges' => $ranges]);
