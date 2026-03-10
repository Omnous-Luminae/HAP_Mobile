## 7. Modules & Écrans Flutter

> 🔍 **Légende des adaptations mobiles** :  
> ✅ Aucune adaptation nécessaire — le widget est nativement mobile  
> ⚠️ Adaptation recommandée — plan détaillé fourni ci-dessous  
> 🔧 Ajout requis — dépendance ou logique manquante à implémenter

---

## 0. Connexion à la base de données (PHP)

> 🔧 **Prérequis** — Ce fichier doit être créé avant tout développement des APIs PHP. Il est inclus en tête de chaque script API.

Créer le fichier `api/db.php` :

```php
<?php
// api/db.php — Connexion PDO sécurisée à project_hap
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'project_hap');
define('DB_USER', 'root');   // À adapter selon l'environnement
define('DB_PASS', '');       // XAMPP : vide par défaut

function getPDO(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT
                 . ';dbname=' . DB_NAME . ';charset=utf8mb4';
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode(['error' => 'Connexion BDD échouée']);
            exit;
        }
    }
    return $pdo;
}

// Headers communs à toutes les APIs
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
```

**Usage dans chaque API :**
```php
<?php
require_once __DIR__ . '/db.php';
$pdo = getPDO();
```

---

## Index des performances BDD recommandées

À exécuter une seule fois après import du dump SQL :

```sql
-- Optimise les requêtes Haversine sur commune (36 000+ entrées)
CREATE INDEX idx_commune_geo
ON commune(latitude_commune, longitude_commune);

-- Optimise les recherches de réservations par bien + dates
CREATE INDEX idx_reservations_biens_dates
ON reservations(id_biens, date_debut, date_fin);

-- Optimise les recherches de favoris
CREATE INDEX idx_favoris_user
ON favoris(id_utilisateur, id_biens);
```

---

### 7.1 Authentification

#### 📐 `LoginScreen` (`auth/connexion.php` → `api/login.php`)

**Fonctionnalités :**
- Formulaire email + mot de passe avec token CSRF géré côté PHP
- Protection anti-brute force : l'API retourne un statut de blocage après 5 tentatives infructueuses (blocage 15 min)
- Message contextuel si redirection depuis une tentative de réservation sans connexion
- Persistance de session via `shared_preferences` (token/user_id)
- Régénération de l'ID de session côté PHP à chaque connexion réussie
- Navigation vers `InscriptionScreen` et `ForgotPasswordScreen`
- Navigation automatique vers l'écran précédent après connexion réussie

**Widgets :** `TextFormField`, `ElevatedButton`, `SnackBar`  
**API :** `POST api/login.php`

**Statut mobile :** ✅ Nativement adapté — widgets tactiles standards

**SQL impliqué :**
```sql
-- Recherche de l'utilisateur
SELECT id_utilisateur, nom_utilisateur, prenom_utilisateur,
       email_utilisateur, password_utilisateur, role_utilisateur
FROM utilisateur
WHERE email_utilisateur = :email
LIMIT 1;

-- Vérification anti-brute force
SELECT COUNT(*) AS nb_tentatives
FROM login_attempts
WHERE ip_address = :ip
  AND success = 0
  AND attempt_time > DATE_SUB(NOW(), INTERVAL 15 MINUTE);

-- Enregistrement d'une tentative
INSERT INTO login_attempts (ip_address, email, success, attempt_time)
VALUES (:ip, :email, :success, NOW());
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Email + MDP valides | Token retourné, `HTTP 200` |
| T2 | MDP incorrect | `HTTP 401`, message générique |
| T3 | Email inexistant | `HTTP 401`, même message générique (pas d'énumération) |
| T4 | 5 tentatives échouées en < 15 min | `HTTP 429`, message de blocage |
| T5 | Tentative après 15 min de blocage | Débloqué, `HTTP 200` si valide |
| T6 | Champs vides | `HTTP 422`, erreur de validation |
| T7 | Token CSRF manquant ou invalide | `HTTP 403` |

---

#### 📝 `InscriptionScreen` (`auth/inscription.php`)

**Fonctionnalités :**
- Formulaire multi-étapes avec `Stepper` :
  - **Étape 1** : Choix du type de compte (particulier / entreprise)
  - **Étape 2** : Informations personnelles (nom, prénom, email, téléphone, date de naissance)
  - **Étape 3** : Adresse avec autocomplete via API `adresse.data.gouv.fr`
  - **Étape 4** : Pour les entreprises — saisie SIRET avec validation algorithme de Luhn
  - **Étape 5** : Mot de passe conforme CNIL (min. 8 caractères, 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial)
- Vérification de la majorité (18+ ans) via calcul de date de naissance
- Captcha mathématique anti-bot (question simple générée côté PHP, validée côté serveur)
- Acceptation RGPD obligatoire (case à cocher)
- Protection anti-spam : blocage de l'IP après trop de tentatives
- Token CSRF pour sécuriser la soumission

**Widgets :** `Stepper`, `TextFormField`, `DropdownButton`, `Checkbox`  
**API :** `POST api/register.php`, `GET adresse.data.gouv.fr`, API SIREN

**Statut mobile :** ⚠️ Adaptation recommandée

> **Plan d'adaptation — `InscriptionScreen` (Stepper 5 étapes) :**  
>  
> **Problème :** 5 étapes = risque de perte de données si l'app passe en arrière-plan entre deux étapes.
>  
> **Solution :**  
> - Persister l'état du formulaire entre les étapes avec un `StateNotifier` Riverpod (ou `ChangeNotifier` Provider) dédié `InscriptionFormNotifier`  
> - Stocker temporairement les valeurs saisies dans `shared_preferences` à chaque passage d'étape (`onStepContinue`)  
> - Restaurer l'état au rechargement de l'écran (`initState`)  
> - Afficher un indicateur de progression clair (`Stepper` en mode `StepperType.horizontal` si l'espace le permet, sinon `vertical`)  
> - Vider le stockage temporaire à la soumission réussie ou à l'annulation explicite

**SQL impliqué :**
```sql
-- Vérification unicité de l'email
SELECT COUNT(*) FROM utilisateur WHERE email_utilisateur = :email;

-- Insertion d'un particulier
INSERT INTO utilisateur
  (nom_utilisateur, prenom_utilisateur, email_utilisateur, telephone_utilisateur,
   date_naissance_utilisateur, password_utilisateur, role_utilisateur,
   rue_utilisateur, id_commune)
VALUES
  (:nom, :prenom, :email, :telephone, :date_naissance,
   :password_hash, 'particulier', :rue, :id_commune);

-- Insertion d'une entreprise (avec SIRET)
INSERT INTO utilisateur
  (nom_utilisateur, prenom_utilisateur, email_utilisateur, telephone_utilisateur,
   date_naissance_utilisateur, password_utilisateur, role_utilisateur,
   rue_utilisateur, id_commune, siret_utilisateur, nom_entreprise)
VALUES
  (:nom, :prenom, :email, :telephone, :date_naissance,
   :password_hash, 'entreprise', :rue, :id_commune, :siret, :nom_entreprise);

-- Anti-spam : vérification IP
SELECT COUNT(*) FROM register_attempts
WHERE ip_address = :ip
  AND attempt_time > DATE_SUB(NOW(), INTERVAL 1 HOUR);
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Toutes les étapes valides (particulier) | Compte créé, `HTTP 201` |
| T2 | Email déjà existant | `HTTP 409`, message d'erreur |
| T3 | SIRET invalide (Luhn échoue) | Étape 4 bloquée |
| T4 | Âge < 18 ans | Étape 2 bloquée |
| T5 | Captcha mathématique faux | `HTTP 422` |
| T6 | RGPD non coché | Formulaire bloqué côté client |
| T7 | App en arrière-plan entre étapes | État restauré depuis `shared_preferences` |
| T8 | MDP non conforme CNIL | Étape 5 bloquée avec message explicite |

---

#### 🔑 `ForgotPasswordScreen` (`auth/forgot_password.php`)

**Fonctionnalités :**
- Saisie de l'adresse email
- Appel API → vérification existence du compte (réponse générique pour éviter l'énumération)
- Génération d'un token sécurisé côté PHP (valide 1 heure)
- En mode local XAMPP : affichage direct du lien de réinitialisation dans l'app
- Navigation vers `ResetPasswordScreen` avec le token

**API :** `POST api/forgot_password.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Vérification existence du compte (réponse générique)
SELECT id_utilisateur FROM utilisateur
WHERE email_utilisateur = :email LIMIT 1;

-- Insertion du token de réinitialisation
INSERT INTO password_reset_tokens (id_utilisateur, token, expires_at)
VALUES (:id_utilisateur, SHA2(:token_brut, 256), DATE_ADD(NOW(), INTERVAL 1 HOUR));
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Email existant | `HTTP 200`, message générique (lien affiché en local XAMPP) |
| T2 | Email inexistant | `HTTP 200`, même message générique |
| T3 | Token expiré (> 1h) | `HTTP 410` à la tentative de reset |

---

#### 🔓 `ResetPasswordScreen` (`auth/reset_password.php`)

**Fonctionnalités :**
- Saisie du nouveau mot de passe + confirmation
- Validation : longueur min. 8 caractères, correspondance des deux champs
- Vérification du token côté PHP (SHA-256, expiration 1h)
- Hash bcrypt du nouveau mot de passe côté PHP
- Suppression du token après utilisation
- Message de succès + redirection vers `LoginScreen`

**API :** `POST api/reset_password.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Vérification du token
SELECT prt.id_utilisateur, prt.expires_at
FROM password_reset_tokens prt
WHERE prt.token = SHA2(:token, 256)
  AND prt.expires_at > NOW()
LIMIT 1;

-- Mise à jour du MDP
UPDATE utilisateur
SET password_utilisateur = :bcrypt_hash
WHERE id_utilisateur = :id_utilisateur;

-- Suppression du token après utilisation
DELETE FROM password_reset_tokens WHERE token = SHA2(:token, 256);
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Token valide + MDP conforme | MDP mis à jour, `HTTP 200` |
| T2 | Token expiré | `HTTP 410` |
| T3 | MDP et confirmation différents | `HTTP 422` |
| T4 | Token déjà utilisé | `HTTP 410` (supprimé après usage) |

---

### 7.2 Accueil

#### 🏠 `AccueilScreen` (`index.php`)

**Fonctionnalités :**
- Hero banner avec slogan « Avec nous les soirées peuvent s'arroser »
- Boutons CTA :
  - « Voir les logements » → `AnnoncesScreen`
  - « Événements à proximité » → `EvenementsScreen`
- Carrousel de biens en avant (derniers biens ajoutés / mis en avant)
- Menu de navigation adaptatif selon le rôle :
  - Visiteur : Accueil, Annonces, Carte, Points d'intérêt, Blog
  - Utilisateur connecté : + Profil, Favoris
- Bouton de connexion / déconnexion dans l'`AppBar`
- Message de bienvenue avec le prénom de l'utilisateur si connecté
- Support thème clair/sombre (switch accessible depuis `ProfilScreen`)

**Widgets :** `CarouselSlider`, `ListView`, `AppBar`, `ElevatedButton`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué : **
```sql
-- Biens mis en avant (derniers validés, non masqués)
SELECT b.id_biens, b.nom_biens, b.description_biens, b.nb_couchage,
       c.nom_commune, c.cp_commune,
       t.nom_type_biens,
       (SELECT tr.prix_nuit FROM tarifs tr WHERE tr.id_biens = b.id_biens
        ORDER BY tr.date_debut ASC LIMIT 1) AS prix_nuit,
       (SELECT AVG(a.note_avis) FROM avis a
        WHERE a.id_biens = b.id_biens AND a.statut_avis = 'publie') AS note_moyenne
FROM biens b
INNER JOIN commune c ON b.id_commune = c.id_commune
INNER JOIN type_biens t ON b.id_type_biens = t.id_type_biens
WHERE b.is_hidden = 0 AND b.validated = 1
ORDER BY b.id_biens DESC
LIMIT 6;
```

---

### 7.3 Annonces & Recherche

#### 📋 `AnnoncesScreen` (`forms/Annonce.form.php`)

**Fonctionnalités :**
- Liste des biens disponibles affichée en `GridView` ou `ListView`
- **Filtres combinés** :
  - Prix (min / max)
  - Capacité (nombre de personnes)
  - Type de bien (appartement, maison, studio…)
  - Équipements / prestations
  - Commune (autocomplete via `api/search_communes.php`)
- Recherche textuelle avec autocomplete (`api/search_biens.php`)
- Galerie d'aperçu pour chaque bien (`cached_network_image`)
- Bouton cœur ❤️ pour ajouter/retirer des favoris (`api/favoris.php`, nécessite connexion)
- Navigation vers `DetailAnnonceScreen` au clic sur un bien

**Widgets :** `GridView`, `FilterChip`, `SearchBar`, `CachedNetworkImage`  
**API :** `GET api/search_biens.php`, `GET api/search_communes.php`, `POST api/favoris.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Recherche combinée avec filtres + géolocalisation (Haversine intégré)
SELECT b.id_biens, b.nom_biens, b.nb_couchage, b.animal_biens,
       c.nom_commune, c.cp_commune, c.latitude_commune, c.longitude_commune,
       t.nom_type_biens,
       MIN(tr.prix_nuit) AS prix_min,
       AVG(a.note_avis) AS note_moyenne,
       (6371 * ACOS(
         COS(RADIANS(:lat)) * COS(RADIANS(c.latitude_commune))
         * COS(RADIANS(c.longitude_commune) - RADIANS(:lng))
         + SIN(RADIANS(:lat)) * SIN(RADIANS(c.latitude_commune))
       )) AS distance_km
FROM biens b
INNER JOIN commune c ON b.id_commune = c.id_commune
INNER JOIN type_biens t ON b.id_type_biens = t.id_type_biens
LEFT JOIN tarifs tr ON tr.id_biens = b.id_biens
LEFT JOIN avis a ON a.id_biens = b.id_biens AND a.statut_avis = 'publie'
WHERE b.is_hidden = 0
  AND b.validated = 1
  AND (:prix_min IS NULL OR tr.prix_nuit >= :prix_min)
  AND (:prix_max IS NULL OR tr.prix_nuit <= :prix_max)
  AND (:capacite IS NULL OR b.nb_couchage >= :capacite)
  AND (:id_type IS NULL OR b.id_type_biens = :id_type)
  AND (:id_commune IS NULL OR b.id_commune = :id_commune)
  -- Filtre géolocalisation : rayon en km (actif uniquement si lat/lng fournis)
  AND (:lat IS NULL OR (6371 * ACOS(
    COS(RADIANS(:lat)) * COS(RADIANS(c.latitude_commune))
    * COS(RADIANS(c.longitude_commune) - RADIANS(:lng))
    + SIN(RADIANS(:lat)) * SIN(RADIANS(c.latitude_commune))
  )) <= :rayon)
GROUP BY b.id_biens
ORDER BY
  CASE WHEN :lat IS NOT NULL THEN distance_km ELSE b.id_biens END ASC
LIMIT 50;
```

> 💡 **Note géolocalisation :** La formule Haversine est intégrée directement en SQL — pas de champ GPS à ajouter dans `utilisateur`. Les colonnes `latitude_commune` et `longitude_commune` de la table `commune` sont suffisantes.

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Recherche sans filtre | Liste complète (max 50) |
| T2 | Filtre prix max = 50€ | Seuls les biens ≤ 50€/nuit |
| T3 | Filtre commune "Lyon" | Biens de Lyon uniquement |
| T4 | Filtre géolocalisation activé (lat/lng valides, rayon 10 km) | Biens triés par distance croissante |
| T5 | Coordonnées GPS invalides | Filtre ignoré, liste normale |
| T6 | Aucun résultat | `[]` avec `HTTP 200` |

---

#### 🏡 `DetailAnnonceScreen` (`forms/annonce_detail.php`)

**Fonctionnalités :**
- Galerie d'images du bien en swipe (`PageView`)
- Informations complètes : titre, description, prix/nuit, capacité, type, adresse
- **Calendrier de disponibilité** (`TableCalendar`) :
  - Dates déjà réservées bloquées (`api/get_availability.php`)
  - Semaines spéciales (indisponibles) colorées en rouge (`api/get_reservations_bien.php`)
  - Date minimale de sélection = aujourd'hui
- **Calcul automatique du tarif** selon la plage sélectionnée :
  - Tarif de base (prix/nuit × nb nuits)
  - Modificateur saisonnier (`api/get_tarifs_week.php`)
  - Affichage du détail du coût (`api/calculate_reservation_cost.php`)
- Liste des avis / notes ⭐ du bien
- Bouton « Ajouter aux favoris » (toggle ❤️)
- Bouton « Réserver » :
  - Redirige vers `LoginScreen` si non connecté (avec message contextuel)
  - Ouvre `ReservationScreen` si connecté

**Widgets :** `PageView`, `TableCalendar`, `RatingBar`, `ElevatedButton`  
**API :** `GET api/get_bien.php`, `GET api/get_availability.php`, `GET api/get_reservations_bien.php`, `GET api/get_tarifs_week.php`, `POST api/calculate_reservation_cost.php`

**Statut mobile :** ⚠️ Adaptation recommandée

> **Plan d'adaptation — `DetailAnnonceScreen` (écran dense) :**
>  
> **Problème :** Cet écran cumule galerie + calendrier + calcul de tarif + avis + boutons d'action. Sur mobile, tout ne peut pas être visible sans scroll — il faut éviter les widgets figés qui bloquent le défilement.
>  
> **Solution :**
> - Utiliser `CustomScrollView` avec des `Sliver` pour un défilement fluide de tout l'écran :
>   ```dart
>   CustomScrollView(
>     slivers: [
>       SliverAppBar(expandedHeight: 250, flexibleSpace: /* galerie PageView */),
>       SliverToBoxAdapter(child: /* infos bien */),
>       SliverToBoxAdapter(child: /* TableCalendar */),
>       SliverToBoxAdapter(child: /* calcul tarif */),
>       SliverList(delegate: /* liste avis */),
>     ],
>   )
>   ```
> - Placer les boutons d'action (Favoris + Réserver) dans un `BottomAppBar` fixe en bas d'écran — ils restent toujours visibles sans polluer le scroll
> - Limiter la hauteur du `TableCalendar` en mode `CalendarFormat.twoWeeks` par défaut, avec option d'expansion en `month`
> - Afficher uniquement les 3 premiers avis avec un bouton « Voir tous les avis » → `AvisScreen` filtré sur ce bien

**SQL impliqué :**
```sql
-- Détail complet d'un bien
SELECT b.*, c.nom_commune, c.cp_commune, c.latitude_commune, c.longitude_commune,
       t.nom_type_biens,
       AVG(a.note_avis) AS note_moyenne,
       COUNT(a.id_avis) AS nb_avis
FROM biens b
INNER JOIN commune c ON b.id_commune = c.id_commune
INNER JOIN type_biens t ON b.id_type_biens = t.id_type_biens
LEFT JOIN avis a ON a.id_biens = b.id_biens AND a.statut_avis = 'publie'
WHERE b.id_biens = :id_biens AND b.is_hidden = 0 AND b.validated = 1
GROUP BY b.id_biens;

-- Disponibilités bloquées
SELECT date_debut, date_fin FROM reservations
WHERE id_biens = :id_biens
  AND statut_reservation NOT IN ('annulee', 'archivee')
  AND date_fin >= CURDATE();

-- Semaines indisponibles (JSON dans le champ unavailable_weeks)
SELECT unavailable_weeks FROM biens WHERE id_biens = :id_biens;

-- Avis du bien (3 premiers)
SELECT u.prenom_utilisateur, a.note_avis, a.commentaire_avis, a.date_avis
FROM avis a
INNER JOIN utilisateur u ON a.id_utilisateur = u.id_utilisateur
WHERE a.id_biens = :id_biens AND a.statut_avis = 'publie'
ORDER BY a.date_avis DESC
LIMIT 3;
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Détail d'un bien existant | Détails corrects, `HTTP 200` |
| T2 | Bien inexistant | `HTTP 404` |
| T3 | Réservations bloquées à partir d'une date future | Listé correctement |
| T4 | Aucune avis disponible | Liste vide | 

---

### 7.4 Réservation

#### 📅 `ReservationScreen` (`api/update_reservation.php`)

**Fonctionnalités :**
- Sélection de la plage de dates avec `TableCalendar` (date de début + date de fin)
- Blocage dynamique des dates indisponibles (déjà réservées ou semaines spéciales)
- Date minimale = aujourd'hui (pas de réservation dans le passé)
- Calcul automatique du montant total :
  - Tarif de base × nombre de nuits
  - Application des modificateurs saisonniers ou de semaines spéciales
- **Récapitulatif** avant confirmation : bien, dates, montant total
- Confirmation → appel `POST api/update_reservation.php`
- Affichage du succès + navigation vers `ProfilScreen` (historique)
- Annulation possible depuis `ProfilScreen`

**Widgets :** `TableCalendar`, `Card`, `ElevatedButton`  
**API :** `GET api/get_availability.php`, `GET api/get_tarifs_week.php`, `POST api/calculate_reservation_cost.php`, `POST api/update_reservation.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Vérification de disponibilité avant insertion
SELECT COUNT(*) AS conflit
FROM reservations
WHERE id_biens = :id_biens
  AND statut_reservation NOT IN ('annulee', 'archivee')
  AND date_debut < :date_fin
  AND date_fin > :date_debut;

-- Calcul du coût (modificateurs saisonniers)
SELECT tr.prix_nuit, tr.modificateur
FROM tarifs tr
WHERE tr.id_biens = :id_biens
  AND tr.date_debut <= :date_fin
  AND tr.date_fin >= :date_debut;

-- Insertion de la réservation
INSERT INTO reservations
  (id_utilisateur, id_biens, date_debut, date_fin, montant_total, statut_reservation, date_reservation)
VALUES
  (:id_utilisateur, :id_biens, :date_debut, :date_fin, :montant_total, 'en_attente', NOW());
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Dates disponibles + utilisateur connecté | Réservation créée, `HTTP 201` |
| T2 | Dates chevauchant une réservation existante | `HTTP 409`, message de conflit |
| T3 | Date de début dans le passé | `HTTP 422` |
| T4 | Utilisateur non connecté | `HTTP 401` |
| T5 | Bien masqué ou non validé | `HTTP 404` |

---

### 7.5 Carte Interactive

#### 🗺️ `CarteScreen` (`map.php`)

**Fonctionnalités :**
- Carte OpenStreetMap via `FlutterMap` (gratuit, sans clé API)
- **Couche biens** : marqueurs colorisés selon le type de bien, cliquables
- **Couche points d'intérêt** : marqueurs distinctifs (clubs 🎵, bars 🍺, restaurants 🍽️…) en superposition (`api/get_poi.php`)
- Clic sur un marqueur de bien → fiche résumée (titre, prix, note) avec bouton vers `DetailAnnonceScreen`
- Clic sur un marqueur POI → fiche résumée avec bouton vers `PtsInteretDetailScreen`
- Centrage automatique sur la position de l'utilisateur (si permission accordée)

**Widgets :** `FlutterMap`, `MarkerLayer`, `Marker`, `BottomSheet`  
**API :** `GET api/get_poi.php`, `GET api/search_biens.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Tous les biens avec coordonnées (marqueurs carte)
SELECT b.id_biens, b.nom_biens, c.latitude_commune, c.longitude_commune,
       t.nom_type_biens, MIN(tr.prix_nuit) AS prix_nuit,
       AVG(a.note_avis) AS note_moyenne
FROM biens b
INNER JOIN commune c ON b.id_commune = c.id_commune
INNER JOIN type_biens t ON b.id_type_biens = t.id_type_biens
LEFT JOIN tarifs tr ON tr.id_biens = b.id_biens
LEFT JOIN avis a ON a.id_biens = b.id_biens AND a.statut_avis = 'publie'
WHERE b.is_hidden = 0 AND b.validated = 1
GROUP BY b.id_biens;

-- Points d'intérêt (api/get_poi.php)
SELECT id_poi, nom_poi, type_poi, adresse_poi,
       latitude_poi, longitude_poi
FROM points_interet
WHERE is_hidden = 0;
```

> 💡 **Géolocalisation :** La position de l'utilisateur (marqueur bleu) vient **uniquement du GPS du téléphone** via `geolocator` — rien n'est stocké en BDD.

---

#### 📍 `PtsInteretDetailScreen` (`forms/pts_interet_detail.php`)

**Fonctionnalités :**
- Affichage des informations du point d'intérêt : nom, type, adresse, coordonnées GPS
- Liste des biens à proximité du point d'intérêt
- Navigation vers `DetailAnnonceScreen` pour chaque bien listé

**Widgets :** `DetailCard`, `ListView`

**Statut mobile :** ✅ Nativement adapté

---

### 7.6 Favoris

#### ❤️ `FavorisScreen` (`forms/mes_favoris.php`)

**Fonctionnalités :**
- Affichage des biens mis en favoris par l'utilisateur connecté
- `GridView` avec `FavoriCard` (image, titre, prix/nuit, note)
- Suppression d'un favori via bouton cœur (toggle `api/favoris.php`)
- Navigation vers `DetailAnnonceScreen` au clic sur une carte
- Message « Aucun favori » si la liste est vide
- Accessible uniquement si connecté

**Widgets :** `GridView`, `FavoriCard`, `IconButton`  
**API :** `GET api/favoris.php`, `POST api/favoris.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Liste des favoris d'un utilisateur
SELECT b.id_biens, b.nom_biens, c.nom_commune,
       MIN(tr.prix_nuit) AS prix_nuit, AVG(a.note_avis) AS note_moyenne
FROM favoris f
INNER JOIN biens b ON f.id_biens = b.id_biens
INNER JOIN commune c ON b.id_commune = c.id_commune
LEFT JOIN tarifs tr ON tr.id_biens = b.id_biens
LEFT JOIN avis a ON a.id_biens = b.id_biens AND a.statut_avis = 'publie'
WHERE f.id_utilisateur = :id_utilisateur AND b.is_hidden = 0
GROUP BY b.id_biens;

-- Ajouter un favori
INSERT INTO favoris (id_utilisateur, id_biens, date_ajout)
VALUES (:id_utilisateur, :id_biens, NOW())
ON DUPLICATE KEY UPDATE date_ajout = NOW();

-- Supprimer un favori
DELETE FROM favoris
WHERE id_utilisateur = :id_utilisateur AND id_biens = :id_biens;
```

---

### 7.7 Avis & Blog

#### 📝 `AvisScreen` (`forms/blog.php`)

**Fonctionnalités :**
- Liste des avis publiés avec note ⭐ (1 à 5), commentaire, date, auteur
- Filtres : par bien, par note minimale
- Pagination de la liste
- **Soumission d'un avis** (utilisateur connecté uniquement) :
  - Sélection du bien concerné parmi les biens réservés par l'utilisateur
  - Note de 1 à 5 étoiles (`RatingBar`)
  - Commentaire libre
  - Les avis soumis sont **en attente de modération** avant publication
- Message informatif si aucun avis disponible

**Widgets :** `ListView`, `RatingBar`, `TextFormField`, `DropdownButton`  
**API :** `GET api/get_avis.php`, `POST api/submit_avis.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Liste des avis publiés avec filtres et pagination
SELECT a.id_avis, a.note_avis, a.commentaire_avis, a.date_avis,
       u.prenom_utilisateur, u.nom_utilisateur,
       b.nom_biens
FROM avis a
INNER JOIN utilisateur u ON a.id_utilisateur = u.id_utilisateur
INNER JOIN biens b ON a.id_biens = b.id_biens
WHERE a.statut_avis = 'publie'
  AND (:id_biens IS NULL OR a.id_biens = :id_biens)
  AND (:note_min IS NULL OR a.note_avis >= :note_min)
ORDER BY a.date_avis DESC
LIMIT 20 OFFSET :offset;

-- Vérification : l'utilisateur a bien réservé ce bien
SELECT COUNT(*) FROM reservations
WHERE id_utilisateur = :id_utilisateur
  AND id_biens = :id_biens
  AND statut_reservation IN ('confirmee', 'archivee');

-- Insertion d'un avis (en attente de modération)
INSERT INTO avis (id_utilisateur, id_biens, note_avis, commentaire_avis, statut_avis, date_avis)
VALUES (:id_utilisateur, :id_biens, :note, :commentaire, 'en_attente', NOW());
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Soumission d'avis par un utilisateur ayant réservé | Avis en attente de modération, `HTTP 201` |
| T2 | Tentative d'avis sans réservation associée | `HTTP 403` |
| T3 | Note hors plage (0 ou 6) | `HTTP 422` |

---

### 7.8 Profil

#### 👤 `ProfilScreen` (`auth/profile.php`)

**Fonctionnalités :**
- Affichage des informations personnelles de l'utilisateur connecté
- **Modification du profil** :
  - Champs : nom, prénom, email, téléphone, date de naissance, adresse, commune
  - Autocomplete adresse via `adresse.data.gouv.fr`
  - Acceptation RGPD obligatoire pour toute modification
  - Validation de tous les champs obligatoires avant soumission
- **Changement de mot de passe** :
  - Vérification de l'ancien mot de passe
  - Saisie + confirmation du nouveau mot de passe
  - Validation : les deux champs doivent correspondre
- **Historique des réservations** de l'utilisateur :
  - Statuts : en attente, confirmée, annulée, archivée
  - Annulation d'une réservation en cours (bouton dédié)
- **Switch thème clair/sombre** (persisté via `shared_preferences`)
- Bouton de déconnexion

**Widgets :** `UserInfoCard`, `ListView`, `Switch`, `TextFormField`, `ElevatedButton`  
**API :** `GET api/get_profil.php`, `POST api/update_profil.php`, `GET api/get_reservations.php`, `DELETE api/delete_reservation.php`

**Statut mobile :** ⚠️ Adaptation recommandée

> **Plan d'adaptation — `ProfilScreen` (écran très dense) :**
>  
> **Problème :** L'écran regroupe : infos personnelles + changement de MDP + historique réservations + switch thème + déconnexion. C'est trop de contenu pour un seul écran mobile sans structure claire.
>  
> **Solution — découpage en sections avec `TabBar` :**
> ```dart
> DefaultTabController(
>   length: 3,
>   child: Scaffold(
>     appBar: AppBar(
>       title: Text('Mon profil'),
>       bottom: TabBar(tabs: [
>         Tab(icon: Icon(Icons.person), text: 'Infos'),
>         Tab(icon: Icon(Icons.history), text: 'Réservations'),
>         Tab(icon: Icon(Icons.settings), text: 'Paramètres'),
>       ]),
>     ),
>     body: TabBarView(children: [
>       /* Onglet 1 : infos perso + modif profil + changement MDP */
>       /* Onglet 2 : historique réservations avec statuts + annulation */
>       /* Onglet 3 : switch thème + déconnexion */
>     ]),
>   ),
> )
> ```
> - Utiliser `ExpansionTile` dans l'onglet "Infos" pour séparer "Modifier le profil" et "Changer le mot de passe" (repliés par défaut)
> - Dans l'onglet "Réservations", utiliser un `ListView` avec des `Card` colorées selon le statut (vert=confirmée, orange=en attente, rouge=annulée, gris=archivée)

**SQL impliqué :**
```sql
-- Récupération du profil
SELECT u.id_utilisateur, u.nom_utilisateur, u.prenom_utilisateur,
       u.email_utilisateur, u.telephone_utilisateur, u.date_naissance_utilisateur,
       u.rue_utilisateur, c.nom_commune, c.cp_commune, u.role_utilisateur
FROM utilisateur u
LEFT JOIN commune c ON u.id_commune = c.id_commune
WHERE u.id_utilisateur = :id_utilisateur;

-- Mise à jour du profil
UPDATE utilisateur SET
  nom_utilisateur = :nom,
  prenom_utilisateur = :prenom,
  email_utilisateur = :email,
  telephone_utilisateur = :telephone,
  rue_utilisateur = :rue,
  id_commune = :id_commune
WHERE id_utilisateur = :id_utilisateur;

-- Changement de mot de passe (vérification ancien MDP puis update)
SELECT password_utilisateur FROM utilisateur WHERE id_utilisateur = :id_utilisateur;
UPDATE utilisateur SET password_utilisateur = :nouveau_hash
WHERE id_utilisateur = :id_utilisateur;

-- Historique des réservations
SELECT r.id_reservation, r.date_debut, r.date_fin, r.montant_total,
       r.statut_reservation, b.nom_biens, c.nom_commune
FROM reservations r
INNER JOIN biens b ON r.id_biens = b.id_biens
INNER JOIN commune c ON b.id_commune = c.id_commune
WHERE r.id_utilisateur = :id_utilisateur
ORDER BY r.date_debut DESC;

-- Annulation d'une réservation (uniquement si statut = en_attente)
UPDATE reservations
SET statut_reservation = 'annulee'
WHERE id_reservation = :id_reservation
  AND id_utilisateur = :id_utilisateur
  AND statut_reservation = 'en_attente';
```

**Tests :**
| # | Scénario | Résultat attendu |
|---|---|---|
| T1 | Mise à jour profil avec données valides | `HTTP 200`, données mises à jour |
| T2 | Changement MDP avec ancien MDP incorrect | `HTTP 401` |
| T3 | Annulation réservation en statut `confirmee` | `HTTP 403` |
| T4 | Switch thème persisté après redémarrage | Thème restauré depuis `shared_preferences` |

---

### 7.9 Support

#### 🎧 `SupportScreen` (`contact.php`)

**Fonctionnalités :**
- Formulaire de création de ticket :
  - **Type** : question / signalement / erreur / suggestion / autre
  - **Sujet** : champ texte court
  - **Message** : champ texte long
  - **Priorité** : basse / normale / haute / urgente
  - **Page concernée** : champ optionnel
- Si connecté : email et nom pré-remplis depuis la session
- Si non connecté : saisie email obligatoire avec validation `filter_var`
- Numéro de ticket affiché après soumission (ex: `#000042`)
- Tous les champs obligatoires (type, sujet, message) vérifiés avant envoi

**Widgets :** `Form`, `DropdownButton`, `TextFormField`, `ElevatedButton`, `SnackBar`  
**API :** `POST api/manage_contacts.php`

**Statut mobile :** ✅ Nativement adapté

**SQL impliqué :**
```sql
-- Insertion d'un ticket de support
INSERT INTO contacts
  (id_utilisateur, email_contact, nom_contact, type_contact,
   sujet_contact, message_contact, priorite_contact, page_concernee,
   numero_ticket, date_contact, statut_contact)
VALUES
  (:id_utilisateur, :email, :nom, :type,
   :sujet, :message, :priorite, :page,
   LPAD(LAST_INSERT_ID() + 1, 6, '0'), NOW(), 'ouvert');
```

---

### 7.10 Géolocalisation Mobile

> 🔧 **Ajout requis** — La géolocalisation est une fonctionnalité native mobile absente de la version web. Elle s'intègre dans `CarteScreen`, `AnnoncesScreen` et `PtsInteretDetailScreen`.

---

#### 📐 Vue d'ensemble

La géolocalisation permet à l'application de :
- Centrer automatiquement la carte sur la position GPS réelle de l'utilisateur
- Trier les biens et points d'intérêt par **distance croissante**
- Proposer un filtre « Autour de moi » dans `AnnoncesScreen`
- Calculer et afficher la **distance entre l'utilisateur et un bien / POI**

> **Décision d'architecture BDD :** La position GPS de l'utilisateur est **éphémère** et gérée exclusivement côté Flutter via `geolocator`. **Aucune table ni colonne GPS n'est ajoutée** pour l'utilisateur. Les colonnes `latitude_commune` et `longitude_commune` de la table `commune` (déjà existantes) sont suffisantes pour calculer les distances côté PHP via la formule de Haversine.

---

#### 📦 Dépendance Flutter

Ajouter dans `pubspec.yaml` :
```yaml
geolocator: ^11.0.0        # Accès GPS natif Android & iOS
```

---

#### 🔐 Permissions requises

**Android** — `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**iOS** — `ios/Runner/Info.plist` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>L'application utilise votre position pour afficher les logements et points d'intérêt à proximité.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>L'application utilise votre position pour vous proposer des logements proches.</string>
```

---

#### ⚙️ Service de géolocalisation — `LocationService`

Créer un service dédié `lib/services/location_service.dart` :

```dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Vérifie les permissions et retourne la position actuelle.
  /// Retourne null si la permission est refusée ou le GPS désactivé.
  static Future<Position?> getCurrentPosition() async {
    // 1. Vérifier si le service GPS est activé sur l'appareil
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // 2. Vérifier l'état de la permission
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Demander la permission si elle n'a jamais été accordée
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    // 4. Refus définitif — renvoyer l'utilisateur vers les paramètres système
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    // 5. Retourner la position avec précision haute
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calcule la distance en kilomètres entre deux coordonnées GPS.
  static double distanceEnKm(
    double latA, double lngA,
    double latB, double lngB,
  ) {
    double distanceEnMetres = Geolocator.distanceBetween(latA, lngA, latB, lngB);
    return distanceEnMetres / 1000;
  }
}
```

**Formule Haversine équivalente côté PHP (pour les APIs) :**
```php
function haversineDistance(float $lat1, float $lng1, float $lat2, float $lng2): float {
    $R = 6371; // Rayon Terre en km
    $dLat = deg2rad($lat2 - $lat1);
    $dLng = deg2rad($lng2 - $lng1);
    $a = sin($dLat/2)**2
       + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng/2)**2;
    return $R * 2 * atan2(sqrt($a), sqrt(1 - $a));
}
```

---

#### 🗺️ Intégration dans `CarteScreen`

**Comportement au chargement :**
1. Appel `LocationService.getCurrentPosition()` dans `initState()`
2. Si la position est obtenue → `mapController.move(LatLng(lat, lng), 13.0)` pour centrer la carte sur l'utilisateur
3. Ajout d'un marqueur bleu distinctif 📍 représentant la position de l'utilisateur dans le `MarkerLayer`
4. Si la permission est refusée → la carte se centre sur une position par défaut (ex: centre de la France : `LatLng(46.603354, 1.888334)`)

**Bouton « Me localiser » dans l'`AppBar` :**
- Icône `Icons.my_location`
- Au clic → rappelle `LocationService.getCurrentPosition()` et recentre la carte
- Si le GPS est désactivé → `SnackBar` informatif « Activez la géolocalisation dans vos paramètres »

```dart
// Exemple d'intégration dans initState
@override
void initState() {
  super.initState();
  _initLocation();
}

Future<void> _initLocation() async {
  final position = await LocationService.getCurrentPosition();
  if (position != null && mounted) {
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_userPosition!, 13.0);
  }
}
```

---

#### 📋 Intégration dans `AnnoncesScreen`

**Filtre « Autour de moi » :**
- `FilterChip` ou `Switch` « Autour de moi » dans la barre de filtres
- Activation → appel `LocationService.getCurrentPosition()`
- Si position obtenue → ajout des paramètres `lat`, `lng` et `rayon` (ex: 10 km par défaut) à la requête `GET api/search_biens.php?lat=X&lng=Y&rayon=10`
- Le backend PHP retourne les biens triés par distance croissante
- Chaque `BienCard` affiche la distance calculée : ex. « 2,4 km »

**Slider de rayon :**
- `Slider` de 1 à 50 km, valeur par défaut 10 km
- Affiché uniquement quand le filtre « Autour de moi » est actif
- Chaque modification du slider relance automatiquement l'appel API avec le nouveau rayon

```dart
// Calcul de la distance pour l'affichage sur chaque carte
final double distKm = LocationService.distanceEnKm(
  _userPosition!.latitude, _userPosition!.longitude,
  bien.latitude, bien.longitude,
);
// Affichage : "2,4 km" ou "< 1 km"
final String distLabel = distKm < 1
    ? '< 1 km'
    : '${distKm.toStringAsFixed(1)} km';
```

---

#### 📍 Intégration dans `PtsInteretDetailScreen`

- La distance entre la position de l'utilisateur et le POI est calculée via `LocationService.distanceEnKm()` et affichée sous l'adresse du POI (ex: « À 3,7 km de vous »)
- La liste des biens à proximité du POI est triée par distance croissante par rapport à l'utilisateur (si position disponible), sinon par distance par rapport au POI

---

#### 🔄 Gestion des états de permission

| État de permission | Comportement dans l'app |
|---|---|
| **Accordée** | Position GPS utilisée, carte centrée, distances affichées |
| **Refusée (première fois)** | `SnackBar` informatif « Activez la localisation pour voir les logements proches » — l'app fonctionne sans géolocalisation |
| **Refusée définitivement** | `AlertDialog` proposant d'ouvrir les paramètres système (`Geolocator.openAppSettings()`) |
| **GPS désactivé** | `SnackBar` « Le GPS est désactivé. Activez-le dans vos paramètres. » — Bouton « Ouvrir les paramètres » |
| **Timeout GPS** | Fallback silencieux sur la position par défaut — pas de blocage de l'UI |

---

#### 🔁 Mise à jour de la position en temps réel (optionnel)

Pour les sessions longues (utilisateur en déplacement), il est possible d'écouter les mises à jour de position en continu :

```dart
StreamSubscription<Position>? _positionStream;

void _startLocationTracking() {
  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // mise à jour tous les 50 mètres
    ),
  ).listen((Position position) {
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
    });
    // Mise à jour du marqueur utilisateur sur la carte
  });
}

@override
void dispose() {
  _positionStream?.cancel();
  super.dispose();
}
```

> ⚠️ **Note :** Le tracking continu consomme de la batterie. Il est recommandé de ne l'activer que sur `CarteScreen` et de le stopper dans `dispose()`.

---

#### 🧪 Tests géolocalisation

```
test/
└── geolocalisation/
    ├── location_service_test.dart   -- permission, GPS désactivé, fallback
    └── distance_calcul_test.dart    -- Haversine Flutter vs PHP
```

```dart
// test/geolocalisation/distance_calcul_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hap_mobile/services/location_service.dart';

void main() {
  group('LocationService — calcul de distance', () {
    test('Paris → Lyon ≈ 392 km', () {
      final dist = LocationService.distanceEnKm(
        48.8566, 2.3522,  // Paris
        45.7640, 4.8357,  // Lyon
      );
      expect(dist, closeTo(392.0, 5.0)); // ±5 km de tolérance
    });

    test('Même point → 0 km', () {
      final dist = LocationService.distanceEnKm(45.0, 5.0, 45.0, 5.0);
      expect(dist, equals(0.0));
    });
  });
}
```

---

### 7.11 Récapitulatif des adaptations mobiles

| Écran | Statut | Action requise |
|---|---|---|
| `LoginScreen` | ✅ | — |
| `InscriptionScreen` | ⚠️ | Persister l'état du `Stepper` 5 étapes avec Riverpod + `shared_preferences` |
| `ForgotPasswordScreen` | ✅ | — |
| `ResetPasswordScreen` | ✅ | — |
| `AccueilScreen` | ✅ | — |
| `AnnoncesScreen` | ⚠️ | Filtre « Autour de moi » + `Slider` rayon via `geolocator` |
| `DetailAnnonceScreen` | ⚠️ | `CustomScrollView` + `Slivers` + `BottomAppBar` pour les boutons d'action |
| `ReservationScreen` | ✅ | — |
| `CarteScreen` | ⚠️ | Centrage GPS + marqueur position utilisateur + bouton « Me localiser » |
| `PtsInteretDetailScreen` | ⚠️ | Affichage distance utilisateur ↔ POI via `geolocator` |
| `FavorisScreen` | ✅ | — |
| `AvisScreen` | ✅ | — |
| `ProfilScreen` | ⚠️ | `TabBar` 3 onglets (Infos / Réservations / Paramètres) + `ExpansionTile` |
| `SupportScreen` | ✅ | — |

---

### 7.12 Dépendances `pubspec.yaml` complètes

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Géolocalisation GPS
  geolocator: ^11.0.0

  # Carte OpenStreetMap
  flutter_map: ^6.0.0
  latlong2: ^0.9.0

  # Calendrier de disponibilité
  table_calendar: ^3.0.9

  # Images réseau avec cache
  cached_network_image: ^3.3.1

  # Notation étoiles
  flutter_rating_bar: ^4.0.1

  # Carrousel
  carousel_slider: ^4.2.1

  # Persistance locale
  shared_preferences: ^2.2.2

  # Gestion d'état
  flutter_riverpod: ^2.4.9   # ou provider: ^6.1.1 selon ton choix

  # HTTP
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

---

### 7.13 Structure des tests Flutter recommandée

```
test/
├── auth/
│   ├── login_test.dart             -- T1 à T7
│   ├── inscription_test.dart       -- T1 à T8 + persistance Stepper
│   └── forgot_password_test.dart   -- T1 à T3
├── annonces/
│   ├── search_biens_test.dart      -- filtres + géolocalisation
│   └── detail_annonce_test.dart    -- calendrier + calcul tarif
├── reservation/
│   └── reservation_test.dart       -- conflit de dates, calcul montant
├── profil/
│   └── profil_test.dart            -- onglets TabBar, historique
├── geolocalisation/
│   ├── location_service_test.dart  -- permission, GPS désactivé
│   └── distance_calcul_test.dart   -- Haversine
└── widget_test.dart                -- smoke test général
```
```