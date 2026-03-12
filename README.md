# Spécification Fonctionnelle – HapMobile (v2)

## 1. Introduction

L'application HapMobile est l'adaptation mobile Flutter du projet web Project HAP. Elle permet à l'utilisateur de chercher, réserver et gérer des locations, d'accéder à des services communautaires et d'utiliser des modules tels que la carte interactive (avec géolocalisation).

Elle communique avec le backend PHP/MySQL mutualisé avec le web (BDD et APIs communes) mais apporte une expérience adaptée au mobile.

---

## 2. Particularités de l'application mobile par rapport au web

- **Géolocalisation utilisateur native (mobile uniquement) :**
  - Permet la localisation de l'utilisateur sur la carte interactive, le filtrage « autour de moi », le calcul de distance jusqu'à un bien ou événement, etc.
  - Appel direct aux capteurs natifs du téléphone (via les permissions nécessaires) pour améliorer la recherche et l'expérience utilisateur dans l'app mobile.

- **Gestion administrative :**
  - Toutes les fonctionnalités d'administration, de gestion/modération des contenus, des annonces ou des utilisateurs restent exclusivement accessibles sur ordinateur via l'interface web (aucun espace admin côté application mobile).

---

## 3. Technologies principales

- Flutter/Dart pour le front mobile
- APIs PHP/MySQL mutualisées avec le web
- Géolocalisation native avec geolocator, carte OSM via flutter_map/latlong2
- Stockage local sécurisé avec shared_preferences
- Gestion d'état via flutter_riverpod

---

## 4. Résumé

La seule différence majeure d'un point de vue fonctionnel/technique par rapport au projet web est la géolocalisation native des utilisateurs sur mobile. L'intégralité de l'administration/modération doit impérativement se faire depuis un ordinateur, aucune gestion de contenu/annonce/utilisateur n'est possible côté mobile.