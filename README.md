1. Introduction
HapMobile est l’adaptation mobile Flutter du projet web Project HAP. L’utilisateur peut rechercher, réserver et gérer des locations, accéder à des services communautaires et utiliser une carte interactive dotée de géolocalisation native.
L’application communique avec un backend PHP/MySQL mutualisé (APIs et BDD communes), mais propose une expérience adaptée au mobile.

2. Particularités de l’application mobile par rapport au web
Géolocalisation utilisateur native (mobile uniquement) :
Permet la localisation en temps réel sur la carte, le filtrage « autour de moi », le calcul de la distance vers chaque bien ou événement.
Utilise les capteurs natifs du téléphone (via permissions gérées dynamiquement) pour optimiser la recherche et l’expérience utilisateur.
Gestion administrative :
Toutes les fonctionnalités d’administration, de gestion ou modération restent strictement réservées à l’interface web (aucun espace admin sur mobile).

3. Architecture & descriptif exhaustif des écrans et composants
   
3.1 Accueil
Champ de recherche (texte) :
Saisie d’adresse, ville ou mot-clé.

Icône loupe (bouton): valide la recherche, redirige vers Résultats.

Carte interactive (OpenStreetMap intégrée) :
Pins interactifs : tap = aperçu du bien (popup image+titre+boutons).
Bouton “Ma position” (icône cible) : recadre la carte sur l’utilisateur.
Bouton “Filtrer autour de moi” : ouvre un slider pour choisir le rayon.

Slider “Rayon” (0–50 km) :
Glissière gauche/droite, change en temps réel le rayon de recherche autour de soi, modifie affichage des biens/services sur la carte.

Cartes catégories (Locations, Événements, Services, autres…) :
Appui = filtre instantané et affichage des résultats de la catégorie sélectionnée.

Bandeaux ou tuiles infos/notifications :
Texte explicatif et bouton “fermer” (croix).

3.2 Recherche & Filtres
Champs texte :
Adresse/localisation libre.

Cases à cocher :

Types de bien : appartement, maison, studio…

Services inclus : wifi, parking, animaux acceptés, etc.
Chaque appui sélectionne/désélectionne l’option (état visible).

Sliders :
Prix minimum/maximum.
Surface minimum/maximum.
Rayon (si pas déjà choisi à l’accueil).

Bouton “Rechercher” :
Lance la recherche avec les critères sélectionnés.

Toggle “Affichage liste/carte” (switch ou segment button) :
Permute l’affichage des résultats (liste <-> carte).

3.3 Résultats
Cartes/tiles de résultats :
Tap sur une carte : affiche la fiche détail du bien.

Bouton “Réserver” : ouvre l’écran réservation du bien sélectionné.

Icône “Favoris” (cœur) : ajouter/retirer ce bien des favoris de l’utilisateur (état cœur plein/vide).
Infobulle “Aucun résultat” si besoin

3.4 Fiche Détail Bien/Annonce
Galerie photo (carrousel horizontal) :
Slide à gauche/droite (ou flèches) pour parcourir les images.
Bouton “Itinéraire” (petite carte/icône voiture) :
Ouvre la navigation dans l’app ou via Maps/Waze vers l’adresse du bien.

Bouton “Réserver” :
Passe à l’écran de réservation avec le bien prérempli.

Section équipements/services :
Liste à puces ou avec icônes cochées/non cochées selon la présence des équipements.

Section avis et notes :
Affichage des notes/étoiles.
Si l’utilisateur a réservé : bouton “Déposer un avis” qui ouvre formulaire avec slider étoiles + champ texte + bouton “Envoyer”.
Bouton retour : navigation vers la page précédente.

3.5 Réservation
Sélecteurs de date (allée/retour ou plage de date) :
Tap = ouvre calendrier natif, sélection de dates.

Stepper nombre de personnes (+ / -) :
Boutons “+” ou “-” pour incrémenter/décrémenter le nombre.

Cases à cocher options :
Ménage, assurance, location de draps… (ajoute/supprime options à la réservation).

Bouton “Valider” :
Affiche le récapitulatif, puis confirme la réservation.
Bouton “Annuler” : retourne à la fiche bien.

3.6 Mes Réservations
Liste de réservations passées et à venir :
Tap : détails de la réservation.
Bouton “Annuler” (si réservation future) : ouvre dialogue de confirmation, puis annule si validé.

3.7 Profil
Champs texte éditables : nom, prénom, mail, téléphone, etc.
Tap = édition possible, clavier natif.

Bouton “Modifier” :
Passe l’écran en mode édition.
Bouton “Enregistrer” :
Sauvegarde modifications sur le serveur.

Bouton “Déconnexion” :
Déconnecte l’utilisateur, retour à l’écran de login.

Bouton “Supprimer mon compte” :
Ouvre une confirmation par dialogue ; si validée, supprime le compte.

3.8 Services / Événements
Liste filtrable par distance (slider rayon).
Bouton “Participer/S’inscrire” : ajoute l’utilisateur à l’événement/service, état modifié (inscrit/non inscrit).

Bouton “Créer une demande” (pour utilisateurs habilités seulement) :
Ouvre un formulaire spécifique.
Toggle d’affichage carte/liste

3.9 Paramètres
Cases à cocher :
consentement données, autres options diverses.
Activation/désactivation prise en compte instantanément.
Bouton “Réinitialiser”/“Vider le cache” :
Ouvre une confirmation ; réalise l'action.
Bouton “Retour”/navigation



4. Technologies principales
Flutter & Dart (mobile)
APIs web mutualisées PHP/MySQL
Géolocalisation native (geolocator)
Carte OSM (flutter_map, latlong2)
shared_preferences pour stockage local
riverpod pour gestion d’état
6. Résumé
La version mobile reprend toutes les fonctionnalités principales à destination des utilisateurs (hors administration), avec en plus l’intégration complète de la géolocalisation native pour une expérience optimale « autour de moi ».
Chaque composant interactif, champ, slider, case à cocher et bouton a une fonctionnalité précise décrite ci-dessus.

