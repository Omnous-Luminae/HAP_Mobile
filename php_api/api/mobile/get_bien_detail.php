<?php
/**
 * get_bien_detail.php — Détail complet d'un bien (API Mobile HAP)
 *
 * Méthode : GET
 * Paramètre : ?id=<id_biens>
 *
 * Réponse :
 *   {
 *     "success": true,
 *     "bien": { ...info, "photos": [...], "avis": [...], "tarifs": [...] }
 *   }
 */

require_once __DIR__ . '/../../config/cors.php';
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../../config/db.php';

$idBiens = isset($_GET['id']) ? (int) $_GET['id'] : 0;
if ($idBiens <= 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Paramètre id manquant ou invalide.']);
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
    echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données.']);
    exit;
}

// ── Infos principales du bien ──────────────────────────────────────────────
$stmtBien = $pdo->prepare("
    SELECT
        b.id_biens,
        b.nom_biens,
        b.rue_biens,
        b.superficie_biens,
        b.description_biens,
        b.animal_biens,
        b.nb_couchage,
        tb.designation_type_bien,
        c.nom_commune,
        c.cp_commune,
        c.latitude_commune  AS lat_commune,
        c.longitude_commune AS long_commune,
        ROUND(AVG(r.rating), 1)     AS note_moyenne,
        COUNT(DISTINCT r.id_review) AS nb_avis
    FROM biens b
    LEFT JOIN type_bien tb ON tb.id_type_biens  = b.id_type_biens
    LEFT JOIN commune   c  ON c.id_commune       = b.id_commune
    LEFT JOIN reviews   r  ON r.id_biens         = b.id_biens AND r.validated = 1
    WHERE b.id_biens = :id AND b.validated = 1
    GROUP BY
        b.id_biens, b.nom_biens, b.rue_biens, b.superficie_biens,
        b.description_biens, b.animal_biens, b.nb_couchage,
        tb.designation_type_bien, c.nom_commune, c.cp_commune,
        c.latitude_commune, c.longitude_commune
");
$stmtBien->execute([':id' => $idBiens]);
$bien = $stmtBien->fetch(PDO::FETCH_ASSOC);

if (!$bien) {
    http_response_code(404);
    echo json_encode(['success' => false, 'message' => 'Bien introuvable.']);
    exit;
}

// ── Photos ─────────────────────────────────────────────────────────────────
$stmtPhotos = $pdo->prepare("
    SELECT id_photo, nom_photos, lien_photo
    FROM photos
    WHERE id_biens = :id
    ORDER BY id_photo ASC
");
$stmtPhotos->execute([':id' => $idBiens]);
$photos = $stmtPhotos->fetchAll(PDO::FETCH_ASSOC);

// ── Avis validés ───────────────────────────────────────────────────────────
$stmtAvis = $pdo->prepare("
    SELECT
        r.id_review,
        r.rating,
        r.content,
        r.created_at,
        CONCAT(l.prenom_locataire, ' ', LEFT(l.nom_locataire, 1), '.') AS auteur
    FROM reviews r
    LEFT JOIN locataire l ON l.id_locataire = r.id_locataire
    WHERE r.id_biens = :id AND r.validated = 1
    ORDER BY r.created_at DESC
    LIMIT 10
");
$stmtAvis->execute([':id' => $idBiens]);
$avis = $stmtAvis->fetchAll(PDO::FETCH_ASSOC);

// ── Tarifs (prochaines semaines) ───────────────────────────────────────────
$stmtTarifs = $pdo->prepare("
    SELECT
        t.id_Tarif,
        t.semaine_Tarif,
        t.année_Tarif   AS annee,
        t.tarif,
        s.lib_saison
    FROM tarif t
    JOIN saison s ON s.id_saison = t.id_saison
    WHERE t.id_biens = :id
      AND (t.année_Tarif > YEAR(NOW())
           OR (t.année_Tarif = YEAR(NOW()) AND t.semaine_Tarif >= WEEK(NOW(), 1)))
    ORDER BY t.année_Tarif ASC, t.semaine_Tarif ASC
");
$stmtTarifs->execute([':id' => $idBiens]);
$tarifs = $stmtTarifs->fetchAll(PDO::FETCH_ASSOC);

// ── Formatage ──────────────────────────────────────────────────────────────
$bien['note_moyenne']     = $bien['note_moyenne'] !== null ? (float) $bien['note_moyenne'] : null;
$bien['nb_avis']          = (int) $bien['nb_avis'];
$bien['superficie_biens'] = (float) $bien['superficie_biens'];
$bien['animal_biens']     = (int) $bien['animal_biens'];
$bien['nb_couchage']      = (int) $bien['nb_couchage'];
$bien['lat_commune']      = $bien['lat_commune'] !== null ? (float) $bien['lat_commune'] : null;
$bien['long_commune']     = $bien['long_commune'] !== null ? (float) $bien['long_commune'] : null;
$bien['photos']           = $photos;
$bien['avis']             = array_map(function ($a) {
    $a['rating'] = (int) $a['rating'];
    return $a;
}, $avis);
$bien['tarifs']           = array_map(function ($t) {
    $t['semaine_Tarif'] = (float) $t['semaine_Tarif'];
    $t['annee']         = (int)   $t['annee'];
    $t['tarif']         = (float) $t['tarif'];
    $t['id_Tarif']      = (int)   $t['id_Tarif'];
    return $t;
}, $tarifs);

echo json_encode(['success' => true, 'bien' => $bien]);
