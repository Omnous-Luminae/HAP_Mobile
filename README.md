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
  - Admin : + Dashboard Admin
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
- Liste des avis publiés (validés par l'admin) avec note ⭐ (1 à 5), commentaire, date, auteur
- Filtres : par bien, par note minimale
- Pagination de la liste
- **Soumission d'un avis** (utilisateur connecté uniquement) :
  - Sélection du bien concerné parmi les biens réservés par l'utilisateur
  - Note de 1 à 5 étoiles (`RatingBar`)
  - Commentaire libre
  - Les avis soumis sont **en attente de validation admin** avant publication
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

### 7.10 Dashboard Admin

#### 🛡️ `AdminDashboardScreen` (`apropos.php` + `forms/dashboard.php`)

**Fonctionnalités :**
- **Accès restreint** au rôle Administrateur (rôle `animateur` côté PHP), vérification côté serveur à chaque requête
- Statistiques globales en cards :
  - Nombre d'utilisateurs inscrits
  - Nombre de réservations (totales / en cours / archivées)
  - Nombre d'avis (publiés / en attente de validation)
  - Nombre de tickets support (ouverts / en cours / fermés)
- Navigation rapide vers tous les sous-modules de gestion

**API :** `GET api/dashboard_stats.php`

**Statut mobile :** ✅ Nativement adapté (StatCards = widgets mobiles natifs)

---

#### 🏠 `GestionBiensScreen` (`forms/Bien.form.php`)

**Fonctionnalités :**
- Liste complète de tous les biens (validés et en attente)
- **CRUD complet** : créer, afficher, modifier, supprimer un bien
- Champs : titre, description, prix/nuit, capacité, type de bien, adresse (autocomplete `adresse.data.gouv.fr`), coordonnées GPS, photos
- Upload multi-photos (ajout dynamique de lignes de photo)
- Liaison aux prestations (`Compose.form.php`) et points d'intérêt (`Dispose.form.php`)
- Filtre par statut (validé / en attente)

**API :** `GET/POST/PUT/DELETE api/bien.php`

**Statut mobile :** ⚠️ Adaptation requise

> **Plan d'adaptation — `GestionBiensScreen` (upload photos) :**
>  
> **Problème :** L'upload multi-photos via input HTML n'existe pas en Flutter. Il faut utiliser `image_picker` pour accéder à la galerie ou la caméra du téléphone.
>  
> **Solution :**
> - Ajouter la dépendance dans `pubspec.yaml` :
>   ```yaml
>   image_picker: ^1.0.7
>   ```
> - Ajouter les permissions Android dans `android/app/src/main/AndroidManifest.xml` :
>   ```xml
>   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
>   <uses-permission android:name="android.permission.CAMERA"/>
>   ```
> - Implémenter le sélecteur de photos :
>   ```dart
>   final ImagePicker picker = ImagePicker();
>   final List<XFile> images = await picker.pickMultiImage();
>   ```
> - Afficher les photos sélectionnées dans un `Wrap` de miniatures avec bouton de suppression individuel
> - Envoyer les photos au backend PHP via `multipart/form-data` avec `dio` :
>   ```dart
>   FormData formData = FormData.fromMap({
>     'photos': images.map((img) => MultipartFile.fromFileSync(img.path)).toList(),
>   });
>   await dio.post('$baseUrl/bien.php', data: formData);
>   ```

---

#### ✅ `ValidationBiensScreen` (`forms/validate_biens.php`)

**Fonctionnalités :**
- Liste des biens en attente de validation soumis par des propriétaires
- Aperçu complet du bien (photos, description, adresse, prix)
- Actions : **Valider** (publier) ou **Refuser** (avec motif)
- Notification au propriétaire après décision

**API :** `POST api/validate_biens.php`

**Statut mobile :** ✅ Nativement adapté

---

#### ⭐ `ValidationAvisScreen` (`forms/validate_reviews.php`)

**Fonctionnalités :**
- Liste des avis en attente de modération
- Affichage : auteur, note ⭐, commentaire, date, bien concerné
- Actions : **Valider** (publier l'avis) ou **Refuser** (supprimer l'avis)

**API :** `POST api/validate_reviews.php`

**Statut mobile :** ✅ Nativement adapté

---

#### 👥 `GestionUsersScreen` (`forms/Locataires.form.php`)

**Fonctionnalités :**
- Liste paginée de tous les utilisateurs
- **CRUD complet** : créer, modifier, supprimer un utilisateur
- Bascule type de compte : **particulier** (nom, prénom, email, téléphone, date de naissance, adresse) / **entreprise** (SIRET, raison sociale)
- Validation SIREN avec algorithme de Luhn
- Vérification de la majorité (18+ ans) à la création
- Recherche par nom, prénom ou email (`api/search_locataires.php`)
- Modification de l'état du compte (actif / bloqué)
- Modal d'édition avec tous les champs pré-remplis

**Widgets :** `DataTable`, `AlertDialog`, `DropdownButton`  
**API :** `GET api/search_locataires.php`, `GET/POST/PUT/DELETE api/locataire.php`

**Statut mobile :** ⚠️ Adaptation requise

> **Plan d'adaptation — `GestionUsersScreen` (DataTable non responsive) :**
>  
> **Problème :** `DataTable` Flutter ne s'adapte pas automatiquement aux petits écrans — les colonnes débordent sur mobile.
>  
> **Solution — remplacer `DataTable` par des `Card` en `ListView` :**
> ```dart
> ListView.builder(
>   itemCount: users.length,
>   itemBuilder: (context, index) {
>     final user = users[index];
>     return Card(
>       child: ListTile(
>         leading: CircleAvatar(child: Text(user.prenom[0])),
>         title: Text('${user.prenom} ${user.nom}'),
>         subtitle: Text(user.email),
>         trailing: PopupMenuButton(items: [
>           PopupMenuItem(value: 'edit', child: Text('Modifier')),  
>           PopupMenuItem(value: 'block', child: Text('Bloquer')),  
>           PopupMenuItem(value: 'delete', child: Text('Supprimer')),  
>         ]),
>       ),
>     );
>   },
> )
> ```
> - La recherche reste accessible via une `SearchBar` en haut de l'écran
> - L'édition s'ouvre dans un `AlertDialog` ou une `BottomSheet` avec les champs pré-remplis
> - Le filtre actif/bloqué se fait via des `FilterChip` en haut de liste

---

#### 📋 `GestionReservationsScreen` (`forms/Reservation.form.php`)

**Fonctionnalités :**
- Vue globale de toutes les réservations (tous utilisateurs)
- **Filtres** : nom de bien, date de début, date de fin, nombre minimum de réservations, statut
- Modification du statut d'une réservation (en attente → confirmée → annulée → archivée)
- Calcul et affichage du montant total
- Navigation vers l'historique par utilisateur

**API :** `GET api/get_reservations.php`, `PUT api/update_reservation.php`

**Statut mobile :** ⚠️ Adaptation requise

> **Plan d'adaptation — `GestionReservationsScreen` (DataTable non responsive) :**
>  
> **Problème :** Même problème que `GestionUsersScreen` — `DataTable` ou `FilteredDataTable` avec de nombreuses colonnes n'est pas adapté au mobile.
>  
> **Solution — Cards avec statut coloré :**
> ```dart
> Card(
>   color: _statutColor(reservation.statut), // vert/orange/rouge/gris
>   child: ListTile(
>     title: Text(reservation.nomBien),
>     subtitle: Text('${reservation.dateDebut} → ${reservation.dateFin}'),
>     trailing: Column(children: [
>       Text('${reservation.montant}€'),
>       DropdownButton<String>(
>         value: reservation.statut,
>         items: ['en_attente','confirmee','annulee','archivee']
>           .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
>         onChanged: (val) => _updateStatut(reservation.id, val),
>       ),
>     ]),
>   ),
> )
> ```
> - Les filtres sont accessibles via un `BottomSheet` ou un panneau `ExpansionTile` repliable en haut
> - Utiliser des `FilterChip` horizontaux scrollables pour les filtres de statut

---

#### 🎉 `GestionEvenementsScreen` (`forms/Evenement.form.php`)

**Fonctionnalités :**
- **CRUD complet** des événements (concerts, festivals, soirées…)
- Champs : nom, type d'événement, date, adresse, description
- **CRUD des types d'événements** (`forms/TypeEvenement.form.php`)
- Liaison des événements aux points d'intérêt

**API :** `GET/POST/PUT/DELETE api/evenement.php`

**Statut mobile :** ✅ Nativement adapté (CRUD ListView)

---

#### 📍 `GestionPtsInteretScreen` (`forms/PtsInteret.form.php`)

**Fonctionnalités :**
- **CRUD complet** des points d'intérêt (clubs, bars, restaurants…)
- Champs : nom, type de POI, adresse, coordonnées GPS (latitude/longitude)
- **CRUD des types de POI** (`forms/TypePtsInteret.form.php`)
- Liaison POI ↔ biens (`forms/Dispose.form.php`)
- Aperçu sur carte intégrée

**API :** `GET api/get_poi.php`, `GET/POST/PUT/DELETE api/pts_interet.php`

**Statut mobile :** ✅ Nativement adapté

---

#### 💰 `GestionTarifsScreen` (`forms/Tarif.form.php` + `forms/manage_tarifs.php`)

**Fonctionnalités :**
- **CRUD des tarifs** associés à un bien :
  - Tarif de base par nuit
  - Modificateur de prix par saison (multiplicateur, ex: 1.5 pour +50%)
  - Semaines spéciales (prix fixe ou multiplicateur)
- Visualisation du calendrier tarifaire par bien

**API :** `GET api/get_tarifs_week.php`, `GET/POST/PUT/DELETE api/tarif.php`

**Statut mobile :** ⚠️ Adaptation recommandée

> **Plan d'adaptation — `GestionTarifsScreen` (DataTable tarifaire) :**
>  
> **Problème :** Le tableau des tarifs par semaine/saison est typiquement représenté sous forme de grille, peu lisible sur mobile.
>  
> **Solution :**
> - Remplacer le tableau par une liste de `Card` par saison/période avec les champs modificateurs éditables inline
> - Pour la visualisation calendaire, utiliser `TableCalendar` en lecture seule avec des marqueurs colorés par niveau de prix
> - Formulaire d'ajout de tarif dans un `BottomSheet` ou `AlertDialog`

---

#### 📆 `GestionSaisonsScreen` (`forms/Saison.form.php`)

**Fonctionnalités :**
- **CRUD des saisons tarifaires** par bien
- Champs : nom de la saison (ex: « Été 2026 »), date de début, date de fin, modificateur de prix
- Vérification de la cohérence des dates (pas de chevauchement)

**API :** `GET/POST/PUT/DELETE api/saison.php`

**Statut mobile :** ✅ Nativement adapté (CRUD ListView)

---

#### 🛋️ `GestionPrestationsScreen` (`forms/Prestation.form.php` + `forms/Compose.form.php`)

**Fonctionnalités :**
- **CRUD des prestations** (Wi-Fi, parking, piscine, cuisine équipée…)
- Liaison prestation ↔ bien (`Compose.form.php`) : ajouter/retirer des équipements à un bien
- Recherche de prestations disponibles (`api/search_composition.php`)

**API :** `GET api/search_composition.php`, `GET/POST/DELETE api/prestation.php`

**Statut mobile :** ✅ Nativement adapté

---

#### 🏘️ `GestionCommunesScreen` (`forms/Commune.form.php`)

**Fonctionnalités :**
- **CRUD des communes** référencées dans l'application
- Champs : nom, code INSEE, département
- Utilisé pour le filtre de recherche des biens et l'autocomplete d'adresse
- Intégration API `api/get_commune_by_insee.php`

**API :** `GET api/get_commune_by_insee.php`, `GET api/search_communes.php`

**Statut mobile :** ✅ Nativement adapté

---

#### 📦 `ArchivesScreen` (`forms/manage_archives.php`)

**Fonctionnalités :**
- Liste des réservations archivées (statut `archivée`)
- Filtres : bien, utilisateur, période de dates
- Affichage détaillé : bien réservé, locataire, dates, montant, date d'archivage
- Consultation des détails via `api/get_archive_details.php`
- Export possible (à implémenter)

**API :** `GET api/get_archive_details.php`

**Statut mobile :** ✅ Nativement adapté

---

#### 📬 `GestionContactsScreen` (`forms/manage_contacts.php`)

**Fonctionnalités :**
- Liste de tous les tickets support soumis par les utilisateurs
- **Filtres** : par statut (ouvert / en cours / fermé), par priorité, par type
- Affichage : sujet, message, priorité, page concernée, date de soumission, auteur
- **Réponse de l'admin** : champ de texte pour rédiger une réponse
- Changement de statut du ticket (ouvert → en cours → fermé)
- Mise en évidence des tickets urgents / haute priorité

**API :** `GET/POST api/manage_contacts.php`

**Statut mobile :** ✅ Nativement adapté

---

### 7.11 Récapitulatif des adaptations mobiles

| Écran | Statut | Action requise |
|---|---|---|
| `LoginScreen` | ✅ | — |
| `InscriptionScreen` | ⚠️ | Persister l'état du `Stepper` 5 étapes avec Riverpod + `shared_preferences` |
| `ForgotPasswordScreen` | ✅ | — |
| `ResetPasswordScreen` | ✅ | — |
| `AccueilScreen` | ✅ | — |
| `AnnoncesScreen` | ✅ | — |
| `DetailAnnonceScreen` | ⚠️ | `CustomScrollView` + `Slivers` + `BottomAppBar` pour les boutons d'action |
| `ReservationScreen` | ✅ | — |
| `CarteScreen` | ✅ | — |
| `PtsInteretDetailScreen` | ✅ | — |
| `FavorisScreen` | ✅ | — |
| `AvisScreen` | ✅ | — |
| `ProfilScreen` | ⚠️ | `TabBar` 3 onglets (Infos / Réservations / Paramètres) + `ExpansionTile` |
| `SupportScreen` | ✅ | — |
| `AdminDashboardScreen` | ✅ | — |
| `GestionBiensScreen` | ⚠️ | `image_picker` pour l'upload photos + permissions Android |
| `ValidationBiensScreen` | ✅ | — |
| `ValidationAvisScreen` | ✅ | — |
| `GestionUsersScreen` | ⚠️ | Remplacer `DataTable` par `ListView` de `Card` + `PopupMenu` |
| `GestionReservationsScreen` | ⚠️ | Remplacer `DataTable` par `Card` colorées + `DropdownButton` statut |
| `GestionEvenementsScreen` | ✅ | — |
| `GestionPtsInteretScreen` | ✅ | — |
| `GestionTarifsScreen` | ⚠️ | Remplacer tableau tarifs par `Card` + `TableCalendar` en lecture seule |
| `GestionSaisonsScreen` | ✅ | — |
| `GestionPrestationsScreen` | ✅ | — |
| `GestionCommunesScreen` | ✅ | — |
| `ArchivesScreen` | ✅ | — |
| `GestionContactsScreen` | ✅ | — |

**Dépendances à ajouter dans `pubspec.yaml` suite aux adaptations :**
```yaml
image_picker: ^1.0.7   # Upload photos dans GestionBiensScreen
```
