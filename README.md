## 7. Modules & Écrans Flutter

> 🔍 **Légende des adaptations mobiles** :  
> ✅ Aucune adaptation nécessaire — le widget est nativement mobile  
> ⚠️ Adaptation recommandée — plan détaillé fourni ci-dessous  
> 🔧 Ajout requis — dépendance ou logique manquante à implémenter

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

---

#### ���� `ResetPasswordScreen` (`auth/reset_password.php`)

**Fonctionnalités :**
- Saisie du nouveau mot de passe + confirmation
- Validation : longueur min. 8 caractères, correspondance des deux champs
- Vérification du token côté PHP (SHA-256, expiration 1h)
- Hash bcrypt du nouveau mot de passe côté PHP
- Suppression du token après utilisation
- Message de succès + redirection vers `LoginScreen`

**API :** `POST api/reset_password.php`

**Statut mobile :** ✅ Nativement adapté

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
> **Problème :** Cet écran cumule galerie + calendrier + calcul de tarif + avis + boutons d'action. Sur mobile, tout ne peut pas être visible sans scroll — il faut éviter les widgets figés[...]
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
> **Problème :** L'écran regroupe : infos personnelles + changement de MDP + historique réservations + switch thème + déconnexion. C'est trop de contenu pour un seul écran mobile sans struc[...]
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

---

#### 📦 Dépendance Flutter

Ajouter dans `pubspec.yaml` :
```yaml
gEolocator: ^11.0.0        # Accès GPS natif Android & iOS
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

**Dépendances à ajouter dans `pubspec.yaml` suite aux adaptations :**
```yaml
géolocator: ^11.0.0    # Géolocalisation GPS dans CarteScreen, AnnoncesScreen, PtsInteretDetailScreen
```
