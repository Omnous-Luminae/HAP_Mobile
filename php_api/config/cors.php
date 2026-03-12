<?php
/**
 * cors.php - Politique CORS centralisee pour l'API mobile.
 */

/**
 * Applique les en-tetes CORS et gere la requete preflight OPTIONS.
 *
 * @param array<int, string> $methods Methodes HTTP autorisees.
 */
function hapApplyCors(array $methods = ['GET', 'POST', 'OPTIONS']): void
{
    $origin = $_SERVER['HTTP_ORIGIN'] ?? '';

    $defaultOrigins = [
        'http://localhost',
        'http://localhost:8080',
        'http://127.0.0.1',
        'http://127.0.0.1:8080',
        'http://10.0.2.2',
        'http://10.0.2.2:8080',
    ];

    $envOrigins = getenv('ALLOWED_ORIGINS') ?: '';
    $allowedOrigins = array_filter(array_map('trim', explode(',', $envOrigins)));
    if (empty($allowedOrigins)) {
        $allowedOrigins = $defaultOrigins;
    }

    if ($origin !== '' && in_array($origin, $allowedOrigins, true)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Vary: Origin');
    }

    header('Access-Control-Allow-Methods: ' . implode(', ', $methods));
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    header('Content-Type: application/json; charset=utf-8');

    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}
