# README_AUTH — Système d'authentification JWT pour HAP Mobile

## Architecture choisie

| Aspect | Choix |
|---|---|
| Protocole | JWT (JSON Web Token) — RFC 7519 |
| Algorithme | HMAC-SHA256 (HS256) |
| Durée de validité | 30 jours (2 592 000 secondes) |
| Stockage côté client | `shared_preferences` (Flutter) |
| Invalidation | Blacklist optionnelle (`jwt_blacklist`) côté serveur |
| Dépendances PHP | Aucune — implémentation manuelle (Base64Url + `hash_hmac`) |
| Dépendances Flutter | `http`, `shared_preferences`, `go_router`, `provider` |

### Pourquoi JWT et pas les sessions PHP ?

Flutter est un client HTTP qui ne gère pas les cookies de session PHP. JWT est une solution stateless :
- Le token est signé côté serveur et stocké côté client
- Chaque requête envoie le token dans le header `Authorization: Bearer <token>`
- Le serveur vérifie la signature sans accéder à une session ou une BDD (sauf pour `auth_me`)

---

## Fichiers PHP à créer dans `Projet_SLAM`

> Ces fichiers se trouvent dans `php_api/` dans ce repo. Copiez-les dans :
> ```
> Projet_SLAM/Projet_HAP-House_After_Party--dev/Projet_HAP(House_After_Party)/
> ```

### Structure des fichiers PHP

```
Projet_HAP(House_After_Party)/
├── config/
│   └── jwt_config.php          ← Clé secrète, durée, algorithme
├── classes/
│   └── JWTHelper.php           ← Encode / Decode / Verify JWT
└── api/
    └── mobile/
        ├── auth_login.php      ← POST : connexion → JWT
        ├── auth_register.php   ← POST : inscription → JWT
        ├── auth_me.php         ← GET  : profil complet (avec JOIN Commune)
        └── auth_logout.php     ← POST : blacklist + { success: true }
```

### Correspondance `php_api/` → `Projet_SLAM`

| Fichier dans ce repo | Destination dans Projet_SLAM |
|---|---|
| `php_api/config/jwt_config.php` | `config/jwt_config.php` |
| `php_api/classes/JWTHelper.php` | `classes/JWTHelper.php` |
| `php_api/api/mobile/auth_login.php` | `api/mobile/auth_login.php` |
| `php_api/api/mobile/auth_register.php` | `api/mobile/auth_register.php` |
| `php_api/api/mobile/auth_me.php` | `api/mobile/auth_me.php` |
| `php_api/api/mobile/auth_logout.php` | `api/mobile/auth_logout.php` |

---

## Structure Flutter (`lib/`)

```
lib/
├── main.dart                        # MaterialApp.router + Provider + GoRouter
├── config/
│   └── api_config.dart              # URLs de tous les endpoints PHP
├── models/
│   └── user.dart                    # Modèle Locataire (fromJson / toJson)
├── services/
│   ├── api_service.dart             # Client HTTP générique (GET/POST + token auto)
│   └── auth_service.dart            # Login / Register / Logout / fetchMe
├── providers/
│   └── auth_provider.dart           # ChangeNotifier — état d'auth global
└── screens/
    ├── auth/
    │   ├── splash_screen.dart       # Vérif. session → redirection
    │   ├── login_screen.dart        # Formulaire de connexion
    │   └── register_screen.dart     # Formulaire d'inscription + autocomplete commune
    └── home_screen.dart             # Écran principal (après connexion)
```

---

## Flux complet d'authentification

```
┌─────────────────┐        POST /api/mobile/auth_login.php        ┌─────────────────┐
│   LoginScreen   │ ──────────────────────────────────────────────→│   PHP Backend   │
│  (Flutter)      │  { email, password }                           │  (Projet_SLAM)  │
│                 │                                                │                 │
│                 │ ←────────────────────────────────────────────── │                 │
│                 │  { success: true, token: "xxx.yyy.zzz",        │  password_verify│
│                 │    user: { id, nom, prenom, email, telephone } }│  + JWTHelper    │
└────────┬────────┘                                                └─────────────────┘
         │
         │ saveSession(token, user)
         ▼
┌─────────────────┐
│SharedPreferences│  auth_token = "xxx.yyy.zzz"
│  (Flutter)      │  auth_user  = { ... }
└────────┬────────┘
         │
         │ Requêtes suivantes
         ▼
┌─────────────────┐        GET /api/mobile/auth_me.php             ┌─────────────────┐
│  ApiService     │ ──────────────────────────────────────────────→│   PHP Backend   │
│  (Flutter)      │  Authorization: Bearer xxx.yyy.zzz             │                 │
│                 │ ←────────────────────────────────────────────── │  JWTHelper      │
│                 │  { success: true, user: { ... commune ... } }   │  ::decode()     │
└─────────────────┘                                                └─────────────────┘
```

---

## Tester en local

### Prérequis

1. Serveur PHP/MySQL démarré (ex. XAMPP, Laragon, Docker)
2. Base `Project_HAP` importée depuis `project_hap.sql`
3. Fichiers PHP copiés dans `Projet_SLAM`
4. Flutter installé (`flutter --version`)

### URL selon l'environnement

| Environnement | URL dans `lib/config/api_config.dart` |
|---|---|
| Émulateur Android | `http://10.0.2.2:8080` (10.0.2.2 = localhost hôte) |
| Simulateur iOS | `http://localhost:8080` |
| Appareil physique | IP locale de votre machine (ex. `http://192.168.1.42:8080`) |
| Production | `https://votre-domaine.fr` |

### Étapes

```bash
# 1. Modifier l'URL dans lib/config/api_config.dart selon votre environnement

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Lancer l'application (émulateur ou appareil connecté)
flutter run

# 4. Tester l'endpoint login directement (optionnel)
curl -X POST http://localhost:8080/Projet_HAP\(House_After_Party\)/api/mobile/auth_login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"motdepasse"}'
```

---

## Base de données — Séparation des droits

Le fichier `sql/create_users.sql` crée deux utilisateurs MySQL :

| Utilisateur | Application | Droits |
|---|---|---|
| `hap_web` | App web PHP (Projet_SLAM) | Accès complet (toutes tables) |
| `hap_mobile` | API mobile (endpoints JWT) | Accès restreint (pas Animateur, pas Archives) |

> ⚠️ **Une seule base** `Project_HAP` — les données sont partagées en temps réel entre les deux applications.

---

## Sécurité

- **JWT_SECRET** : changez la valeur dans `php_api/config/jwt_config.php` avant déploiement. Minimum 32 caractères aléatoires.
  ```bash
  openssl rand -base64 32
  ```
- **HTTPS** : en production, forcez HTTPS pour que les tokens JWT ne transitent pas en clair.
- **Blacklist** : `auth_logout.php` crée automatiquement la table `jwt_blacklist` si elle n'existe pas.
- **Mots de passe MySQL** : changez `ChangeMe_WebPassword_Fort!` et `ChangeMe_MobilePassword_Fort!` dans `sql/create_users.sql`.
