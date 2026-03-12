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

    $originAllowed = hapIsAllowedOrigin($origin, $allowedOrigins);

    if ($originAllowed) {
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

/**
 * @param array<int, string> $allowedOrigins
 */
function hapIsAllowedOrigin(string $origin, array $allowedOrigins): bool
{
    if ($origin === '') {
        return false;
    }

    if (in_array($origin, $allowedOrigins, true)) {
        return true;
    }

    return hapIsLocalDevOrigin($origin);
}

function hapIsLocalDevOrigin(string $origin): bool
{
    $parts = parse_url($origin);
    if (!is_array($parts)) {
        return false;
    }

    $host = $parts['host'] ?? '';
    $scheme = $parts['scheme'] ?? '';

    if ($scheme !== 'http' && $scheme !== 'https') {
        return false;
    }

    return $host === 'localhost' || $host === '127.0.0.1';
}
