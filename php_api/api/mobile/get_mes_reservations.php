<?php
/**
 * get_mes_reservations.php — Réservations de l'utilisateur connecté (API Mobile HAP)
 *
 * Méthode : GET
 * Header  : Authorization: Bearer <token>
 *
 * Réponse :
 *   {
 *     "success": true,
 *     "data": [
 *       {
 *         "id_reservation", "date_debut", "date_fin",
 *         "total_cost", "nb_nuits", "statut",
 *         "bien": { "id_biens", "nom_biens", "nom_commune", "photo" }
 *       }
 *     ]
 *   }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

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
    echo json_encode(['success' => false, 'message' => 'Token manquant.']);
    exit;
}

$payload = \JWTHelper::decode($m[1], JWT_SECRET);
if ($payload === false) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Token invalide ou expiré.']);
    exit;
}

$idLocataire = (int) ($payload['id_locataire'] ?? 0);

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
    echo json_encode(['success' => false, 'message' => 'Erreur de connexion.']);
    exit;
}

$stmt = $pdo->prepare("
    SELECT
        r.id_reservation,
        DATE_FORMAT(r.date_debut_reservation, '%Y-%m-%d') AS date_debut,
        DATE_FORMAT(r.date_fin_reservation,   '%Y-%m-%d') AS date_fin,
        DATEDIFF(r.date_fin_reservation, r.date_debut_reservation) AS nb_nuits,
        r.total_cost,
        CASE
            WHEN r.date_fin_reservation < CURDATE()   THEN 'termine'
            WHEN r.date_debut_reservation > CURDATE() THEN 'a_venir'
            ELSE 'en_cours'
        END AS statut,
        b.id_biens,
        b.nom_biens,
        c.nom_commune,
        (SELECT p.lien_photo FROM photos p WHERE p.id_biens = b.id_biens LIMIT 1) AS photo
    FROM reservation r
    JOIN biens b   ON b.id_biens   = r.id_biens
    LEFT JOIN commune c ON c.id_commune = b.id_commune
    WHERE r.id_locataire = :id
    ORDER BY r.date_debut_reservation DESC
");
$stmt->execute([':id' => $idLocataire]);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$data = array_map(function ($row) {
    return [
        'id_reservation' => (int)   $row['id_reservation'],
        'date_debut'     =>         $row['date_debut'],
        'date_fin'       =>         $row['date_fin'],
        'nb_nuits'       => (int)   $row['nb_nuits'],
        'total_cost'     => (float) $row['total_cost'],
        'statut'         =>         $row['statut'],
        'bien'           => [
            'id_biens'    => (int) $row['id_biens'],
            'nom_biens'   =>       $row['nom_biens'],
            'nom_commune' =>       $row['nom_commune'],
            'photo'       =>       $row['photo'],
        ],
    ];
}, $rows);

echo json_encode(['success' => true, 'data' => $data]);
