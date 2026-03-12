# Spécification Fonctionnelle – HapMobile (v2)

---

## 1. Introduction

L'application **HapMobile** est une transposition/adaptation mobile Flutter du projet web **Project HAP**.  
Son but principal : permettre à l'utilisateur de chercher, réserver et gérer des locations de biens, et d'accéder à des services communautaires (avis, favoris, support, blog, carte interactive…) dans une expérience fluide et optimisée sur mobile.

Elle interagit en HTTP avec le **backend PHP/MySQL partagé avec le projet web** (BDD commune + APIs communes), avec plusieurs adaptations pour garantir la persistance locale, la navigation mobile et l'exploitation du GPS natif.

> **Important :** L'application mobile ne dispose d'**aucun espace administration**. La gestion des contenus, utilisateurs et modération est entièrement réalisée depuis l'interface web (Project HAP). Le mobile est exclusivement un espace utilisateur final.

---

## 2. Rôles utilisateur (mobile)

| Rôle | Description |
|---|---|
| **Visiteur** | Non connecté. Peut consulter les annonces, la carte, les avis. Ne peut pas réserver, gérer des favoris ni laisser d'avis. |
| **Utilisateur connecté – Particulier** | Accès complet aux fonctionnalités réservation, favoris, avis, profil, support. |
| **Utilisateur connecté – Entreprise** | Identique au particulier ; formulaire d'inscription étendu (SIRET). |
| **Propriétaire de bien** | Peut consulter ses propres biens dans son profil. Pas de gestion de biens depuis le mobile (gérée côté web). |

> Il n'existe **aucun rôle administrateur** côté mobile. Tout affichage conditionnel repose sur l'état **connecté / non connecté** et, secondairement, sur le type de compte (particulier / entreprise / propriétaire).

---

## 3. Parcours utilisateur & modules

### 3.1 Authentification

#### a) LoginScreen
- **Ouverture :** Formulaire email / mot de passe, bouton « Se connecter », liens « S'inscrire » & « Mot de passe oublié ? »
- **Saisie & clic « Se connecter » :**
  - Vérifie les champs (vide, email valide, longueur MDP)
  - Désactive le bouton, affiche un loader
  - Envoi POST à `api/login.php` (avec token CSRF)
  - Si 5 tentatives échouées : message *"Trop de tentatives, réessayez dans 15mn"*
  - Si succès : stocke le token/session localement (`shared_preferences`), redirige vers l'écran précédent ou Accueil
  - Si erreur : affiche une Snackbar contextuelle (jamais d'indice sur email inexistant / MDP incorrect pour éviter l'énumération)
  - Si token expiré en cours de session : déconnexion automatique silencieuse + redirection LoginScreen + message *"Votre session a expiré, veuillez vous reconnecter"*
- **Comportements automatiques :**
  - Si déjà connecté : redirige sur Accueil
  - Regénère automatiquement l'ID session lors de la connexion

#### b) InscriptionScreen
- **Formulaire en 5 étapes (Stepper)**
- À chaque clic "Suivant" : valide localement les champs de l'étape, persiste l'état (Riverpod + `shared_preferences`)
- Si l'app passe en arrière-plan, tout l'état est restauré au retour
- **Étapes :**
  - Step 1 : Choix persona (Particulier / Entreprise)
  - Step 2 : Informations personnelles, vérification majorité (date de naissance)
  - Step 3 : Adresse autocomplete (API publique) – suggestions au fil de la saisie, clic → préremplit les champs
  - Step 4 *(si Entreprise uniquement)* : Entrée SIRET + bouton « Vérifier » (contrôle Luhn)
  - Step 5 : Mot de passe (min 8 caractères, maj, min, chiffre, spécial — validé en local ET côté serveur), RGPD à cocher, captcha mathématique
- **Clic "Valider" :**
  - POST à `api/register.php` (form-data, token CSRF), loader + désactivation des champs
  - Succès : Snackbar + redirection LoginScreen + suppression état temporaire
  - Erreur : message explicite si contrainte unique (ex : email déjà utilisé), générique sinon
- En cas de retour arrière dans le stepper, l'état saisi doit être conservé
- L'app doit empêcher la perte de données en cas de crash / app kill / rotation écran

#### c) ForgotPasswordScreen
- Champ email + bouton "Envoyer"
- Validation format email en local → POST API → loader
- Affichage : *"Si ce mail existe, un lien de réinitialisation vous a été envoyé"*
- En environnement dev (XAMPP) : lien affiché directement
- Redirige vers ResetPasswordScreen si succès & clic

#### d) ResetPasswordScreen
- Deux champs mot de passe + confirmation
- Validation Flutter avant API (longueur / correspondance)
- POST à `api/reset_password.php` (avec token)
- Affichage succès ou erreur (expiré, mal formaté, déjà utilisé, etc.)

---

### 3.2 Accueil (AccueilScreen)
- Affichage dynamique selon état de connexion (connecté / non connecté)
- Hero Banner avec slogan
- Boutons CTA : « Voir les logements » → AnnoncesScreen, « Événements proches » → EvenementsScreen
- Carrousel d'annonces mises en avant : clic → DetailAnnonceScreen
- Message de bienvenue avec prénom si connecté
- Menu de navigation global (bottom nav ou drawer selon layout adaptatif)
- Switch thème clair/sombre (persistance via `shared_preferences`)
- Bouton déconnexion / connexion toujours visible dans AppBar

---

### 3.3 Recherche et annonces (AnnoncesScreen)
- **Affichage :** Liste/grid des biens (photos, titre, prix/nuit, type, distance si géolocalisation active)
- **Filtres :**
  - Prix min/max (slider)
  - Capacité (picker)
  - Type de bien (chips)
  - Commune (autocomplete, requête dès 2 caractères)
  - « Autour de moi » (switch — demande permission GPS native, fallback si refus)
  - Rayon (slider, visible uniquement si « Autour de moi » actif)
- **Interactions :**
  - Chaque modification relance la recherche (debounce 300ms)
  - Clic sur un bien → DetailAnnonceScreen
  - Bouton cœur sur chaque bien : toggle favori (POST/DELETE API), retour immédiat UI + feedback snackbar
  - Barre de recherche textuelle avec autocomplete et suggestions

---

### 3.4 Détail annonce (DetailAnnonceScreen)
- PageView d'images (swipe)
- Section complète : titre, description, équipements, type, capacité, adresse, POI proches, commune
- Prix/nuit + mini résumé du tarif (base, modificateurs saisonniers)
- Calendrier (`TableCalendar`) : choix date début + fin, jours indisponibles grisés, semaines bloquées colorées
- Mise à jour du tarif dynamique à chaque sélection (recalcul : jours × tarif, haute saison prise en compte, callback API si besoin)
- Section « Avis » : 3 premiers affichés + bouton « Voir tous les avis » → AvisScreen
- **BottomAppBar fixe :** « Ajouter / Retirer des favoris » + « Réserver »
  - Réserver : si non connecté → redirection login avec message contextuel, sinon → ReservationScreen
- Responsive, tout le contenu scrollable via `CustomScrollView` (Slivers)
- Distance à l'utilisateur affichée si géolocalisation active
- Bouton **Partager** : permet de partager le lien de l'annonce via les options natives du système (share_plus)

---

### 3.5 Réservation (ReservationScreen)
- Récapitulatif : logement, photos, calendrier sélectionné, prix calculé, dates choisies
- Formulaire : dates pré-remplies si passées depuis DetailAnnonceScreen, bouton « Valider »
- Appel API check/insert réservation (dates vérouillées côté serveur, montant recalculé côté PHP — double contrôle)
- Succès : snackbar *"Réservation créée"* + redirection Profil onglet Historique
- Conflit : message d'erreur + calendrier surlignant les dates indisponibles

---

### 3.6 Carte interactive (CarteScreen)
- Chargement des biens et POI avec coordonnées, affichage des marqueurs sur carte OSM (`flutter_map` + `latlong2`)
- Marqueurs différenciés par type ; clic → BottomSheet fiche résumée + bouton naviguer
- Si permission GPS active : centrage sur auto-position + bouton « Me localiser » recalcule et recadre ; fallback centre France si refus
- Marqueur personnalisé bleu pour la position utilisateur
- Clic POI : mini-fiche + bouton → détail POI
- Clic bien : fiche + bouton → DetailAnnonceScreen

---

### 3.7 Favoris (FavorisScreen)
- Liste grid des biens favoris (utilisateur connecté uniquement)
- Image, titre, prix/nuit, commune, note
- Bouton cœur pour retirer le favori (feedback immédiat)
- Clic → DetailAnnonceScreen
- Message explicite si liste vide
- Accès restreint : redirection vers LoginScreen si visiteur non connecté

---

### 3.8 Avis (AvisScreen)
- Liste des avis publiés : nom auteur, bien concerné, note, commentaire, date
- Filtres : par bien, par note minimale ; pagination scroll infini (20 par page)
- Bouton « Laisser un avis » (connecté uniquement) → bottom sheet ou nouvelle page
  - Sélection du bien parmi ceux déjà réservés (récupérés via API)
  - Notation étoiles + commentaire libre
  - Envoi POST API + feedback immédiat *"En attente de modération"*
- Message explicite si aucun avis
- Clic sur un bien → DetailAnnonceScreen

---

### 3.9 Blog (BlogScreen)
- Liste des articles publiés : titre, image de couverture, résumé, date, auteur
- Pagination (scroll infini ou bouton « Charger plus »)
- Clic sur un article → DetailArticleScreen :
  - Contenu complet de l'article (texte, images)
  - Bouton partager (share_plus)
  - Lien vers les annonces liées si référencées dans l'article
- Lecture seule : aucune création/modification d'article depuis le mobile (géré côté web admin)

---

### 3.10 Événements (EvenementsScreen)
- Liste des événements à venir : titre, date, lieu, description courte, image
- Filtres : par date, par commune
- Clic → DetailEvenementScreen :
  - Informations complètes (description, lieu, date, organisateur)
  - Carte mini avec marqueur de l'événement
  - Bouton partager (share_plus)
- Lecture seule : aucune création depuis le mobile

---

### 3.11 Profil utilisateur (ProfilScreen)
- **TabBar 3 onglets :**
  - **Infos & modification :** données éditables + bouton « Enregistrer » ; RGPD à cocher à chaque modification ; changement mot de passe (ancien + nouveau + confirmation)
  - **Historique réservations :** listview avec statut, possibilité d'annuler si statut *"en attente"* ; feedback couleur par statut sur les Cards
  - **Paramètres :** switch thème, bouton déconnexion
- Clic « Déconnexion » : flush `shared_preferences` / token, redirection LoginScreen
- Accès restreint : redirection LoginScreen si visiteur

---

### 3.12 Support (SupportScreen)
- Formulaire : type (dropdown), sujet (texte court), message, priorité (dropdown/boutons), page concernée (texte)
- Pré-remplissage nom/email si connecté
- Validation : tous les champs requis, email valide ; feedback escaladé sur priorité urgente
- Clic « Soumettre » : POST API → succès → affiche numéro de ticket + snackbar

---

### 3.13 Notifications (NotificationsScreen)
- Affichage des notifications reçues par l'utilisateur connecté : confirmation réservation, rappel, réponse support, etc.
- Badge sur l'icône de navigation indiquant le nombre de notifications non lues
- Clic sur une notification → redirige vers l'écran concerné (réservation, support, annonce)
- Bouton « Tout marquer comme lu »
- Implémentation : push notifications via FCM (Firebase Cloud Messaging) pour Android/iOS ; stockage des notifications en BDD, récupérées également via API pour les utilisateurs sans push actif
- Gestion de la permission de notifications (Android 13+ / iOS) : demande explicite au premier lancement après connexion

---

### 3.14 Géolocalisation (service transverse – LocationService)
- Appelé sur CarteScreen, AnnoncesScreen (filtre « Autour de moi »), DetailAnnonceScreen, EvenementsScreen
- Gestion permission / timeout : Snackbar ou AlertDialog selon le cas
- Mode tracking optionnel sur CarteScreen (mise à jour du marqueur en cas de déplacement, limité pour la batterie)
- Toute distance affichée = calculée Flutter (UI) et côté backend (tri SQL / formule Haversine)
- **Les coordonnées utilisateur ne sont jamais sauvegardées en BDD** — tout est local et éphémère

---

## 4. Scénarios & interactions notables

- Tous les boutons principaux affichent un feedback visuel au clic (snackbar, loader, désactivation)
- Transferts inter-écrans via `Navigator push/pop` avec passage de paramètres si besoin
- Persistance des états multi-étapes (Riverpod + `shared_preferences`) : aucune perte de données en cas de crash / background / app kill
- **Gestion des erreurs réseau :** toute erreur HTTP, timeout ou parsing est interceptée → feedback GUI adapté (snackbar/alert) + proposition de relancer
- **Expiration de session :** interceptée de manière transparente → déconnexion automatique + redirection LoginScreen avec message explicite
- **Partage natif** (share_plus) disponible sur : DetailAnnonceScreen, DetailArticleScreen, DetailEvenementScreen

---

## 5. Tests – Critères d'acceptation

Chaque module doit disposer de tests automatisés côté Flutter (`test/`), validés à chaque mise à jour. Les identifiants de tests (T1, T2…) sont détaillés dans le README du projet.

---

## 6. Adaptations & évolutions (backlog & issues)

Issues GitHub actuellement ouvertes à intégrer :

| Issue | Titre | Statut |
|---|---|---|
| #7 | Phase 4 — Profil & Réservations | En cours |
| #8 | Phase 5 — Carte & Événements | En cours |
| #9 | Phase 6 — Navigation & Finitions | En cours |
| #10 | Phase 7 — Implémentation des notifications | Planifié |
| #11 | Photo (gestion photos profil / bien ?) | À préciser |
| #12 | Ajouter une option pour partager | Intégré dans spec (section 3.4, 3.9, 3.10) |

---

## 7. Dépendances Flutter & intégrations tierces

| Paquet | Usage |
|---|---|
| `geolocator` | Géolocalisation GPS |
| `flutter_map` + `latlong2` | Carte OSM interactive |
| `flutter_riverpod` | Gestion d'état globale |
| `cached_network_image` | Chargement images optimisé |
| `carousel_slider` | Carrousel accueil |
| `table_calendar` | Calendrier réservation |
| `flutter_rating_bar` | Notation étoiles |
| `shared_preferences` | Persistance locale (token, thème, état formulaires) |
| `http` | Appels API REST |
| `share_plus` | Partage natif |
| `firebase_messaging` | Notifications push (FCM) |

- Permissions Android/iOS pour GPS et notifications définies dans le projet (voir README)
- APIs externes (autocomplete adresses, SIRET/SIREN) appelées directement côté Flutter, résultats validés en local avant envoi au back
- La BDD et les APIs sont **partagées avec le projet web** (Project HAP) — tout accès mobile passe par les mêmes endpoints PHP
