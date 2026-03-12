1. Introduction
L’application HapMobile est une transposition/adaptation mobile Flutter du projet web « Project HAP ».
Son but principal : permettre à l’utilisateur de chercher, réserver et gérer des locations de biens et d'accéder à des services communautaires (avis, favoris, support, blog, carte interactive…) dans une expérience fluide et optimisée sur mobile.

Elle interagit en HTTP avec le backend PHP/MySQL (APIs existantes + logicielle métier du projet web), avec plusieurs adaptations pour garantir la persistance locale, la navigation mobile et l'exploitation du GPS natif.

2. Parcours utilisateur & modules
2.1 Authentification
a) LoginScreen
Ouverture : Formulaire email / mot de passe, bouton « Se connecter », liens « S’inscrire » & « Mot de passe oublié ? »
Saisie & clic « Se connecter » :
Vérifie les champs (vide, email valide, longueur MDP)
Désactive le bouton, affiche un loader
Envoi POST à api/login.php (avec token CSRF)
Si 5 tentatives échouées : message “Trop de tentatives, réessayez dans 15mn”
Si succès : stocke le token/session localement (shared_preferences), redirige vers l’écran précédent ou Accueil
Si erreur : affiche une Snackbar contextuelle (mais jamais d’indice pour email inexistant/MDP incorrect pour éviter l’énumération)
Clic « S’inscrire » : Navigation vers InscriptionScreen
Clic « Mot de passe oublié » : Ouvre ForgotPasswordScreen
**Comportements automatiques **:
Si déjà connecté : redirige sur Accueil
Regénère automatiquement l’ID session lors de la connexion
b) InscriptionScreen
Formulaire en 5 étapes (Stepper)
À chaque clic “Suivant” :
Valide localement le ou les champs de l’étape
Persiste tous les champs dans un model d’état (Riverpod ou Provider + shared_preferences)
Si l’app passe en arrière-plan, tout l’état doit être restauré au retour
À chaque step :
Step 1 : choix persona (particulier/entreprise)
Step 2 : Informations persos, vérifie majorité (date de naissance)
Step 3 : Adresse autocomplete (API publique) – Suggestions affichées au fil de la saisie, clic => préremplit automatiquement les champs
Step 4 (si entreprise) : Entrée SIRET + bouton « vérifier » (contrôle Luhn)
Step 5 : Mot de passe (local et server-side : min 8 caractères, maj, min, chiffre, spécial), RGPD à cocher, captcha mathématique
Clic “Valider” :
POST à api/register.php (form-data, token CSRF)
Loader + désactivation des champs
Affichage du succès/échec :
Succès : Snackbar + redirige auto vers LoginScreen, supprime l’état temporaire
Erreur : message explicite si unique, générique sinon
En cas de retour à une étape antérieure puis retour à l’avant, l’état saisi DOIT être conservé
L’app doit empêcher la perte de données en cas de crash/app kill/rotation écran.
c) ForgotPasswordScreen
Champ email, bouton “Envoyer”
Saisie e-mail → vérifie format localement
POST API, loader
Affichage: "Si ce mail existe, un lien de réinitialisation vous a été envoyé"
En local (dev : XAMPP), lien affiché directement
Redirige vers ResetPasswordScreen si succès & clic
d) ResetPasswordScreen
Deux champs mot de passe + confirmation, validation côté Flutter (avant API) sur longueur/correspondance
Bouton “Réinitialiser”
POST à api/reset_password.php (avec token)
Affichage succès ou erreur (expiré, mal formaté, déjà utilisé, etc.)

2.2 Accueil (AccueilScreen)
Affichage dynamique des modules selon connexion/permissions/rôle utilisateur
Hero Banner avec slogan
Boutons CTA : « Voir les logements » (va à AnnoncesScreen), « Evénements proches » (va à EvenementsScreen)
Carrousel d’annonces mises en avant : clic => DetailAnnonceScreen
Personnalisation : message de bienvenue prénom utilisateur si connecté
Menu de navigation global (bottom nav ou drawer selon layout/adaptatif)
Switch thème clair/sombre (et persistance via shared_preferences)
Bouton déconnexion/connexion toujours visible dans AppBar

2.3 Recherche et annonces (AnnoncesScreen)
Affichage : Liste/grid des biens (photos, titre, prix/nuit, type, distance si géolocalisation)
Filtres en haut :
Prix min/max (slider)
Capacité (picker)
Type de bien (chips)
Commune (autocomplete, requête dès 2 caractères)
“Autour de moi” (Switch Filter : si actif, demande permission GPS native, sinon fallback)
Rayon (slider, visible si Autour de moi actif)
Interaction :
Chaque modification relance la recherche (debounce 300ms)
Clic sur un bien : ouvre DetailAnnonceScreen
Bouton cœur sur chaque bien : toggle favori (POST/DELETE API), retour immédiat UI, feedback snackbar
Recherche textuelle : champ SearchBar, propose autocomplete et suggestions

2.4 Détail annonce (DetailAnnonceScreen)
PageView d’images (swipe)
Section complète : titre, description, équipements, type, capacité, adresse (proche POI, commune)
Prix/nuit, mini résumé du tarif (base, modificateurs saisonniers)
Calendrier (TableCalendar) : choisit date début+fin, grise les jours absents/dispos, semaines bloquées colorées
Choix plage date met à jour tarif dynamique (recalcul : jours × tarif, tient compte prix haute saison, callback API si besoin)
Section « avis » : 3 premiers affichés, bouton « Voir tous les avis » qui ouvre AvisScreen
Boutons fixes (BottomAppBar ): “Ajouter/Retirer aux favoris”, “Réserver”
Réserver : Si non connecté, redirige login avec message contextuel, sinon ouvre ReservationScreen
Responsive, tout contenu doit pouvoir être scrollé dans un CustomScrollView (Slivers)
Affiche distance à l’utilisateur si géolocalisation active

2.5 Réservation (ReservationScreen)
Affichage recap : logement, photos, calendrier sélectionné, prix calculé, dates choisies
Formulaire : choix date début/fin (déjà préfilled si passé depuis DétailAnnonceScreen), bouton “Valider”
Appelle API de check/insert réservation (dates sont vérouillées côté serveur), montant recalculé côté PHP également avec la même logique que sur mobile (double contrôle)
En cas de succès : snackbar « Réservation créée », redirige vers Profil onglet historiques
En cas de conflit : message d’erreur, le calendrier surligne les dates indisponibles

2.6 Carte interactive (CarteScreen)
Initialisation : charge les biens et les POI avec coordonnées, affiche tous les marqueurs sur carte OSM (flutter_map + latlong2)
Affichage : marquers différenciés par type, clic => BottomSheet fiche résumée + bouton naviguer (ouvre détail bien ou POI)
Si permission GPS active, centre la carte sur auto-position ; bouton « Me localiser » recalcule la position et recadre la vue ; si non, fallback centre France
L’utilisateur voit un marqueur personnalisé de sa position (bleu)
Clic POI : ouvre mini-fiche + bouton aller à détail POI
Clic bien : ouvre fiche + bouton aller à DétailAnnonceScreen

2.7 Favoris (FavorisScreen)
Liste grid des biens favoris de l’utilisateur connecté
Image, titre, prix/nuit, commune, note
Bouton cœur pour supprimer (supprime/retire feedback immédiat)
Clic : ouvre DétailAnnonceScreen
Message si liste vide

2.8 Avis & Blog (AvisScreen)
Liste des avis publiés : nom auteur, bien concerné, note, commentaire, date
Filtres : par bien, par note minimale ; pagination (scroll infini/20 par page)
Clic sur “Laisser un avis” (connecté uniquement) : opens bottom sheet ou nouvelle page
Sélection du bien parmi ceux déjà réservés (récupérés sur l’API)
Notation étoiles, commentaire libre
Envoi : POST API, feedback immédiat visuel (“en attente de modération”)
Message explicite si pas d’avis
Si clic sur bien : remonte à DétailAnnonceScreen

2.9 Profil utilisateur (ProfilScreen)
Affichage : Données utilisateur, historique réservations avec status
Tabs (TabBar 3 Onglets) :
Infos & modification (données éditables + bouton “Enregistrer”)
Historique réservations (listview, possible d’annuler si “en attente”)
Paramètres (switch thème, bouton déconnexion)
Modification profil nécessite RGPD coché à chaque fois, validation complète des champs avant POST
Changement mot de passe : champ ancien + nouveau + confirmation, validation avant POST
Annulation réservation uniquement sur celles en attente, feedback couleur par status sur les Cards
Clic “Déconnexion” : flush les shared_preferences/token, redirige login

2.10 Support (SupportScreen)
Formulaire : type (dropdown), sujet (texte court), message, priorité (dropdown/boutons), page concernée (texte)
Pré-remplissage nom/email si user connecté
Validation : tous les champs requis, email valide ; feedback escaladé sur priorité urgente
Clic “Soumettre” : POST API, success => affiche numéro de ticket, snackbar

2.11 Géolocalisation (service transverse)
Service Flutter “LocationService” appelé sur CarteScreen, AnnoncesScreen (filtre autour de moi), PtsInteretDetailScreen
Gestion permission/timeout : affiche la Snackbar ou AlertDialog selon cas
Mode tracking optionnel sur CarteScreen (update position marker si déplacement, limité pour batterie)
Toute distance affichée à l’utilisateur = calculée Flutter (pour l’UI), et côté backend (pour le tri SQL/Haversine)
Les coordonnées utilisateur ne sont jamais sauvegardées en BDD, tout est local/éphémère

4. Scénarios & Interactions Notables
Tous les boutons principaux affichent un feedback visuel sur click (snackbar, loader, désactivation…)
Transferts inter-écrans se font via Navigator push/pop avec éventuellement passage de paramètres/retour résultats (ex : après login ou réservation réussie)
Persistance des états multi-étapes (via Providers/SharedPrefs) pour garantir aucune perte d’infos en cas de crash/background/app kill
Gestion erreurs réseaux : toute erreur HTTP, timeout ou validation est interceptée, feedback GUI adapté (snackbar/alert, désactive la fonction et propose relancer ou diagnostic)

6. Tests – Critères d’acceptation
Chaque module décrit des tests types (“T1, T2, ...”) dans le README – tous doivent avoir leurs tests automatisés correspondants côté Flutter (test/) et être validés à chaque mise à jour.

7. Adaptations/Évolutions (Issues et backlog)
Si tu souhaites que la spéc inclue un backlog précis basé sur les issues GitHub, indique-le et je ferai un résumé/ticket-by-ticket des points à revoir/intégrer/corriger.
Idem pour les demandes issues du web.

8. Dépendances Flutter & Intégrations Tiers
Toutes les dépendances nécessaires (geolocator, flutter_map, riverpod/provider, cached_network_image, carousel_slider, table_calendar, flutter_rating_bar, shared_preferences, http) doivent être listées et maintenues à jour.
Permissions requises Android/iOS pour le GPS doivent être prévues dans le projet, voir README.
Les APIs externes (autocomplete adresses, SIREN pour entreprises, etc.) sont appelées en direct (http) côté Flutter, résultats validés en local avant envoi au back.
