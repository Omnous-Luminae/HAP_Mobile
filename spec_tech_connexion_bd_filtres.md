# Spécification technique – Authentification JWT, Connexion BDD & Filtres
### Version 3 — avec explications détaillées

---

## Partie 1 — C'est quoi un JWT et pourquoi on l'utilise ?

### Le problème que ça résout

Quand un utilisateur se connecte à l'application, le serveur PHP doit pouvoir répondre à une question simple sur chaque requête suivante : **"Est-ce que cette personne est bien connectée, et qui est-elle ?"**

La solution naïve serait de renvoyer l'email et le mot de passe à chaque requête — évidemment trop dangereux. Une autre approche classique côté web est la **session PHP** (un identifiant de session stocké dans un cookie), mais ça fonctionne mal pour une application mobile : les apps n'ont pas de cookies natifs, et les sessions PHP nécessitent que le serveur garde en mémoire qui est connecté, ce qui pose des problèmes dès qu'on a plusieurs serveurs.

Le **JWT (JSON Web Token)** résout tout ça : le serveur génère un "badge" signé après le login, l'app le garde, et l'envoie à chaque requête. Le serveur peut vérifier ce badge **sans consulter la base de données**, juste en vérifiant la signature mathématique.

### L'analogie du bracelet

Imagine une boîte de nuit :
- À l'entrée tu montres ta pièce d'identité (email + mot de passe) → c'est le **login**
- Le videur te donne un bracelet tamponné avec une date → c'est le **JWT**
- Pour chaque consommation au bar, tu montres juste le bracelet → c'est l'**envoi du token dans chaque requête**
- Le bracelet a une date d'expiration (ici 30 jours). Après ça, tu dois retourner à l'entrée te réauthentifier

Ce qui est élégant : le barman n'a pas besoin d'appeler le videur à chaque verre. Il vérifie juste que le bracelet est authentique et pas expiré.

---

## Partie 2 — Structure d'un JWT : ce que c'est concrètement

Un JWT ressemble à ça dans la pratique :

```
eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMjN9.SflKxwRJSMeKKF2QT4fwpMeJf36
```

C'est trois blocs séparés par des points. Chaque bloc est encodé en **base64** (un format texte qui transforme n'importe quelles données en caractères lisibles). Voici ce que contient chaque bloc :

**Bloc 1 — Le Header** : dit simplement quel algorithme a été utilisé pour signer. Dans ce projet c'est `HS256` (HMAC avec SHA-256).

**Bloc 2 — Le Payload** : c'est la partie utile. Elle contient les informations sur l'utilisateur : son ID, son email, son rôle, l'heure à laquelle le token a été créé (`iat` = "issued at"), et l'heure à laquelle il expire (`exp`). **Important** : ces données ne sont pas chiffrées, juste encodées. N'importe qui peut les lire si il intercepte le token. C'est pourquoi on n'y met jamais de mot de passe ni de données sensibles.

**Bloc 3 — La Signature** : c'est ce qui garantit que personne n'a modifié le token. Le serveur PHP prend le header + le payload, et les signe mathématiquement avec la clé secrète `JWT_SECRET`. Si quelqu'un essaie de modifier le payload (par exemple changer son `user_id` pour usurper une autre identité), la signature ne correspondra plus et le serveur rejettera le token.

---

## Partie 3 — La configuration JWT dans le projet

Le fichier `php_api/config/jwt_config.php` définit trois constantes qui gouvernent tout le système :

**`JWT_SECRET`** — C'est la clé secrète utilisée pour signer et vérifier tous les tokens. C'est le secret le plus critique de l'application : si quelqu'un la connaît, il peut fabriquer des tokens valides et se faire passer pour n'importe quel utilisateur. La valeur actuelle dans le repo (`HAP_m0b1l3_S3cr3t_K3y_Ch4ng3_M3_1n_Pr0d!`) est un **placeholder de développement** — elle doit absolument être remplacée par une vraie clé aléatoire avant tout déploiement, générée avec la commande `openssl rand -base64 32`. Elle ne doit jamais être committée dans Git en production.

**`JWT_EXPIRY`** — Durée de validité d'un token, ici 2 592 000 secondes = **30 jours**. Passé ce délai, le token est automatiquement rejeté même s'il est techniquement valide. Ce choix de 30 jours est un équilibre entre confort (l'utilisateur n'a pas à se reconnecter souvent) et sécurité (si un token est volé, il finira par expirer).

**`JWT_ALGORITHM`** — L'algorithme de signature, ici `HS256`. Cela signifie HMAC + SHA-256 : une fonction mathématique à sens unique qui produit une empreinte unique à partir des données et de la clé secrète.

```php
define('JWT_SECRET', 'HAP_m0b1l3_S3cr3t_K3y_Ch4ng3_M3_1n_Pr0d!'); // ⚠️ CHANGER EN PROD
define('JWT_EXPIRY', 2592000);   // 30 jours
define('JWT_ALGORITHM', 'HS256');
```

---

## Partie 4 — Ce qui se passe lors d'un login (côté PHP)

Quand l'utilisateur soumet son email et son mot de passe, voici les étapes que le backend PHP effectue :

**Étape 1 — Vérification des credentials** : PHP cherche l'utilisateur dans la base de données par son email, puis vérifie que le mot de passe correspond au hash stocké (`password_verify`). Si ça échoue, on retourne une erreur générique sans préciser si c'est l'email ou le mot de passe qui est faux (pour éviter l'énumération de comptes).

**Étape 2 — Construction du payload** : PHP prépare le contenu du token : l'ID de l'utilisateur, son email, son rôle, l'heure actuelle (`iat`), et l'heure d'expiration (`exp` = maintenant + 30 jours).

**Étape 3 — Calcul de la signature** : PHP encode le header et le payload en base64, puis calcule la signature HMAC-SHA256 sur `header.payload` en utilisant `JWT_SECRET`.

**Étape 4 — Assemblage et retour** : Les trois parties sont assemblées en `header.payload.signature` et renvoyées à Flutter dans la réponse JSON, accompagnées des infos de base sur l'utilisateur.

```php
// Le token est retourné dans une réponse de ce type :
{
  "success": true,
  "token": "eyJhbGci....",
  "user": { "id": 42, "prenom": "Alice", "role": "particulier" }
}
```

---

## Partie 5 — Ce qui se passe sur chaque requête protégée (côté PHP)

Quand Flutter envoie une requête vers un endpoint qui nécessite d'être connecté (ex : créer une réservation, accéder aux favoris), PHP doit vérifier le token. Voici le processus :

**Étape 1 — Extraction du token** : PHP lit le header HTTP `Authorization` de la requête. Ce header doit contenir `Bearer ` suivi du token. Si ce header est absent ou mal formé, PHP répond immédiatement avec une erreur 401 (non autorisé).

**Étape 2 — Découpe du token** : PHP sépare le token en ses trois parties (header, payload, signature) en découpant sur les points.

**Étape 3 — Vérification de la signature** : PHP recalcule la signature attendue à partir du header et du payload reçus, en utilisant `JWT_SECRET`. Il compare ensuite cette signature recalculée avec celle reçue. Si elles diffèrent, le token a été modifié ou fabriqué — rejet immédiat en 401. La comparaison utilise `hash_equals()` (et non `===`) pour éviter les attaques par timing.

**Étape 4 — Vérification de l'expiration** : PHP décode le payload et vérifie que le champ `exp` est supérieur à l'heure actuelle. Si le token est expiré, rejet en 401 avec le message "Token expiré".

**Étape 5 — Traitement normal** : Si tout est valide, PHP extrait le `user_id` du payload et traite la requête normalement, en sachant exactement quel utilisateur fait la demande, sans aucune requête BDD supplémentaire.

---

## Partie 6 — Ce que Flutter fait avec le token

### Après le login : stockage

Quand Flutter reçoit le token dans la réponse du login, il le sauvegarde dans `shared_preferences` — le système de stockage local de Flutter, l'équivalent du localStorage sur le web. On stocke le token lui-même et son timestamp d'expiration pour pouvoir le vérifier localement plus tard.

```dart
await prefs.setString('jwt_token', token);
await prefs.setInt('jwt_expiry', expiryTimestamp);
```

### Sur chaque requête : envoi dans le header

Pour chaque appel API nécessitant une authentification, Flutter récupère le token stocké et l'ajoute dans le header `Authorization` de la requête HTTP. Le serveur PHP s'attend exactement à ce format.

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
}
```

### Vérification locale avant la requête

Avant même d'envoyer une requête, Flutter peut vérifier localement si le token est encore valide en comparant le timestamp d'expiration stocké avec l'heure actuelle. Une marge de 5 minutes est conseillée pour éviter les cas limites où le token expirerait pendant la requête.

Si le token est déjà expiré localement, Flutter déclenche directement la déconnexion sans même appeler le serveur.

### Gestion d'une réponse 401

Si malgré tout le serveur répond avec un code 401 (token invalide ou expiré côté serveur), Flutter doit réagir proprement : vider le token stocké, vider le cache mémoire, et rediriger l'utilisateur vers le LoginScreen avec un message contextuel "Votre session a expirée, veuillez vous reconnecter". Cette logique doit être centralisée dans un `ApiService` unique pour ne pas la répéter dans chaque appel.

### Déconnexion manuelle

Quand l'utilisateur clique sur "Déconnexion", Flutter supprime simplement le token des `shared_preferences` et vide le cache. Il n'y a pas d'appel serveur nécessaire car les JWT sont stateless — le serveur ne garde pas de liste des tokens actifs, ils sont valides ou expirés point final.

---

## Partie 7 — Connexion à la base de données (PDO centralisé)

### Pourquoi centraliser ?

Sans centralisation, chaque fichier PHP qui a besoin de la BDD ferait son propre `new PDO(...)` avec ses propres identifiants hardcodés. Ça pose trois problèmes : si les identifiants changent, il faut modifier des dizaines de fichiers ; si une connexion échoue, le comportement d'erreur sera différent partout ; et on risque d'ouvrir plusieurs connexions inutiles vers MySQL.

La solution : un fichier unique `php_api/config/db.php` avec une fonction `getPDO()` qui utilise un **singleton** — c'est-à-dire qu'elle crée la connexion une seule fois et réutilise toujours la même ensuite.

### Comment ça marche

La variable `$pdo` est déclarée `static` à l'intérieur de la fonction. En PHP, une variable statique dans une fonction garde sa valeur entre les appels. Donc la première fois que `getPDO()` est appelée, `$pdo` vaut `null`, la connexion est créée. La deuxième fois, `$pdo` a déjà une valeur, la connexion existante est retournée directement.

Si la connexion échoue (mauvais identifiants, serveur MySQL injoignable), on lève une `DatabaseConnectionException` personnalisée au lieu de faire un `echo + exit` directement. Pourquoi ? Parce que ça donne aux endpoints la possibilité de gérer l'erreur comme ils veulent (logger, retourner un format JSON spécifique, etc.), plutôt que d'avoir un comportement brutal et identique partout.

Les valeurs par défaut (`root`, `project_hap`) ne sont là que pour le développement local sous XAMPP. En production, **toutes** ces valeurs doivent venir de variables d'environnement définies sur le serveur, jamais hardcodées dans le code.

```php
// Utilisation dans n'importe quel endpoint :
require_once __DIR__ . '/../../config/db.php';

try {
    $pdo = getPDO();
} catch (DatabaseConnectionException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    exit;
}
// À partir d'ici, $pdo est disponible et fiable
```

---

## Partie 8 — Pagination des résultats

### Pourquoi c'est indispensable

Sans pagination, un endpoint comme "liste des biens" retournerait potentiellement des centaines d'objets d'un coup. Sur mobile, ça signifie une requête lente, beaucoup de mémoire utilisée, et une mauvaise expérience. La pagination limite chaque réponse à un nombre raisonnable d'éléments (ici 20 par défaut) et permet à Flutter de charger la suite au fur et à mesure que l'utilisateur scrolle.

### Convention adoptée

Flutter envoie deux paramètres en plus des filtres : `page` (numéro de la page, commence à 1) et `per_page` (nombre d'éléments par page). PHP répond avec les données ET des métadonnées indiquant le total d'éléments disponibles, ce qui permet à Flutter de savoir s'il y a encore des pages à charger.

```
GET /api/biens?type_bien=2&prix_max=500&page=2&per_page=20
```

La réponse contient toujours `total`, `page`, et `per_page` pour que Flutter puisse calculer s'il y a une page suivante (`page * per_page < total`).

PHP protège aussi contre les abus : `per_page` est plafonné à 100 même si Flutter demande plus, et `page` est forcé à minimum 1 même si une valeur invalide est envoyée.

---

## Partie 9 — Gestion des filtres (Flutter)

### Le modèle FilterOptions

Toutes les options de filtrage sont regroupées dans une seule classe `FilterOptions`. Cette classe est **immuable** : au lieu de modifier ses propriétés, on crée une nouvelle instance avec les nouvelles valeurs via une méthode `copyWith`. Ça facilite la gestion d'état avec Riverpod et évite les bugs liés aux mutations accidentelles.

Une propriété `null` signifie "filtre non actif". Par exemple `prixMin = null` veut dire "pas de filtre sur le prix minimum". C'est important pour ne pas envoyer des paramètres inutiles à l'API.

### Les seuils comme constantes

Les valeurs "par défaut" des sliders (prix jusqu'à 5000€, superficie jusqu'à 500m²) ne doivent pas être écrites en dur dans l'UI. Si ces valeurs changent, il faudrait les retrouver et les modifier partout. Elles sont donc définies dans un fichier de constantes partagé, importé partout où nécessaire.

### activeCount

Cette propriété calculée indique combien de filtres sont actuellement actifs. Elle est utilisée pour afficher le badge rouge sur le bouton de filtre (ex : "3" si 3 filtres sont appliqués). Elle ne compte que les filtres "métier" (prix, type, animaux...), pas le tri ni la recherche textuelle qui sont toujours présents.

### Pourquoi la logique dans le modèle et pas dans l'UI

La règle "si le prix max est égal à la valeur par défaut, ne pas l'envoyer à l'API" est une règle **métier**, pas une règle d'affichage. Elle appartient donc au modèle `FilterOptions`, dans sa méthode `toQueryParams()`. Si on la met dans le widget BottomSheet, elle devient invisible et difficile à tester — et si on a un autre endroit dans l'app qui applique des filtres, on devra rédupliquer cette logique.

---

## Partie 10 — Gestion d'état avec Riverpod

Riverpod est le gestionnaire d'état choisi pour ce projet. Son rôle est de rendre les données accessibles depuis n'importe quel widget de l'app, et de mettre à jour automatiquement l'interface quand ces données changent.

Concrètement pour les filtres : quand l'utilisateur valide de nouveaux filtres dans le BottomSheet, Riverpod met à jour le `FilterOptions` global. Tous les widgets qui "écoutent" ce provider (la liste des biens, le badge de filtre, la barre de recherche) sont automatiquement reconstruits avec les nouvelles valeurs. Pas besoin de passer des callbacks manuellement entre widgets.

---

## Partie 11 — Gestion des erreurs réseau

Chaque appel HTTP peut échouer de plusieurs façons : timeout (le serveur met trop de temps), erreur serveur (500), session expirée (401), pas de connexion internet. Chaque cas doit produire un message adapté à l'utilisateur — pas juste "une erreur s'est produite".

Cette gestion doit être centralisée dans un `ApiService` unique. On y distingue : les `TimeoutException` (message "connexion trop lente"), les `SocketException` (message "pas de connexion internet"), les 401 (déconnexion + redirection), et les autres codes d'erreur HTTP (message générique avec proposition de réessayer).

---

## Partie 12 — Cache des requêtes

Le cache évite de rappeler l'API si l'utilisateur revient sur la même recherche avec les mêmes filtres. C'est une Map en mémoire qui associe une "clé" (la représentation textuelle des filtres actifs) à la liste de biens correspondante.

Ce cache est **en mémoire uniquement** — il est vidé à chaque redémarrage de l'app. C'est volontaire : les données de biens peuvent changer (nouvelle disponibilité, nouveau prix), donc un cache trop persistant risque d'afficher des données obsolètes. Pour un cache plus avancé avec gestion de TTL, on pourrait intégrer `dio_cache_interceptor`.

---

## Flux complet — De la connexion à l'affichage des résultats filtrés

```
FLUTTER                                PHP + MySQL
  │                                        │
  │  1. POST /login                        │
  │     { email, password }  ─────────────►│
  │                                        │  Vérifie les credentials en BDD
  │                                        │  Génère le JWT (HS256, 30 jours)
  │  2. Réponse { token, user } ◄──────────│
  │                                        │
  │  3. Stocke token + expiry              │
  │     dans shared_preferences            │
  │                                        │
  │  4. GET /biens?page=1&prix_max=500     │
  │     Header: Authorization: Bearer eyJ  │
  │                              ─────────►│
  │                                        │  Vérifie signature JWT
  │                                        │  Vérifie expiration
  │                                        │  Applique les filtres SQL
  │                                        │  Pagine les résultats
  │  5. Réponse { data, total } ◄──────────│
  │                                        │
  │  6. [Si 401 reçu]                      │
  │     → Supprime token                   │
  │     → Redirige LoginScreen             │
```

---

## Synthèse des règles à respecter

**Sécurité**
- `JWT_SECRET` doit être une clé forte, différente par environnement, jamais dans Git
- Ne jamais mettre de données sensibles (mot de passe, CB) dans le payload JWT
- Toujours utiliser `hash_equals()` pour comparer les signatures, jamais `===`
- Les valeurs par défaut de BDD (root, project_hap) ne sont autorisées qu'en dev local

**Architecture**
- Un seul `getPDO()` dans `db.php` — aucun `new PDO()` ailleurs
- Un seul `ApiService` Flutter qui gère l'envoi du token et les erreurs réseau
- La logique métier des filtres appartient à `FilterOptions`, pas aux widgets
- Les seuils numériques des filtres sont des constantes nommées dans un fichier dédié

**Performance**
- Pagination obligatoire sur tous les endpoints de liste
- Cache mémoire côté Flutter pour éviter les appels répétés à filtres identiques
- Vérification locale de l'expiration du token avant chaque requête