<?php
/**
 * search_communes.php - Recherche de communes pour autocomplete.
 *
 * Methode: GET
 * Parametre: q (chaine de recherche)
 */

require_once __DIR__ . '/../config/cors.php'; // NOSONAR - API procedurale sans autoloader
hapApplyCors(['GET', 'OPTIONS']);

require_once __DIR__ . '/../config/db.php'; // NOSONAR - API procedurale sans autoloader

$query = trim($_GET['q'] ?? '');

if ($query === '') {
    echo json_encode([
        'success' => true,
        'data' => [],
    ]);
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
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de connexion a la base de donnees.',
    ]);
    exit;
}

$sql = 'SELECT id_commune, code_insee, nom_commune, cp_commune
        FROM Commune
        WHERE nom_commune LIKE :query OR cp_commune LIKE :query
        ORDER BY nom_commune ASC
        LIMIT 20';

try {
    $stmt = $pdo->prepare($sql);
    $stmt->execute([':query' => '%' . $query . '%']);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $data = array_map(static function (array $row): array {
        return [
            'id_commune' => (int) $row['id_commune'],
            'code_insee' => $row['code_insee'],
            'nom_commune' => $row['nom_commune'],
            'cp_commune' => $row['cp_commune'],
        ];
    }, $rows);

    echo json_encode([
        'success' => true,
        'data' => $data,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la recherche des communes.',
    ]);
}
