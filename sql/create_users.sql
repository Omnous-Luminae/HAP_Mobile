-- =============================================================================
-- create_users.sql — Gestion des utilisateurs MySQL par application
-- Base de données : Project_HAP (House After Party)
--
-- Stratégie : 1 seule base de données, 2 utilisateurs MySQL avec droits
-- différenciés selon l'application (web = accès complet, mobile = restreint).
--
-- ⚠️  Remplacez les mots de passe avant d'exécuter ce script en production.
-- =============================================================================

USE Project_HAP;


-- =============================================================================
-- UTILISATEUR : APP WEB — accès complet (admin inclus)
-- =============================================================================

CREATE USER IF NOT EXISTS 'hap_web'@'localhost'
    IDENTIFIED BY 'ChangeMe_WebPassword_Fort!';

-- Accès complet à toutes les tables (y compris Animateur, Archives…)
GRANT SELECT, INSERT, UPDATE, DELETE ON Project_HAP.* TO 'hap_web'@'localhost';

FLUSH PRIVILEGES;
SELECT '✅ Utilisateur hap_web créé avec accès complet' AS status;


-- =============================================================================
-- UTILISATEUR : APP MOBILE — accès restreint (pas d'admin, pas d'archives)
-- =============================================================================

CREATE USER IF NOT EXISTS 'hap_mobile'@'localhost'
    IDENTIFIED BY 'ChangeMe_MobilePassword_Fort!';

-- ── Tables en lecture seule (le mobile consulte mais ne modifie pas) ──────────
GRANT SELECT ON Project_HAP.Commune            TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Biens              TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Type_Bien          TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Tarif              TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Saison             TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Prestation         TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Compose            TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Photos             TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Pts_Interet        TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Photos_PtsInteret  TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Type_Pts_Interet   TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Dispose            TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Evenement          TO 'hap_mobile'@'localhost';
GRANT SELECT ON Project_HAP.Type_Evenement     TO 'hap_mobile'@'localhost';

-- ── Tables avec lecture + écriture (actions du locataire) ─────────────────────
-- Le locataire peut créer son compte, modifier son profil
GRANT SELECT, INSERT, UPDATE ON Project_HAP.Locataire   TO 'hap_mobile'@'localhost';

-- Le locataire peut ajouter / supprimer des favoris
GRANT SELECT, INSERT, DELETE ON Project_HAP.Favoris     TO 'hap_mobile'@'localhost';

-- Le locataire peut créer des réservations et les consulter
GRANT SELECT, INSERT         ON Project_HAP.Reservation TO 'hap_mobile'@'localhost';

-- Le locataire peut laisser des avis
GRANT SELECT, INSERT         ON Project_HAP.Reviews     TO 'hap_mobile'@'localhost';

-- La blacklist JWT est gérée uniquement par l'API mobile
GRANT SELECT, INSERT, DELETE ON Project_HAP.jwt_blacklist TO 'hap_mobile'@'localhost';

-- ❌ PAS d'accès à :
--    Animateur          → gestion admin (app web uniquement)
--    Reservation_Archive → archives admin
--    Archive_Log        → logs système admin
--    Compose_backup     → sauvegardes admin

FLUSH PRIVILEGES;
SELECT '✅ Utilisateur hap_mobile créé avec accès restreint' AS status;


-- =============================================================================
-- Vérification des droits accordés
-- =============================================================================
-- SHOW GRANTS FOR 'hap_web'@'localhost';
-- SHOW GRANTS FOR 'hap_mobile'@'localhost';
