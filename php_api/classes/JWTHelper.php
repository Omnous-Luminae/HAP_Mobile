<?php
/**
 * JWTHelper.php — Classe utilitaire JWT pure PHP (sans dépendance externe)
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/classes/JWTHelper.php
 *
 * Implémente le standard JWT (JSON Web Token) RFC 7519 :
 *   - Algorithme : HMAC-SHA256 (HS256)
 *   - Encodage   : Base64Url (sans padding)
 *   - Format     : header.payload.signature
 */
class JWTHelper
{
    /**
     * Encode un payload en JWT signé.
     *
     * @param  array  $payload  Données à inclure dans le token (id, email, exp, iat…)
     * @param  string $secret   Clé secrète HMAC
     * @return string           Token JWT complet (header.payload.signature)
     */
    public static function encode(array $payload, string $secret): string
    {
        $header = [
            'typ' => 'JWT',
            'alg' => 'HS256',
        ];

        $headerEncoded  = self::base64UrlEncode(json_encode($header));
        $payloadEncoded = self::base64UrlEncode(json_encode($payload));

        $signature = self::sign($headerEncoded . '.' . $payloadEncoded, $secret);

        return $headerEncoded . '.' . $payloadEncoded . '.' . $signature;
    }

    /**
     * Décode et vérifie un JWT.
     *
     * @param  string       $token   Token JWT à vérifier
     * @param  string       $secret  Clé secrète HMAC
     * @return array|false           Payload décodé, ou false si invalide / expiré
     */
    public static function decode(string $token, string $secret)
    {
        $decodedPayload = false;
        $parts = explode('.', $token);
        if (count($parts) === 3) {
            [$headerEncoded, $payloadEncoded, $signatureReceived] = $parts;

            // Vérification de la signature
            $expectedSignature = self::sign($headerEncoded . '.' . $payloadEncoded, $secret);
            if (hash_equals($expectedSignature, $signatureReceived)) {
                // Décodage du payload
                $payload = json_decode(self::base64UrlDecode($payloadEncoded), true);
                // Vérification conjointe de la structure et de l'expiration
                if (is_array($payload) && (!isset($payload['exp']) || $payload['exp'] >= time())) {
                    $decodedPayload = $payload;
                }
            }
        }

        return $decodedPayload;
    }

    /**
     * Vérifie uniquement la validité d'un JWT (signature + expiration).
     *
     * @param  string $token   Token JWT à vérifier
     * @param  string $secret  Clé secrète HMAC
     * @return bool            true si le token est valide et non expiré
     */
    public static function verify(string $token, string $secret): bool
    {
        return self::decode($token, $secret) !== false;
    }

    // -------------------------------------------------------------------------
    // Méthodes privées
    // -------------------------------------------------------------------------

    /**
     * Calcule la signature HMAC-SHA256 d'un message.
     *
     * @param  string $data    Données à signer (header.payload)
     * @param  string $secret  Clé secrète
     * @return string          Signature encodée en Base64Url
     */
    private static function sign(string $data, string $secret): string
    {
        return self::base64UrlEncode(
            hash_hmac('sha256', $data, $secret, true)
        );
    }

    /**
     * Encode une chaîne en Base64Url (sans caractères =, +, /).
     *
     * @param  string $data  Données brutes
     * @return string        Chaîne Base64Url
     */
    private static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Décode une chaîne Base64Url.
     *
     * @param  string $data  Chaîne Base64Url
     * @return string        Données décodées
     */
    private static function base64UrlDecode(string $data): string
    {
        $padded = strtr($data, '-_', '+/');
        $padded .= str_repeat('=', (4 - strlen($padded) % 4) % 4);
        return base64_decode($padded);
    }
}
