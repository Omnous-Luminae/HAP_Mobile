<?php
/**
 * jwt_config.php — Configuration JWT pour l'API mobile HAP
 *
 * CE FICHIER DOIT ÊTRE PLACÉ DANS :
 *   Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/config/jwt_config.php
 *
 * ⚠️  Remplacez JWT_SECRET par une chaîne aléatoire de 32+ caractères en production.
 *     Ne commitez jamais ce fichier avec votre vraie clé secrète dans un dépôt public.
 */

// Clé secrète utilisée pour signer les tokens JWT (HMAC-SHA256)
// Générez une clé forte avec : openssl rand -base64 32
define('JWT_SECRET', 'HAP_m0b1l3_S3cr3t_K3y_Ch4ng3_M3_1n_Pr0d!');

// Durée de validité d'un token : 30 jours en secondes
define('JWT_EXPIRY', 2592000);

// Algorithme de signature
define('JWT_ALGORITHM', 'HS256');
