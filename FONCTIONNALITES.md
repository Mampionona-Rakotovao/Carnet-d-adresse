# Inventaire fonctionnel vérifié — `carnet_adresses_repere`

> Audit réalisé par lecture du code source (lecture seule). Date de vérification : 2026-11-12. Environnement analysé : `/home/mampy/Modeles/carnet_adresses_repere`.
> Chaque fonctionnalité ci-dessous est prouvée par au moins une référence `fichier:ligne`. Les éléments non prouvables par le dépôt sont en annexe (§10).

## 1. Résumé

- **Nature** : application Flutter (Dart `>=3.3.0 <4.0.0`, version `0.1.0`) de carnet d’adresses basé sur des repères, avec carte MapTiler, itinéraire/guidage via OSRM, partage par lien Supabase et centre d’aide intégré (`pubspec.yaml:1-8`, `README.md:1-9`, `lib/main.dart:92-148`).
- **Backend** : Supabase (URL/clé anon en dur dans `lib/core/supabase_client.dart:36-48`), tables/RPC/bucket utilisés côté app : `addresses`, `landmarks`, `route_steps`, `favorites`, `profiles`, `photos`, `address_permissions`, `share_links`, `share_link_redemptions`, `share_link_uses`, RPC `create_share_link`, `revoke_share_link`, `redeem_share_link`, `get_my_shared_addresses` (preuves `grep` et migrations).
- **Fonctionnalités inventoriées** : **52** — ✅ Complète : 33, 🟡 Partielle : 11, 🔸 Affichage seul/stub : 1, ⚫ Code mort : 2, ❓ Non déterminé : 5.
- **Points forts (prouvés)** : auth e-mail/Google + reset par code/lien, CRUD adresses/repères/étapes, carte plan/satellite, calcul d’itinéraire OSRM et guidage GPS animé, partage par lien avec limites/durée/révocation/compteur et écran destinataire, aide riche avec recherche locale, thèmes persistants (`lib/core/router.dart:156-301`, `lib/features/navigation/navigation_screen.dart:73-148`, `lib/features/address_detail/widgets/share_link_sheet.dart:110-207`, `lib/features/help/data/help_search.dart:18-259`).
- **Principaux manques/écarts** : 2 erreurs d’analyse et 10 tests en échec, clé Supabase anon et URL hardcodées, App Links/`assetlinks.json` non présents dans le dépôt, iOS sans deep links/universal links déclarés, recherche « Partagées avec moi » et favoris partagés dépendants de tables/RLS non définies dans les migrations fournies, notification propriétaire incomplète côté client, pas de suppression de compte/hors-ligne/itinéraire non voiture (`flutter analyze`, `flutter test`, `lib/core/supabase_client.dart:38-39`, `lib/features/search/search_screen.dart:95-104`, `lib/core/share_notifications.dart:151-189`).

## 2. Tableau récapitulatif

| ID | Nom | Catégorie | Statut | Écran / route |
|---|---|---|---|---|
| F-001 | Initialisation, session, deep links entrants | Robustesse / Plateformes | ✅ | `main.dart` (pas de route) |
| F-002 | Gestion globale des erreurs et écran de secours | Robustesse | ✅ | global (`_AppErrorFallback`) |
| F-003 | Inscription e-mail + confirmation par code | Compte et authentification | ✅ | `/login`, `/confirm-email` |
| F-004 | Connexion e-mail / mot de passe | Compte et authentification | ✅ | `/login` |
| F-005 | Connexion Google (native web/mobile) | Compte et authentification | 🟡 | `/login` |
| F-006 | Mot de passe oublié (code + lien) et réinitialisation | Compte et authentification | ✅ | `/login`, `/reset-code`, `/reset-password` |
| F-007 | Déconnexion et invalidation session expirée | Compte et authentification | ✅ | accueil (menu), démarrage |
| F-008 | Profil utilisateur `profiles` (best effort) | Compte et authentification | 🟡 | post-auth / démarrage implicite |
| F-009 | Suppression de compte | Compte et authentification | 🔸 | non implémenté (mentionné aide) |
| F-010 | Liste des adresses (flux temps réel, récents) | Adresses | ✅ | `/` |
| F-011 | Création d’adresse (formulaire complet) | Adresses | ✅ | `/address/create` |
| F-012 | Modification d’adresse | Adresses | ✅ | `/address/:id/edit` |
| F-013 | Suppression d’adresse et nettoyage photos | Adresses | ✅ | `/address/:id` |
| F-014 | Capture GPS et choix position sur carte | Adresses | ✅ | `/address/create`, `/address/:id/edit` |
| F-015 | Photo d’adresse (galerie, upload Storage) | Adresses | ✅ | formulaire adresse |
| F-016 | Consultation détail d’adresse (propriétaire/visiteur) | Adresses | ✅ | `/address/:id` |
| F-017 | Repères : création, détail, modification, suppression | Repères | ✅ | `/address/:id`, `/address/:id/steps`, détail partagé |
| F-018 | Photo de repère et stockage | Repères | ✅ | feuille repère |
| F-019 | Étapes du trajet : ajout, détail, modification, suppression | Étapes du trajet | ✅ | `/address/:id`, `/address/:id/steps` |
| F-020 | Assistant de finalisation (repères puis étapes) | Étapes du trajet / Repères | ✅ | `/address/:id/steps` |
| F-021 | Favoris : ajout/retrait, liste, annulation | Favoris | ✅ | `/favorites`, `/search`, `/address/:id` |
| F-022 | Filtrage RLS implicite des favoris/adresses | Favoris / Sécurité | ❓ | lectures Supabase |
| F-023 | Recherche d’adresses (nom/localité/repère, périmètres) | Recherche | 🟡 | `/search` |
| F-024 | Carte MapTiler plan/satellite, marqueurs, attribution | Carte | ✅ | fiches/formulaires/guidage |
| F-025 | Bascule vue carte et sélection de position | Carte | ✅ | formulaires/adresses |
| F-026 | Comportement carte sans clé / erreur tuiles | Carte | 🟡 | `CarteWidget` |
| F-027 | Calcul d’itinéraire OSRM (voiture) | Trajet | ✅ | fiche adresse |
| F-028 | Guidage intégré GPS (suivi, recalcul, arrivée) | Trajet | ✅ | écran navigation (push) |
| F-029 | Ouverture navigation externe Google Maps | Trajet | ✅ | fiche/guidage |
| F-030 | Création de lien de partage (durée, nb personnes) | Partage | ✅ | feuille partage (fiche adresse) |
| F-031 | Liste, historique, repartage et révocation des liens | Partage | ✅ | feuille partage |
| F-032 | Ouverture d’un lien partagé (écran dédié `/a/:token`) | Partage | ✅ | `/a/:token` |
| F-033 | Ouvrir un lien/coller un code (onglet) | Partage | 🟡 | `/share/open` |
| F-034 | Adresses « Partagées avec moi » | Partage | 🟡 | `/shared` |
| F-035 | Notifications d’ouverture de liens au propriétaire | Partage | 🟡 | global (snack) |
| F-036 | Centre d’aide, catégories, articles, recherche | Aide et accompagnement | ✅ | `/aide`, `/aide/categorie/:categorie`, `/aide/:id` |
| F-037 | Aide contextuelle, feedback article, suggestions | Aide et accompagnement | ✅ | fiches/formulaires/feuilles, articles |
| F-038 | Tour de bienvenue (onboarding) | Aide et accompagnement | ✅ | accueil (overlay) |
| F-039 | Support par e-mail pré-rempli | Aide et accompagnement | ✅ | centre d’aide / articles |
| F-040 | Thème clair/sombre/système persistant | Interface et design | ✅ | menu accueil, global |
| F-041 | Barre de navigation flottante (shell) | Interface et design | ✅ | `/`, `/search`, `/favorites`, `/share/open` |
| F-042 | Fonds d’écran dessinés (AppBackground) | Interface et design | ✅ | multiples écrans |
| F-043 | Design system, états, feedback, haptique | Interface et design | 🟡 | global |
| F-044 | Animations/transitions | Interface et design | 🟡 | barre nav, guidage, pages |
| F-045 | Accessibilité (sémantique, scaling, motion) | Interface et design | 🟡 | partiel |
| F-046 | Pages 404 / erreurs de route et contenu introuvable | Robustesse | ✅ | `errorBuilder`, écrans aide |
| F-047 | Plateformes, permissions Android, intents/deep links | Plateformes et distribution | 🟡 | Android manifest, iOS, web |
| F-048 | Page web de secours / téléchargement / App Links | Plateformes et distribution | ⚫ | dépôt (`web/`, racine) absent de preuve |
| F-049 | Composant squelettes de chargement | Interface et design | ⚫ | `lib/ui/app_skeleton.dart` (non référencé) |
| F-050 | Routeur, gardes d’auth et flux de récupération | Compte et authentification / Robustesse | ✅ | `lib/core/router.dart` |
| F-051 | Tests automatisés et analyse statique | Tests et outils | 🟡 | `test/`, `flutter analyze/test` |
| F-052 | Données personnelles, clés et sécurité côté client | Sécurité et confidentialité | ❓ | client + migrations partielles |

## 3. Catalogue détaillé

### Compte et authentification

#### F-001 · Initialisation, session, deep links entrants
- Catégorie : Robustesse / Plateformes et distribution
- Description : Initialise Flutter/Supabase/préférences, restaure ou invalide une session expirée, mémorise les liens de reset/partage au démarrage à froid et route les liens reçus à chaud.
- Statut : ✅ Complète
- Où l'utiliser : au lancement de l’app (aucune route dédiée) ; redirige vers `/reset-password` ou `/a/:token` selon lien.
- Preuves : `lib/main.dart:92-148`, `lib/main.dart:150-155`, `lib/core/router.dart:49-106`, `lib/core/supabase_client.dart:36-48`, `lib/core/share_notifications.dart:26-49`.
- Données : `auth` Supabase (session, refresh, signOut) ; `SharedPreferences` indirect via `initShareOpenNotifications` (`lib/core/share_notifications.dart:58-76`).
- Permissions et dépendances : `app_links` (`pubspec.yaml:17`, `lib/main.dart:1,126-144`), `shared_preferences` (`pubspec.yaml:40`).
- Cas limites gérés : session expirée/invalide au boot -> tentative refresh puis `signOut` (`lib/main.dart:113-120`) ; lien reset web `/reset-password` mémorisé avant init (`lib/main.dart:99-102`) ; lien partage froid via `definirLienInitial` (`lib/main.dart:131-134`).
- Limites ou manques constatés : la reconnaissance de lien partage n’accepte que host GitHub Pages précis ou schéma `carnetadresses` (`lib/core/router.dart:61-76`) ; aucun autre domaine/hôte.

#### F-002 · Gestion globale des erreurs et écran de secours
- Catégorie : Robustesse
- Description : Journalise les erreurs Flutter/plateforme et affiche en release un écran de secours localisé avec retour à l’accueil.
- Statut : ✅ Complète
- Où l'utiliser : global, affiché à la place du widget rouge en mode release.
- Preuves : `lib/main.dart:19-90`, `lib/main.dart:94`.
- Données : aucune.
- Permissions et dépendances : Flutter foundation/material.
- Cas limites gérés : mode debug conserve `ErrorWidget` détaillé (`lib/main.dart:30-33`) ; handler global retourne `true` (`lib/main.dart:25-28`).
- Limites ou manques constatés : pas de télémétrie/rapport distant, seulement `debugPrint` (`lib/main.dart:22,27`).

#### F-003 · Inscription e-mail + confirmation par code
- Catégorie : Compte et authentification
- Description : Permet de créer un compte avec nom, e-mail, mot de passe puis, si aucune session n’est créée, de valider un code OTP reçu par e-mail.
- Statut : ✅ Complète
- Où l'utiliser : `Accueil` non connecté → `/login` (bascule inscription) → `/confirm-email`.
- Preuves : `lib/features/auth/auth_screen.dart:34-75`, `lib/features/auth/auth_screen.dart:222-287`, `lib/features/auth/confirm_email_screen.dart:22-63`, `lib/core/router.dart:156-187`.
- Données : `auth.signUp`, `auth.verifyOTP(type: signup)`, `auth.resend(type: signup)` ; métadonnée `name` ; `profiles` via `ensureProfile()` si session immédiate (`lib/features/auth/auth_screen.dart:41-57`, `lib/features/auth/confirm_email_screen.dart:33-39`, `lib/core/supabase_client.dart:13-29`).
- Permissions et dépendances : `supabase_flutter` ; réseau.
- Cas limites gérés : email invalide / nom vide / mot de passe < 6 (`lib/features/auth/auth_screen.dart:240-286`) ; code nettoyé des non-chiffres (`lib/features/auth/confirm_email_screen.dart:23-24`) ; renvoi de code possible.
- Limites ou manques constatés : la longueur de code n’est pas strictement imposée côté app (max 10) et dépend du backend (`lib/features/auth/confirm_email_screen.dart:96-104`).

#### F-004 · Connexion e-mail / mot de passe
- Catégorie : Compte et authentification
- Description : Authentifie un utilisateur existant par e-mail et mot de passe ; la redirection est pilotée par l’état de session.
- Statut : ✅ Complète
- Où l'utiliser : `/login`.
- Preuves : `lib/features/auth/auth_screen.dart:59-66`, `lib/features/auth/auth_screen.dart:289-326`, `lib/core/router.dart:121-153`.
- Données : `auth.signInWithPassword`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : champs requis/format e-mail (`lib/features/auth/auth_screen.dart:255-286`) ; erreurs affichées via `AppSnack.error` (`lib/features/auth/auth_screen.dart:69-71`, `lib/ui/app_feedback.dart:104-114`).
- Limites ou manques constatés : pas de protection anti-double-clic spécifique au-delà du flag `_loading` désactivant les boutons (`lib/features/auth/auth_screen.dart:35,315,335`).

#### F-005 · Connexion Google
- Catégorie : Compte et authentification
- Description : Propose une connexion Google : flux OAuth navigateur sur web, et flux natif `google_sign_in` + `signInWithIdToken` sur mobile.
- Statut : 🟡 Partielle
- Où l'utiliser : `/login` → bouton « Continuer avec Google ».
- Preuves : `lib/features/auth/widgets/google_sign_in_button.dart:25-51`, `lib/services/google_auth_service.dart:3-29`, `lib/features/auth/auth_screen.dart:332-333`.
- Données : `auth.signInWithOAuth(Google)` sur web (`google_sign_in_button.dart:29-34`), `auth.signInWithIdToken(Google)` sur mobile (`google_auth_service.dart:25-28`), puis `profiles.upsert` via `ensureProfile()` (`google_sign_in_button.dart:39`).
- Permissions et dépendances : `google_sign_in` (`pubspec.yaml:41`), réseau, configuration Google Cloud/console (non versionnée) ; `webClientId` hardcodé (`google_auth_service.dart:3-4`).
- Cas limites gérés : annulation Google ignorée (`google_sign_in_button.dart:41-45`) ; absence d’`idToken` lève `AuthException` (`google_auth_service.dart:21-23`).
- Limites ou manques constatés : `_webRedirectFallback` déclaré mais non utilisé (`lib/features/auth/widgets/google_sign_in_button.dart:12`, warning `flutter analyze`) ; validité/configuration OAuth côté projet Google/Supabase non vérifiable depuis le dépôt.

#### F-006 · Mot de passe oublié, code OTP et nouveau mot de passe
- Catégorie : Compte et authentification
- Description : Envoie un e-mail de reset, permet de valider un code de récupération puis de définir un nouveau mot de passe ; gère aussi l’arrivée par lien profond.
- Statut : ✅ Complète
- Où l'utiliser : `/login` → « Mot de passe oublié ? » → `/reset-code` → `/reset-password`.
- Preuves : `lib/features/auth/auth_screen.dart:77-137`, `lib/features/auth/reset_code_screen.dart:38-97`, `lib/features/auth/reset_code_screen.dart:99-132`, `lib/features/auth/reset_password_screen.dart:33-55`, `lib/core/router.dart:107-114`, `lib/core/router.dart:129-134`, `lib/main.dart:99-102,125-143`.
- Données : `auth.resetPasswordForEmail` (envoi + renvoi), `auth.verifyOTP(type: recovery)`, `auth.updateUser(password)` ; flag `_isPasswordRecovery` côté client.
- Permissions et dépendances : `supabase_flutter`, `app_links` (mobile), réseau.
- Cas limites gérés : cooldown renvoi 30s (`reset_code_screen.dart:20,118-130`) ; message spécifique code expiré/invalide (`reset_code_screen.dart:54-63`) ; validation confirmation mot de passe (`reset_password_screen.dart:119-127`).
- Limites ou manques constatés : flux mixte code/lien (complexe) ; succès dépend des templates Supabase/email livrables non présents dans le dépôt.

#### F-007 · Déconnexion et invalidation session expirée
- Catégorie : Compte et authentification
- Description : Déconnecte depuis le menu accueil (avec confirmation) et force un retour propre au login si la session stockée est invalide/expirée.
- Statut : ✅ Complète
- Où l'utiliser : `/` menu ⋮ → « Se déconnecter » ; au démarrage ; sur erreur JWT dans le flux accueil.
- Preuves : `lib/features/home/home_screen.dart:53-103`, `lib/features/home/home_screen.dart:189-201`, `lib/main.dart:113-120`, `lib/features/home/home_screen.dart:228-235`.
- Données : `auth.signOut()`, `auth.refreshSession()`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : dialogue de confirmation (`home_screen.dart:55-97`) ; session expirée au boot (`main.dart:113-120`) ; erreur JWT stream -> `signOut` (`home_screen.dart:228-235`).
- Limites ou manques constatés : pas de suppression des données locales de cache applicatif au logout (hors session Supabase).

#### F-008 · Profil utilisateur `profiles`
- Catégorie : Compte et authentification
- Description : Crée/complète best effort une ligne de profil à partir de l’utilisateur connecté (id, email, nom).
- Statut : 🟡 Partielle
- Où l'utiliser : après inscription avec session immédiate et après connexion Google native (appel explicite).
- Preuves : `lib/core/supabase_client.dart:7-30`, `lib/features/auth/auth_screen.dart:55-57`, `lib/features/auth/widgets/google_sign_in_button.dart:37-39`.
- Données : table `profiles` (`upsert` sur `id/email/name`).
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : aucun utilisateur connecté -> no-op ; échec loggé sans bloquer (`supabase_client.dart:14-29`).
- Limites ou manques constatés : pas d’écran de consultation/édition du profil ; aucune preuve d’appel `ensureProfile()` pour connexion e-mail classique (seulement inscription session immédiate et Google) ; schéma/politiques `profiles` absents du dépôt.

#### F-009 · Suppression de compte
- Catégorie : Compte et authentification
- Description : Fonction annoncée comme absente dans l’aide ; aucun flux de suppression de compte trouvé dans le code.
- Statut : 🔸 Affichage seul / stub (informationnel) — fonction non implémentée
- Où l'utiliser : non disponible.
- Preuves : `lib/features/help/data/help_content.dart:1895-1904` (« L'application ne propose pas encore de suppression de compte. ») ; absence de `deleteUser`/RPC de suppression dans `lib/` (`grep "deleteUser|supprimer.*compte"` sans résultat d’implémentation).
- Données : aucune.
- Permissions et dépendances : n/a.
- Cas limites gérés : n/a.
- Limites ou manques constatés : attente utilisateur possible vu texte d’aide ; aucun parcours applicatif.

### Adresses

#### F-010 · Liste des adresses de l’utilisateur (accueil)
- Catégorie : Adresses
- Description : Affiche en temps réel les adresses de l’utilisateur connecté, avec état vide, erreur JWT/session, et ouverture du détail.
- Statut : ✅ Complète
- Où l'utiliser : onglet `Accueil` → `/`.
- Preuves : `lib/features/home/home_screen.dart:29-45`, `lib/features/home/home_screen.dart:217-359`, `lib/core/router.dart:193-199`, `lib/core/app_scaffold.dart:45-104`.
- Données : `addresses` stream `.stream(primaryKey:['id']).eq('owner_id', userId).order('created_at')` (`home_screen.dart:33-44`).
- Permissions et dépendances : `supabase_flutter`, shell navigation.
- Cas limites gérés : utilisateur null -> stream vide (`home_screen.dart:33-35`) ; erreur JWT -> signOut (`home_screen.dart:228-235`) ; adresse supprimée masquée localement après retour (`home_screen.dart:47-53`, `247-250`).
- Limites ou manques constatés : pas de pagination (stream complet) ; tri “récentes” par `created_at desc`.

#### F-011 · Création d’adresse
- Catégorie : Adresses
- Description : Crée une adresse avec nom (obligatoire), description/localité optionnelles, visibilité, type GPS, position et photo optionnelle, puis ouvre l’assistant d’étapes.
- Statut : ✅ Complète
- Où l'utiliser : `/` menu → « Ajouter une adresse » → `/address/create` ; après enregistrement → `/address/:id/steps`.
- Preuves : `lib/features/address_create/address_form_screen.dart:166-231`, `lib/features/address_create/address_form_screen.dart:240-520`, `lib/core/router.dart:266-272`.
- Données : `addresses.insert(...).select().single()` puis éventuel `addresses.update(photo_url)` ; Storage `photos` via upload (`address_form_screen.dart:156-164,195-225`).
- Permissions et dépendances : `image_picker`, `geolocator`/`permission_handler` (via capture), `supabase_flutter`, `flutter_map`.
- Cas limites gérés : nom obligatoire, position GPS obligatoire avant save (`address_form_screen.dart:168-174,320-324,447-449`) ; nettoyage photo ancienne en édition non applicable ici.
- Limites ou manques constatés : après création, redirection vers étapes et non fiche détail (`address_form_screen.dart:226-230`).

#### F-012 · Modification d’adresse
- Catégorie : Adresses
- Description : Modifie les champs d’une adresse existante et met à jour/remplace la photo en nettoyant l’ancienne si nécessaire.
- Statut : ✅ Complète
- Où l'utiliser : `/address/:id` (propriétaire) → icône crayon → `/address/:id/edit`.
- Preuves : `lib/features/address_detail/address_detail_screen.dart:467-475`, `lib/features/address_create/address_form_screen.dart:179-194`, `lib/core/router.dart:273-281`, `lib/core/photo_storage.dart:9-28`.
- Données : `addresses.update(...).eq(id)` ; `photos` upload/remove best effort.
- Permissions et dépendances : `image_picker`, `supabase_flutter`.
- Cas limites gérés : suppression de la référence photo ancienne si URL changée (`address_form_screen.dart:190-192`).
- Limites ou manques constatés : aucun contrôle propriétaire côté écran d’édition (la fiche masque l’action, mais la route reste accessible si `Address` extra fourni) ; sécurité effective dépend RLS (non prouvée dans dépôt).

#### F-013 · Suppression d’adresse et nettoyage des photos
- Catégorie : Adresses
- Description : Supprime une adresse après confirmation, exige une ligne supprimée côté base, puis tente de supprimer le dossier photo associé.
- Statut : ✅ Complète
- Où l'utiliser : `/address/:id` (propriétaire) → icône corbeille.
- Preuves : `lib/features/address_detail/address_detail_screen.dart:172-223`, `lib/core/photo_storage.dart:32-50`.
- Données : `addresses.delete().eq(id).select()` ; Storage bucket `photos` suppression dossier.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : confirmation explicite ; échec si `deleted` vide (`address_detail_screen.dart:188-207`) ; retour liste/accueil après suppression (`address_detail_screen.dart:95-101`).
- Limites ou manques constatés : suppression des repères/étapes/favoris/liens présentée à l’utilisateur mais garantie par cascade/contraintes DB non visibles dans le dépôt (à confirmer).

#### F-014 · Capture GPS et sélection de position sur carte
- Catégorie : Adresses
- Description : Récupère la position courante, gère permissions/service GPS, permet d’affiner le point en déplaçant la carte sous une épingle centrale.
- Statut : ✅ Complète
- Où l'utiliser : formulaire adresse `/address/create` ou `/address/:id/edit`, section Localisation.
- Preuves : `lib/features/address_create/address_form_screen.dart:101-147`, `lib/features/address_create/address_form_screen.dart:389-451`, `lib/features/address_create/address_form_screen.dart:531-639`.
- Données : aucune écriture DB directe ; met à jour état local latitude/longitude/type GPS.
- Permissions et dépendances : `geolocator` (`pubspec.yaml:20`), `permission_handler` (`pubspec.yaml:21`), `flutter_map` ; permissions Android `ACCESS_FINE/COARSE_LOCATION` (`AndroidManifest.xml:6-7`).
- Cas limites gérés : service GPS désactivé, refus/refus définitif avec bouton « Ouvrir les paramètres du téléphone » (`address_form_screen.dart:105-131,401-408`).
- Limites ou manques constatés : précision/timeout de `getCurrentPosition()` non paramétrés explicitement (défaut plugin).

#### F-015 · Photo d’adresse (galerie, upload, suppression)
- Catégorie : Adresses
- Description : Sélectionne une image dans la galerie (redimensionnée max 1600), l’affiche en aperçu, l’upload au bucket `photos` et permet de la retirer.
- Statut : ✅ Complète
- Où l'utiliser : formulaire adresse.
- Preuves : `lib/features/address_create/address_form_screen.dart:76-99`, `lib/features/address_create/address_form_screen.dart:156-164`, `lib/features/address_create/address_form_screen.dart:274-337`.
- Données : Storage `photos` chemin `<addressId>/cover_<timestamp>.<ext>` (`address_form_screen.dart:159-164`) ; champ `addresses.photo_url`.
- Permissions et dépendances : `image_picker` (`pubspec.yaml:28`), permissions Android caméra/médias déclarées (`AndroidManifest.xml:10-14`, iOS `NSPhotoLibrary*` `Info.plist:27-30`).
- Cas limites gérés : extension normalisée/sécurisée fallback `jpg` (`address_form_screen.dart:84-86`).
- Limites ou manques constatés : source galerie uniquement (pas de capture caméra dans ce formulaire) malgré permission CAMERA déclarée.

#### F-016 · Consultation du détail d’une adresse
- Catégorie : Adresses
- Description : Affiche la fiche complète (photo, infos, GPS, carte/trajet, repères, étapes) et adapte les actions selon propriétaire.
- Statut : ✅ Complète
- Où l'utiliser : `Accueil/Recherche/Favoris` → `/address/:id`.
- Preuves : `lib/features/address_detail/address_detail_screen.dart:57-93`, `lib/features/address_detail/address_detail_screen.dart:394-669`, `lib/core/router.dart:292-300`.
- Données : `addresses.select().eq(id).maybeSingle()`, `landmarks.select().order(position_order)`, `route_steps.select().order(step_order)` (`address_detail_screen.dart:66-83`).
- Permissions et dépendances : `supabase_flutter`, `flutter_map`, composants trajet.
- Cas limites gérés : adresse introuvable -> état vide + retour liste (`address_detail_screen.dart:71-78,414-425`) ; erreurs réseau/DB -> `AppErrorState`.
- Limites ou manques constatés : propriétaire déterminé côté client par `ownerId == currentUser.id` (`address_detail_screen.dart:52-54`) ; règle d’accès réelle dépend RLS.

### Repères

#### F-017 · Repères : création, détail, modification, suppression
- Catégorie : Repères
- Description : Permet au propriétaire d’ajouter, consulter, modifier et supprimer des repères d’une adresse, avec affichage des étapes associées dans le détail.
- Statut : ✅ Complète
- Où l'utiliser : `/address/:id` section « Repères » ; détail repère (tap) ; `/address/:id/steps` (page repères).
- Preuves : `lib/features/address_detail/address_detail_screen.dart:225-323`, `lib/features/address_detail/address_detail_screen.dart:581-635`, `lib/features/address_detail/widgets/landmark_form_sheet.dart:24-47`, `lib/features/address_detail/widgets/landmark_form_sheet.dart:92-137`, `lib/features/address_detail/widgets/landmark_detail_sheet.dart:20-170`.
- Données : `landmarks.insert/update/delete().select()`, lecture `route_steps` associées par `landmark_id`.
- Permissions et dépendances : `image_picker`, `supabase_flutter`.
- Cas limites gérés : suppression confirmée et vérifiée (`delete().select()` vide signalé) (`address_detail_screen.dart:247-279`) ; suppression repère ne supprime pas les étapes (message aide) (`help_content.dart:904-906`).
- Limites ou manques constatés : le formulaire repère ne saisit pas latitude/longitude (champs existent au modèle mais non édités) (`landmark_form_sheet.dart:49-53,109-118`).

#### F-018 · Photo de repère et stockage
- Catégorie : Repères
- Description : Ajoute/remplace la photo d’un repère via galerie, l’upload dans `photos/<addressId>/` et supprime l’ancienne photo si remplacée/supprimée.
- Statut : ✅ Complète
- Où l'utiliser : feuille « Nouveau repère » / « Modifier le repère ».
- Preuves : `lib/features/address_detail/widgets/landmark_form_sheet.dart:65-90`, `lib/features/address_detail/widgets/landmark_form_sheet.dart:124-136`, `lib/core/photo_storage.dart:9-28`.
- Données : Storage bucket `photos`, champ `landmarks.photo_url`.
- Permissions et dépendances : `image_picker`, permissions médias.
- Cas limites gérés : aperçu local et suppression de l’ancienne photo best effort (`landmark_form_sheet.dart:133-135`, `photo_storage.dart:26-27`).
- Limites ou manques constatés : aucune compression/limite de taille explicite côté client hormis `maxWidth: 1600` à la sélection.

### Étapes du trajet

#### F-019 · Étapes du trajet : ajout, détail, modification, suppression
- Catégorie : Étapes du trajet
- Description : Gère des instructions textuelles ordonnées avec distance/direction et repère associé optionnel.
- Statut : ✅ Complète
- Où l'utiliser : `/address/:id` section « Étapes du trajet » ; détail étape.
- Preuves : `lib/features/address_detail/address_detail_screen.dart:281-349`, `lib/features/address_detail/address_detail_screen.dart:637-668`, `lib/features/address_detail/widgets/route_step_form_sheet.dart:23-53`, `lib/features/address_detail/widgets/route_step_form_sheet.dart:95-138`, `lib/features/address_detail/widgets/route_step_detail_sheet.dart`.
- Données : `route_steps.insert/update/delete().select()`, lien optionnel `landmark_id`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : instruction obligatoire (`route_step_form_sheet.dart:96-99,166-169`) ; suppression confirmée/vérifiée (`address_detail_screen.dart:298-325`).
- Limites ou manques constatés : pas de réordonnancement drag-and-drop (ordre fixé par `step_order`/ajout séquentiel), cohérent avec aide (`help_content.dart:1065-1078`).

#### F-020 · Assistant de finalisation post-création (repères puis étapes)
- Catégorie : Étapes du trajet / Repères
- Description : Après création d’adresse, guide en deux pages (repères puis étapes) et permet de terminer sans étape.
- Statut : ✅ Complète
- Où l'utiliser : redirection automatique vers `/address/:id/steps` après création.
- Preuves : `lib/features/address_create/step_wizard_screen.dart:16-32`, `lib/features/address_create/step_wizard_screen.dart:118-217`, `lib/features/address_create/address_form_screen.dart:226-230`, `lib/core/router.dart:282-291`.
- Données : `landmarks.select().order(position_order)`, `landmarks` insert via feuille, `route_steps.insert().select().single()`.
- Permissions et dépendances : `supabase_flutter`, `image_picker` (via feuille repère).
- Cas limites gérés : chargement/erreur repères (`step_wizard_screen.dart:221-224`) ; bouton terminer sans étape (`step_wizard_screen.dart:205-214`).
- Limites ou manques constatés : écran de tâche hors shell (barre absente, par conception) (`lib/core/app_scaffold.dart:7-17`).

### Favoris

#### F-021 · Favoris : ajout/retrait, liste, restauration
- Catégorie : Favoris
- Description : Marque/démarque une adresse en favori depuis la fiche ou la recherche, affiche la liste ordonnée et propose « Annuler » après retrait.
- Statut : ✅ Complète
- Où l'utiliser : `/favorites`, étoile sur `/search` et `/address/:id`.
- Preuves : `lib/core/favorites.dart:24-65`, `lib/features/favorites/favorites_screen.dart:20-88`, `lib/features/favorites/favorites_screen.dart:91-168`, `lib/features/search/search_screen.dart:275-306`, `lib/features/address_detail/address_detail_screen.dart:351-367`, `lib/core/router.dart:207-213`.
- Données : table `favorites` (`select/insert/delete`, colonnes `user_id`, `address_id`, `created_at`) ; `addresses.select().inFilter(id, ids)`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : état vide, erreur, refresh pull-to-refresh (`favorites_screen.dart:106-134`) ; ordre conservé selon ids favoris (`favorites_screen.dart:31-42`) ; session absente -> `StateError` (`favorites.dart:10-15`).
- Limites ou manques constatés : l’ajout lit d’abord `isFavorite` via état UI puis écrit (pas de transaction) (`favorites.dart:55-64`) ; comportement si favori pointe vers adresse inaccessible dépend RLS/filtres serveur.

#### F-022 · Visibilité des favoris/adresses liées aux droits
- Catégorie : Favoris / Sécurité et confidentialité
- Description : Le code suppose que la RLS filtre les adresses inaccessibles et que les favoris deviennent invisibles sans nettoyage client.
- Statut : ❓ Non déterminé
- Où l'utiliser : `/favorites`, `/search`.
- Preuves : commentaire/intent `lib/core/favorites.dart:5-9` ; requêtes filtrées côté client `lib/features/favorites/favorites_screen.dart:31-42`.
- Données : `favorites`, `addresses` (politiques RLS non fournies).
- Permissions et dépendances : Supabase RLS côté serveur.
- Cas limites gérés : le client recoupe par ids retournés (`favorites_screen.dart:41`).
- Limites ou manques constatés : aucune politique RLS/version de schéma de base dans le dépôt pour confirmer RG13.

### Recherche

#### F-023 · Recherche d’adresses
- Catégorie : Recherche
- Description : Recherche des adresses par nom/localité et par nom/description de repère, avec périmètres « Tout / Mes adresses / Publiques », favoris et ouverture détail.
- Statut : 🟡 Partielle
- Où l'utiliser : onglet `Recherche` → `/search`.
- Preuves : `lib/features/search/search_screen.dart:47-145`, `lib/features/search/search_screen.dart:147-259`, `lib/core/router.dart:200-206`.
- Données : `addresses` (`select`, `or ilike name/locality`, filtres `owner_id`/`visibility`), `landmarks` (`select address_id,name,description ilike`), `address_permissions` (périmètre partagé), `favorites`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : annulation de requêtes obsolètes via `_requestId` (`search_screen.dart:49-68`) ; champ vide effacé relance (`search_screen.dart:180-186`) ; état vide/erreur/chargement (`search_screen.dart:231-259`).
- Limites ou manques constatés : l’UI expose seulement 3 segments (Tout/Mes adresses/Publiques) alors que `SearchScope.sharedWithMe` et logique `address_permissions` existent dans le code (`search_screen.dart:12,93-104,197-225`) ; recherche sensible à la construction `ilike` et pas de tolérance fautes côté serveur (contrairement à l’aide) ; la table `address_permissions` n’est pas définie dans les migrations fournies.

### Carte

#### F-024 · Carte MapTiler (plan/satellite), marqueurs et attribution
- Catégorie : Carte
- Description : Affiche une carte tuilée MapTiler en mode `hybrid` ou `streets-v2` avec marqueurs, polylignes et attribution.
- Statut : ✅ Complète
- Où l'utiliser : sélection de position (formulaire adresse), fiche/trajet, écran destinataire partagé, guidage.
- Preuves : `lib/widgets/carte_widget.dart:7-133`, `lib/widgets/map_marker.dart:5-33`, `lib/features/address_detail/widgets/trajet_widgets.dart` (usage), `lib/features/navigation/navigation_screen.dart:355-398`.
- Données : aucune DB ; clé `String.fromEnvironment('MAPTILER_KEY')` (`carte_widget.dart:11`).
- Permissions et dépendances : `flutter_map`, `latlong2` (`pubspec.yaml:24-25`), réseau, `INTERNET`.
- Cas limites gérés : attribution affichée (`carte_widget.dart:105-110`) ; `maxNativeZoom: 17` pour tuiles (`carte_widget.dart:100`).
- Limites ou manques constatés : `userAgentPackageName` fixé à `com.example.carnet_adresses_repere` (`carte_widget.dart:99`), différent de l’`applicationId` release (`android/app/build.gradle.kts:26`).

#### F-025 · Bascule plan/satellite et interaction carte
- Catégorie : Carte
- Description : Bascule entre vue plan et satellite, zoom/déplacement, et recentrage contextuel pendant le guidage.
- Statut : ✅ Complète
- Où l'utiliser : cartes de formulaire, trajet, guidage.
- Preuves : `lib/widgets/carte_widget.dart:47-57`, `lib/widgets/map_type_buttons.dart:4-23`, `lib/features/address_create/address_form_screen.dart:564-637`, `lib/features/navigation/navigation_screen.dart:392-397`, `lib/features/navigation/navigation_screen.dart:447-464`.
- Données : aucune.
- Permissions et dépendances : `flutter_map`.
- Cas limites gérés : haptique sur bascule (`carte_widget.dart:49`) ; en guidage, drag désactive le suivi et affiche bouton recentrer (`navigation_screen.dart:392-397,447-464`).
- Limites ou manques constatés : certains écrans masquent le bouton interne et fournissent le leur (comportement configurable) (`carte_widget.dart:33-35,112-129`).

#### F-026 · Carte sans clé / dépendance réseau
- Catégorie : Carte
- Description : Affiche un message explicite si `MAPTILER_KEY` est absente ; la gestion des erreurs de chargement de tuiles/réseau n’est pas spécialisée.
- Statut : 🟡 Partielle
- Où l'utiliser : tout écran contenant `CarteWidget`.
- Preuves : `lib/widgets/carte_widget.dart:61-72`, `README.md:59-61`, `dart_defines.example.json:1-3`.
- Données : aucune.
- Permissions et dépendances : `--dart-define(-from-file)` MapTiler.
- Cas limites gérés : clé vide -> placeholder texte (`carte_widget.dart:61-72`).
- Limites ou manques constatés : pas de détection “carte grise/offline” côté widget ; le contenu d’aide décrit ce cas mais le code n’implémente pas un diagnostic automatique (`help_content.dart:1951-1973`).

### Trajet

#### F-027 · Calcul d’itinéraire OSRM
- Catégorie : Trajet
- Description : Calcule un itinéraire voiture via l’API publique OSRM et retourne géométrie, étapes, distance et durée.
- Statut : ✅ Complète
- Où l'utiliser : section « Trajet » de la fiche adresse/partagée (bouton Itinéraire) et initialisation du guidage.
- Preuves : `lib/core/route_service.dart:67-122`, `lib/features/address_detail/widgets/trajet_widgets.dart` (consommation), `lib/features/navigation/navigation_screen.dart:112-121`.
- Données : HTTP GET externe `https://router.project-osrm.org/route/v1/driving/...` ; aucune donnée Supabase.
- Permissions et dépendances : `http` (`pubspec.yaml:45`), `INTERNET`.
- Cas limites gérés : timeout 15s, statut non 200/code non `Ok`/exception -> `null` (`route_service.dart:78-120`).
- Limites ou manques constatés : service public sans clé ni SLA connu dans le code ; mode voiture uniquement (dur) (`route_service.dart:74`, aide `help_content.dart:1493-1516`).

#### F-028 · Guidage intégré en temps réel
- Catégorie : Trajet
- Description : Ouvre un écran de guidage avec position courante, prochaine manœuvre, distance/temps restants, recalcul hors itinéraire et détection d’arrivée.
- Statut : ✅ Complète
- Où l'utiliser : fiche adresse/partagée → bouton « Guidage » (écran `NavigationScreen`, navigation par `Navigator.push`).
- Preuves : `lib/features/navigation/navigation_screen.dart:13-209`, `lib/features/navigation/navigation_screen.dart:328-466`, `lib/features/address_detail/widgets/trajet_widgets.dart` (lancement).
- Données : `RouteService`, flux `Geolocator.getPositionStream`.
- Permissions et dépendances : `geolocator`, permissions localisation, `flutter_map`, `http`.
- Cas limites gérés : refus/absence GPS -> message et repli Google Maps (`navigation_screen.dart:73-110,339-353`) ; recalcul max toutes les 15s si écart > 60m (`navigation_screen.dart:178-183,151`) ; arrivée < 30m (`navigation_screen.dart:163-170`).
- Limites ou manques constatés : écran non déclaré dans `go_router` (accessible via push interne uniquement) ; dépend fortement du service OSRM/public et du GPS.

#### F-029 · Navigation externe Google Maps
- Catégorie : Trajet
- Description : Ouvre Google Maps en mode voiture vers la destination comme solution principale ou de secours.
- Statut : ✅ Complète
- Où l'utiliser : boutons « Naviguer » (fiche/trajet), secours écran guidage.
- Preuves : `lib/core/navigation_launcher.dart:4-12`, `lib/features/navigation/navigation_screen.dart:349-351`.
- Données : URL `https://www.google.com/maps/dir/?api=1...`.
- Permissions et dépendances : `url_launcher` (`pubspec.yaml:46`), application Google Maps/navigateur externe.
- Cas limites gérés : retourne bool de lancement (`navigation_launcher.dart:11`) ; utilisé en fallback si guidage impossible (`navigation_screen.dart:339-353`).
- Limites ou manques constatés : pas de vérification/feedback explicite si `launchUrl` retourne false dans tous les appelants (non systématiquement traité).

### Partage

#### F-030 · Création de lien de partage
- Catégorie : Partage
- Description : Crée côté serveur un lien de partage avec durée (minutes ou jamais) et limite de personnes, puis propose le partage système.
- Statut : ✅ Complète
- Où l'utiliser : `/address/:id` (propriétaire) → icône partage → feuille « Partager cette adresse ».
- Preuves : `lib/features/address_detail/widgets/share_link_sheet.dart:110-149`, `lib/features/address_detail/widgets/share_link_sheet.dart:275-353`, `supabase/migrations/20261104_000002_creation_lien_cote_serveur.sql:11-80`.
- Données : RPC `create_share_link(p_address_id, p_max_uses, p_duration_minutes)` ; table `share_links`.
- Permissions et dépendances : `share_plus` (`pubspec.yaml:35`), `supabase_flutter`.
- Cas limites gérés : validation durée/max_uses/auth/propriété côté SQL (`20261104_000002...:29-57`) ; messages d’erreur mappés client (`share_link_sheet.dart:151-164`).
- Limites ou manques constatés : base URL de partage hardcodée GitHub Pages (`share_link_sheet.dart:34,166-172`).

#### F-031 · Gestion des liens (liste, historique, repartage, révocation)
- Catégorie : Partage
- Description : Liste les liens d’une adresse avec statut/compteur/expiration, affiche l’historique des accès, permet de repartager et révoquer.
- Statut : ✅ Complète
- Où l'utiliser : feuille de partage d’une adresse.
- Preuves : `lib/features/address_detail/widgets/share_link_sheet.dart:63-108`, `lib/features/address_detail/widgets/share_link_sheet.dart:174-236`, `lib/features/address_detail/widgets/share_link_sheet.dart:238-269`, `lib/features/address_detail/widgets/share_link_sheet.dart:354-447`, `supabase/migrations/20261104_000001_limite_partage_liens.sql:299-326`.
- Données : `share_links`, `share_link_redemptions` (comptage), `share_link_uses` + `profiles` (historique), RPC `revoke_share_link`.
- Permissions et dépendances : `share_plus`, `supabase_flutter`.
- Cas limites gérés : timer de rafraîchissement UI expiration chaque minute (`share_link_sheet.dart:50-54`) ; révocation confirmée et idempotente côté SQL (`20261104_000001...:309-325`) ; états actif/expiré/complet/révoqué (`share_link_sheet.dart:417-433`, `share_link.dart:195-203`).
- Limites ou manques constatés : lecture `share_link_uses` avec jointure `profiles(name,email)` côté client expose des métadonnées au propriétaire selon RLS (politiques non entièrement définies dans dépôt).

#### F-032 · Ouverture d’un lien partagé (`/a/:token`)
- Catégorie : Partage
- Description : Ouvre un lien reçu, demande une action explicite pour consommer/valider l’accès, affiche adresse complète en lecture seule, erreurs et expiration.
- Statut : ✅ Complète
- Où l'utiliser : lien `https://mampionona-rakotovao.github.io/a/<token>` ou `carnetadresses://a/<token>` → `/a/:token`.
- Preuves : `lib/features/share/shared_link_screen.dart:26-103`, `lib/features/share/shared_link_screen.dart:136-234`, `lib/core/shared_with_me.dart:27-113`, `lib/core/router.dart:56-96`, `lib/core/router.dart:224-232`, `supabase/migrations/20261104_000001_limite_partage_liens.sql:105-263`.
- Données : RPC `redeem_share_link(p_token)` (lecture adresse/repères/étapes, comptage, idempotence propriétaire/déjà utilisé).
- Permissions et dépendances : `supabase_flutter`, deep links/app links, réseau.
- Cas limites gérés : codes `auth_required/expired/revoked/full/not_found` traduits (`shared_with_me.dart:100-113`, `shared_link_screen.dart:110-123`) ; minuterie d’expiration côté UI (`shared_link_screen.dart:42-77`) ; pas d’appel auto à l’ouverture (`shared_link_screen.dart:12-14`).
- Limites ou manques constatés : exige authentification (`20261104_000001...:120-123`), contrairement au texte d’aide mentionnant une consultation possible via navigateur/page d’installation (`help_content.dart:1669-1688`, annexe).

#### F-033 · Onglet « Ouvrir un lien » (coller code/lien)
- Catégorie : Partage
- Description : Permet de coller un token ou une URL et d’ouvrir l’adresse partagée dans le même écran via la même logique de rachat serveur.
- Statut : 🟡 Partielle
- Où l'utiliser : shell `Ouvrir un lien` → `/share/open`.
- Preuves : `lib/features/share/redeem_share_screen.dart:23-69`, `lib/features/share/redeem_share_screen.dart:71-125`, `lib/core/app_scaffold.dart:60-80`, `lib/core/router.dart:214-220`.
- Données : RPC `redeem_share_link`.
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : extraction du dernier segment après `/` (`redeem_share_screen.dart:35-39`) ; affichage erreurs/chargement.
- Limites ou manques constatés : pas de validation/feedback si champ vide (retour silencieux) (`redeem_share_screen.dart:41-46`) ; extraction naïve peut être inadéquate pour certains formats inattendus.

#### F-034 · Adresses « Partagées avec moi »
- Catégorie : Partage
- Description : Liste les adresses reçues dont le lien reste valide, avec détails dépliables, ouverture fiche complète et rafraîchissement périodique.
- Statut : 🟡 Partielle
- Où l'utiliser : `Accueil` menu → « Partagées avec moi » → `/shared`.
- Preuves : `lib/features/share/shared_with_me_screen.dart:27-102`, `lib/features/share/shared_with_me_screen.dart:104-315`, `lib/core/shared_with_me.dart:11-16`, `supabase/migrations/20261104_000001_limite_partage_liens.sql:329-374`.
- Données : RPC `get_my_shared_addresses` ; RPC `redeem_share_link` pour charger détails (idempotent côté serveur).
- Permissions et dépendances : `supabase_flutter`.
- Cas limites gérés : recalcul serveur à chaque ouverture/refresh (`_load`) ; timer 30s pour rafraîchir affichage expiration (`shared_with_me_screen.dart:31-34`).
- Limites ou manques constatés : action carte en AppBar ouvre toujours le premier élément si liste non vide (pas sélection contextuelle) (`shared_with_me_screen.dart:118-126`) ; UX « Partagées avec moi » dépend de politiques/tables antérieures non entièrement versionnées dans dépôt.

#### F-035 · Notifications d’ouverture de liens au propriétaire
- Catégorie : Partage
- Description : Au login/session initiale, vérifie les ouvertures récentes de liens et affiche un snack/son de notification au propriétaire.
- Statut : 🟡 Partielle
- Où l'utiliser : global après connexion/démarrage connecté.
- Preuves : `lib/core/share_notifications.dart:18-49`, `lib/core/share_notifications.dart:51-141`, `lib/core/share_notifications.dart:145-227`, `lib/main.dart:108`, `lib/ui/app_feedback.dart` (`notificationOn`).
- Données : `share_link_uses` (select), `share_links` (vérification propriétaire/adresse), `addresses` (noms), `profiles` (nom ouvreur) ; `SharedPreferences` clé `share_open_last_seen_<userId>`.
- Permissions et dépendances : `shared_preferences`, `supabase_flutter`, `audioplayers` (via `AppSnack`/assets sons selon implémentation UI, asset déclaré `pubspec.yaml:67-68`).
- Cas limites gérés : dédoublonnage temporel par `lastSeen` (`share_notifications.dart:61-104`) ; filtre pour ne notifier que les liens du propriétaire (`share_notifications.dart:106-121,151-189`) ; erreurs avalées (`share_notifications.dart:139-140`).
- Limites ou manques constatés : logique client fragile/défensive (requêtes larges puis filtrage, jointures secondaires pouvant être bloquées par RLS) ; migration 20261023 ajoute policy `share_link_uses_select_owner` mais d’autres policies/schémas requis ne sont pas tous dans le dépôt.

### Aide et accompagnement

#### F-036 · Centre d’aide, catégories et articles
- Catégorie : Aide et accompagnement
- Description : Fournit un centre d’aide avec accueil thématique, catégories, articles détaillés, navigation vers écrans cibles et recherche locale.
- Statut : ✅ Complète
- Où l'utiliser : `Accueil` menu → « Aide » → `/aide`, `/aide/categorie/:categorie`, `/aide/:id`.
- Preuves : `lib/features/help/screens/help_center_screen.dart:22-266`, `lib/features/help/screens/help_category_screen.dart`, `lib/features/help/screens/help_article_screen.dart:28-280`, `lib/features/help/data/help_content.dart:1-220`, `lib/features/help/data/help_content.dart:2255-2334`, `lib/core/router.dart:241-265`.
- Données : contenu statique local (`helpArticles`) ; aucune DB distante.
- Permissions et dépendances : `go_router`, `shared_preferences` (feedback article).
- Cas limites gérés : article/catégorie introuvable -> états dédiés (`help_article_screen.dart:82-100`, tests `help_navigation_test.dart`) ; route inconnue -> `NotFoundPage` (`router.dart:154`).
- Limites ou manques constatés : le contenu est volumineux et peut diverger du comportement réel (voir §7).

#### F-037 · Recherche dans l’aide et aides contextuelles
- Catégorie : Aide et accompagnement
- Description : Recherche locale tokenisée/normalisée avec score, snippets, suggestions, et boutons d’aide contextuelle ouvrant des articles pertinents.
- Statut : ✅ Complète
- Où l'utiliser : `/aide` (champ recherche), boutons « ? » sur formulaires/fiche/feuilles (adresse, trajet, partage).
- Preuves : `lib/features/help/data/help_search.dart:18-259`, `lib/features/help/screens/help_center_screen.dart:62-132`, `lib/features/help/widgets/contextual_help_button.dart`, `lib/features/address_create/address_form_screen.dart:253-266`, `lib/features/address_detail/address_detail_screen.dart:524-536`, `lib/features/address_detail/widgets/share_link_sheet.dart:290-301`.
- Données : `SharedPreferences` pour feedback « article utile ? » (`help_article_screen.dart:35-80`).
- Permissions et dépendances : aucune externe spécifique.
- Cas limites gérés : debounce 200ms (`help_center_screen.dart:44-51`) ; aucun résultat + suggestions (`help_center_screen.dart:336-403`) ; feedback négatif propose contact support (`help_article_screen.dart:60-79`).
- Limites ou manques constatés : la qualité de la recherche est heuristique (pas d’indexation persistante).

#### F-038 · Tour de bienvenue (onboarding)
- Catégorie : Aide et accompagnement
- Description : Affiche un tour guidé au premier affichage de l’accueil et permet de le revoir depuis l’aide.
- Statut : ✅ Complète
- Où l'utiliser : `/` (première ouverture) ; `/aide` → « Revoir la visite guidée ».
- Preuves : `lib/features/home/home_screen.dart:38-45`, `lib/core/onboarding.dart:3-20`, `lib/features/help/widgets/onboarding_tour.dart`, `lib/features/help/screens/help_center_screen.dart:259-264`.
- Données : `SharedPreferences` clé `onboarding_vu`.
- Permissions et dépendances : `shared_preferences`.
- Cas limites gérés : vérification `mounted` avant/after async (`home_screen.dart:41-45`) ; persistance marqueur vu (`onboarding.dart:11-14`).
- Limites ou manques constatés : contenu exact du tour dépend du widget `onboarding_tour.dart` (non relu intégralement), déclenchement seulement sur `HomeScreen`.

#### F-039 · Support par e-mail pré-rempli
- Catégorie : Aide et accompagnement
- Description : Construit un message de support avec version app et plateforme, tente d’ouvrir le client mail, sinon copie l’adresse.
- Statut : ✅ Complète
- Où l'utiliser : `/aide` et articles d’aide → « Contacter le support ».
- Preuves : `lib/features/help/support.dart:1-61`, `lib/features/help/screens/help_center_screen.dart:249-253`, `lib/features/help/screens/help_article_screen.dart:68-80`.
- Données : version via `PackageInfo`; description plateforme via `platform_info.dart`.
- Permissions et dépendances : `package_info_plus` (`pubspec.yaml:47`), `url_launcher`, `Clipboard`.
- Cas limites gérés : absence de messagerie -> copie email + message utilisateur (`support.dart:56-60`) ; fallback version `inconnue` (`support.dart:19-21`).
- Limites ou manques constatés : adresse support hardcodée (`support.dart:10`).

### Interface, design et paramètres

#### F-040 · Thème clair/sombre/système persistant
- Catégorie : Interface et design / Paramètres et préférences
- Description : Applique un thème Material 3 clair/sombre, mémorise le choix utilisateur et permet de le changer depuis l’accueil.
- Statut : ✅ Complète
- Où l'utiliser : global ; `Accueil` menu ⋮ → section « Apparence ».
- Preuves : `lib/core/theme/app_theme.dart`, `lib/core/theme/theme_mode_controller.dart:1-56`, `lib/main.dart:106,147,172-204`, `lib/features/home/home_screen.dart:111-163`.
- Données : `SharedPreferences` clé `theme_mode` (`theme_mode_controller.dart:3,18-25`).
- Permissions et dépendances : `shared_preferences`, `MaterialApp.router`.
- Cas limites gérés : mode chargé avant `runApp` pour éviter scintillement (`main.dart:106-107`) ; valeurs invalides ignorées (`theme_mode_controller.dart:21-24`).
- Limites ou manques constatés : quelques infos lint `prefer_const_constructors` dans `app_theme.dart` (`flutter analyze`).

#### F-041 · Barre de navigation flottante (shell)
- Catégorie : Interface et design
- Description : Affiche une barre flottante custom à 4 entrées shell (Accueil/Recherche/Favoris + écran `/share/open` rattaché à Accueil) avec animation, haptique et masquage clavier.
- Statut : ✅ Complète
- Où l'utiliser : routes shell `/`, `/search`, `/favorites`, `/share/open`.
- Preuves : `lib/core/app_scaffold.dart:20-113`, `lib/ui/app_bottom_nav.dart:42-120` (et suite du composant), `lib/core/router.dart:188-222`.
- Données : aucune persistée.
- Permissions et dépendances : `go_router`, composants internes/haptique.
- Cas limites gérés : correspondance exacte d’onglet et routes “home-owned” (`app_scaffold.dart:45-83`) ; navigation par `go` (pas d’empilement) (`app_scaffold.dart:97-99`).
- Limites ou manques constatés : 10 tests échouent dont 3 ciblant directement la barre (ancrage/hauteur) — écart entre attentes tests et implémentation actuelle (`flutter test`, `test/app_bottom_nav_test.dart`).

#### F-042 · Fonds d’écran décoratifs (motifs dessinés)
- Catégorie : Interface et design
- Description : Applique des fonds peints (relevé, rues, hero, calme, vide) via `CustomPainter` derrière les écrans.
- Statut : ✅ Complète
- Où l'utiliser : login/reset/confirm, accueil/recherche/favoris, formulaires, partage, aide, etc.
- Preuves : `lib/ui/app_background.dart:1-160` (et suite), usages `lib/features/home/home_screen.dart:362-366`, `lib/features/auth/auth_screen.dart:155-160`, `lib/features/address_create/address_form_screen.dart:270-273`, `lib/features/help/screens/help_center_screen.dart:88-90`.
- Données : aucune.
- Permissions et dépendances : Flutter painting.
- Cas limites gérés : style `aucun` neutre ; isolation `RepaintBoundary` et exclusion sémantique (`app_background.dart:57-85`).
- Limites ou manques constatés : nombreux tests golden/background présents ; certains échecs globaux peuvent être liés à environnement/pixels attendus (voir §8).

#### F-043 · Design system, composants partagés, feedback et haptique
- Catégorie : Interface et design
- Description : Centralise thème/couleurs/espacements/motion, composants (`AppButton`, `SectionHeader`, `AppStatusChip`, `AppSnack`, états) et retours haptiques.
- Statut : 🟡 Partielle
- Où l'utiliser : transversal.
- Preuves : `lib/core/theme/app_colors.dart`, `lib/core/theme/app_spacing.dart`, `lib/core/theme/app_motion.dart`, `lib/ui/app_button.dart`, `lib/ui/section.dart`, `lib/ui/status_chip.dart`, `lib/ui/app_states.dart:1-220`, `lib/ui/app_feedback.dart` (utilisé), `lib/core/app_haptics.dart`.
- Données : aucune.
- Permissions et dépendances : Flutter services/material.
- Cas limites gérés : mapping d’erreurs techniques vers messages FR (`app_states.dart` via `friendlyErrorMessage`, `lib/ui/app_feedback.dart:104-114` usage) ; états chargement/vide/erreur réutilisables.
- Limites ou manques constatés : `lib/ui/app_skeleton.dart` existe mais n’est pas référencé (⚫ F-049) ; plusieurs `prefer_const_constructors` (`flutter analyze`).

#### F-044 · Animations et transitions
- Catégorie : Interface et design
- Description : Anime la navigation de la barre flottante, les transitions de page et la caméra/étapes du guidage.
- Statut : 🟡 Partielle
- Où l'utiliser : shell, navigation entre routes, guidage.
- Preuves : `lib/ui/app_bottom_nav.dart` (animation contrôlée), `lib/ui/app_page.dart` (utilisé `lib/core/router.dart:158-160`), `lib/features/navigation/navigation_screen.dart:49-72`, `lib/features/navigation/navigation_screen.dart:415-423`.
- Données : aucune.
- Permissions et dépendances : Flutter animation.
- Cas limites gérés : réduction/instantané selon `AppMotion.reduit` (`navigation_screen.dart:60-66`).
- Limites ou manques constatés : couverture et conformité aux attentes visuelles non entièrement validées (tests golden/nav en échec).

#### F-045 · Accessibilité
- Catégorie : Interface et design
- Description : Apporte quelques éléments d’accessibilité (exclusion sémantique du décor, `MediaQuery.withClampedTextScaling`, tooltips/labels sur actions).
- Statut : 🟡 Partielle
- Où l'utiliser : fond décoratif, barre nav, boutons icônes divers.
- Preuves : `lib/ui/app_background.dart:73-74`, `lib/ui/app_bottom_nav.dart:116-119`, tooltips ex. `lib/features/address_detail/address_detail_screen.dart:447-487`, `lib/features/share/shared_link_screen.dart:198-202`.
- Données : aucune.
- Permissions et dépendances : Flutter semantics.
- Cas limites gérés : décor non annoncé aux lecteurs d’écran (`app_background.dart:73`).
- Limites ou manques constatés : pas d’audit sémantique systématique (labels/ordre focus/contrastes dynamiques) prouvé ; pas de test accessibilité dédié.

### Robustesse et états

#### F-046 · Pages introuvables et états vides/erreurs dédiés
- Catégorie : Robustesse
- Description : Gère les routes inconnues, articles/catégories d’aide inconnus, et affiche des états réutilisables chargement/vide/erreur.
- Statut : ✅ Complète
- Où l'utiliser : route inconnue, `/aide/:id` invalide, `/aide/categorie/:x` invalide, écrans de listes/détails.
- Preuves : `lib/core/router.dart:154`, `lib/ui/not_found_page.dart`, `lib/features/help/screens/help_article_screen.dart:82-100`, `lib/features/help/screens/help_category_screen.dart`, `lib/ui/app_states.dart:12-220`.
- Données : aucune.
- Permissions et dépendances : `go_router`.
- Cas limites gérés : boutons de retour/accueil sur états introuvables (preuves écrans aide/tests `help_navigation_test.dart`).
- Limites ou manques constatés : `NotFoundPage` non lu en détail ici (fichier présent) ; comportement exact validé partiellement par tests d’aide.

### Plateformes, distribution, permissions et intégrations

#### F-047 · Configuration plateforme Android/iOS/web (déclarée)
- Catégorie : Plateformes et distribution
- Description : Déclare permissions et intent-filters Android, descriptions de permissions iOS et configuration web de base.
- Statut : 🟡 Partielle
- Où l'utiliser : build/exécution plateforme.
- Preuves : `android/app/src/main/AndroidManifest.xml:2-18,38-73`, `ios/Runner/Info.plist:23-30,49-63`, `web/index.html:1-47`, `web/manifest.json` (présent dans arborescence), `pubspec.yaml:55-68`.
- Données : n/a.
- Permissions et dépendances : Android `INTERNET, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, CAMERA, READ_MEDIA_IMAGES, READ_EXTERNAL_STORAGE(max32)` (`AndroidManifest.xml:3-14`) ; iOS localisation/caméra/photothèque (`Info.plist:23-30`).
- Cas limites gérés : features GPS/caméra marquées non requises (`AndroidManifest.xml:17-18`).
- Limites ou manques constatés : `applicationId`/namespace release `com.pokanel.carnet` vs package manifeste `com.example...`/label/`userAgentPackageName` (`android/app/build.gradle.kts:26,39`, `AndroidManifest.xml:21`, `carte_widget.dart:99`) — incohérence à vérifier ; aucune déclaration App Links/Universal Links côté iOS (`Info.plist` sans `CFBundleURLTypes`/associated domains).

#### F-048 · Page web de secours, téléchargement, `assetlinks.json`, `404.html`
- Catégorie : Plateformes et distribution
- Description : Éléments attendus pour un site de partage/téléchargement (`mampionona-rakotovao.github.io`, `assetlinks.json`, page secours/404) non trouvés dans le dépôt.
- Statut : ⚫ Code mort / absent du dépôt (non prouvé)
- Où l'utiliser : hors app (attendu web public).
- Preuves : absence à la racine/web : `find . -maxdepth 3 -name 'assetlinks.json' -o -name '404.html'` sans résultat ; `web/` ne contient que `index.html`, `manifest.json`, `favicon.png`, `icons/` (`ls web`). L’app référence `https://mampionona-rakotovao.github.io/a/` (`share_link_sheet.dart:34`, `AndroidManifest.xml:56-64`, `router.dart:66-69`).
- Données : n/a.
- Permissions et dépendances : GitHub Pages / hébergement externe.
- Cas limites gérés : n/a dans dépôt.
- Limites ou manques constatés : vérification App Links Android (`autoVerify`) et page secours dépend d’artefacts externes non versionnés.

#### F-049 · Squelettes de chargement UI
- Catégorie : Interface et design
- Description : Composant de skeleton UI présent mais non utilisé par les écrans applicatifs.
- Statut : ⚫ Code mort
- Où l'utiliser : non atteint.
- Preuves : `lib/ui/app_skeleton.dart:1-80` (définitions) ; aucune référence hors sa définition (`grep -rn "app_skeleton|AppSkeleton" lib` → uniquement `lib/ui/app_skeleton.dart`).
- Données : aucune.
- Permissions et dépendances : Flutter.
- Cas limites gérés : n/a.
- Limites ou manques constatés : code non branché ; `flutter analyze` signale des infos de const dans ce fichier.

#### F-050 · Routeur, shell et règles d’accès navigation
- Catégorie : Compte et authentification / Robustesse
- Description : Définit toutes les routes, protège les écrans authentifiés, gère recovery/reset, liens partagés en attente et 404.
- Statut : ✅ Complète
- Où l'utiliser : global.
- Preuves : `lib/core/router.dart:116-303`, `lib/core/app_scaffold.dart:45-113`.
- Données : session `supabase.auth.currentSession`, état auth stream.
- Permissions et dépendances : `go_router`, `supabase_flutter`.
- Cas limites gérés : redirection vers login avec mémorisation lien `/a/:token` (`router.dart:136-141,147-151`) ; interdiction d’accès auth pages quand connecté sauf cas gérés (`router.dart:143-151`) ; recovery force `/reset-password` (`router.dart:129-134`).
- Limites ou manques constatés : `_listenForPasswordRecovery` s’abonne sans annulation stockée localement (`router.dart:107-114`) — fuite théorique mineure sur cycle de vie singleton.

#### F-051 · Tests automatisés et analyse statique
- Catégorie : Tests et outils
- Description : Tests unitaires/widget/golden présents ; analyse et exécution de tests effectuées.
- Statut : 🟡 Partielle
- Où l'utiliser : développement/CI local.
- Preuves : `test/widget_test.dart`, `test/help_search_test.dart`, `test/help_navigation_test.dart`, `test/app_bottom_nav_test.dart`, `test/app_background_test.dart`, `test/goldens/*.png` ; résultats : `flutter analyze` → 24 issues (2 erreurs, 1 warning, 21 infos), `flutter test` → 52 tests, 42 passés, 10 échoués.
- Données : n/a.
- Permissions et dépendances : Flutter SDK/Dart.
- Cas limites gérés : tests couvrent aide/recherche/navigation, fond, bottom nav (partiellement).
- Limites ou manques constatés : erreurs bloquantes de compilation statique détectées dans `share_link_sheet.dart:199-201` et échecs multiples (goldens/nav) ; couverture inexistante prouvée pour auth, Supabase, CRUD, partage réel, GPS/carte/trajet.

#### F-052 · Sécurité et confidentialité (constats factuels)
- Catégorie : Sécurité et confidentialité
- Description : Constate la présence de secrets/config côté client, l’usage de RPC, et les limites de preuve serveur dans le dépôt.
- Statut : ❓ Non déterminé (partiellement observable)
- Où l'utiliser : n/a.
- Preuves : URL + clé anon hardcodées `lib/core/supabase_client.dart:38-39` ; `anonKey` déprécié signalé par analyze ; RPC utilisées `create_share_link/revoke_share_link/redeem_share_link/get_my_shared_addresses` (`share_link_sheet.dart:110,206`, `shared_with_me.dart:14,86`) ; migrations révoquent certains accès directs (`20261104_000001...:386-393`, `20261104_000002...:84-87`).
- Données : `profiles`, `share_link_uses`, `share_link_redemptions`, etc.
- Permissions et dépendances : Supabase Auth/RLS/Storage policies.
- Cas limites gérés : décisions de partage/limites déplacées côté SQL dans migrations récentes (`20261104_000001...`, `20261104_000002...`).
- Limites ou manques constatés : `service_role` non trouvé dans `lib/` (`grep service_role` sans résultat) mais politiques RLS complètes, schéma initial des tables et configuration Storage non fournis ; impossible de certifier l’isolation des données sans accès projet Supabase.

## 4. Carte de l’application

### Routes `go_router` déclarées (`lib/core/router.dart`)

| Route | Écran / builder | Paramètres | Protégée (auth requise) | Atteinte par |
|---|---|---|---|---|
| `/login` | `AuthScreen` (`:156-162`) | — | Non (redirigé vers `/` si connecté) | redirect initial/non connecté, liens auth |
| `/reset-code` | `ResetCodeScreen` (`:163-171`) | `extra: String? email` | Non (accessible non connecté ; connecté redirigé `/` sauf recovery) | `AuthScreen._forgotPassword` push (`lib/features/auth/auth_screen.dart:126`) |
| `/reset-password` | `ResetPasswordScreen` (`:172-178`) | — | Non (forcé par `_isPasswordRecovery`) | recovery flag deep link / `ResetCodeScreen` `go` (`lib/features/auth/reset_code_screen.dart:52`), redirect |
| `/confirm-email` | `ConfirmEmailScreen` (`:179-187`) | `extra: String? email` | Non | inscription sans session (`lib/features/auth/auth_screen.dart:51`) |
| `/` (shell) | `HomeScreen` (`:193-199`) | — | Oui | barre nav, redirects, retours divers (`app_scaffold.dart:47,97`) |
| `/search` (shell) | `SearchScreen` (`:200-206`) | — | Oui | barre nav (`app_scaffold.dart:47,97`), `HomeScreen` « Rechercher » (`home_screen.dart:307`) |
| `/favorites` (shell) | `FavoritesScreen` (`:207-213`) | — | Oui | barre nav (`app_scaffold.dart:47,97`) |
| `/share/open` (shell) | `RedeemShareScreen` (`:214-220`) | — | Oui | shell (onglet implicite/home-owned) (`app_scaffold.dart:60,82`) |
| `/a/:token` | `SharedLinkScreen` (`:224-232`) | `path: token` | Oui (sinon mémorisé puis login) | liens entrants `ouvrirLienEntrant/definirLienInitial` (`router.dart:84-96`), `SharedWithMeScreen` (`lib/features/share/shared_with_me_screen.dart:121-124,203-205,233-235`) |
| `/shared` | `SharedWithMeScreen` (`:234-240`) | — | Oui | menu accueil (`home_screen.dart:124-125`), état vide accueil (`home_screen.dart:286`) |
| `/aide` | `HelpCenterScreen` (`:241-247`) | — | Oui | menu accueil (`home_screen.dart:128`), boutons « Retour au centre d’aide » (`help_article_screen.dart:96-97`), aide contextuelle/erreurs (indirect via navigation aide) |
| `/aide/categorie/:categorie` | `HelpCategoryScreen` (`:248-256`) | `path: categorie` | Oui | `HelpCenterScreen` grille (`help_center_screen.dart:216-218`) |
| `/aide/:id` | `HelpArticleScreen` (`:257-265`) | `path: id` | Oui | `HelpCenterScreen`, tuiles/relations (`help_center_screen.dart:56-58`, `help_article_screen.dart:215-217`) |
| `/address/create` | `AddressFormScreen` (`:266-272`) | — | Oui | menu accueil, état vide (`home_screen.dart:120-121,278`), aide `help_content` routes |
| `/address/:id/edit` | `AddressFormScreen(existingAddress)` (`:273-281`) | `path: id`, `extra: Address?` | Oui | fiche détail (`address_detail_screen.dart:471-474`) |
| `/address/:id/steps` | `StepWizardScreen` (`:282-291`) | `path: id`, `extra: String? addressName` | Oui | création adresse `pushReplacement` (`address_form_screen.dart:226-229`) |
| `/address/:id` | `AddressDetailScreen` (`:292-300`) | `path: id` | Oui | accueil/recherche/favoris (`home_screen.dart:52`, `search_screen.dart:75`, `favorites_screen.dart:49`) |

### Notes de navigation
- **Shell** : `ShellRoute` enveloppe `/`, `/search`, `/favorites`, `/share/open` dans `AppScaffold` (`router.dart:188-222`, `app_scaffold.dart:20-43`).
- **Gardes** : connecté requis pour tout sauf `/login`, `/reset-code`, `/reset-password`, `/confirm-email` (avec règles spécifiques recovery et partage en attente) (`router.dart:122-152`).
- **404** : `errorBuilder` → `NotFoundPage` (`router.dart:154`).

### Écrans inaccessibles / orphelins
- Aucun écran de `lib/features/**/` non relié détecté par les routes/composants lus (tous atteints par route, push, feuille modale, ou widget interne).
- **Orphelin UI (non-écran)** : `lib/ui/app_skeleton.dart` non utilisé (`grep app_skeleton`).
- **Écran sans route déclarée (accessible par push direct)** : `lib/features/navigation/navigation_screen.dart` (`NavigationScreen`) — ouvert depuis widgets trajet (`lib/features/address_detail/widgets/trajet_widgets.dart`, usage) et non via `GoRoute`.

## 5. Modèle de données (vu par le code et le dépôt)

### Tables Supabase utilisées par l’app (colonnes lues/écrites observées)

| Table | Colonnes observées (lecture) | Colonnes observées (écriture) | Relations implicites observées | Fichiers principaux |
|---|---|---|---|---|
| `addresses` | `id, owner_id, name, description, locality, visibility, latitude, longitude, gps_type, photo_url, created_at` | insert `owner_id,name,description,locality,visibility,latitude,longitude,gps_type,photo_url` ; update champs + `photo_url` ; delete par `id` | `owner_id -> auth.user` (client), liée à `landmarks/route_steps/favorites/share_links` | `models/address.dart:41-72`, `home_screen.dart:37-44,247`, `search_screen.dart:106-145`, `address_form_screen.dart:195-224`, `address_detail_screen.dart:66-91,188-192` |
| `landmarks` | `id, address_id, name, description, photo_url, latitude, longitude, position_order, created_at` (selon requêtes) | insert/update via `toInsertJson` (`address_id,name,description,photo_url,latitude,longitude,position_order`) ; delete par `id` | `address_id -> addresses.id`, `route_steps.landmark_id -> landmarks.id` | `models/landmark.dart:23-49`, `address_detail_screen.dart:80-83,255-259`, `landmark_form_sheet.dart:109-123`, `step_wizard_screen.dart:58-62` |
| `route_steps` | `id, address_id, step_order, instruction, distance, direction, landmark_id` | insert/update via `toInsertJson` (`address_id,step_order,instruction,distance,direction,landmark_id`) ; delete par `id` | `address_id -> addresses.id`, `landmark_id -> landmarks.id?` | `models/route_step.dart:20-41`, `address_detail_screen.dart:86-89,311-313`, `route_step_form_sheet.dart:109-128`, `step_wizard_screen.dart:91-107` |
| `favorites` | `address_id, created_at` | insert `user_id,address_id` ; delete par `user_id,address_id` | `user_id -> auth.user`, `address_id -> addresses.id` | `core/favorites.dart:24-64` |
| `profiles` | `id, name, email` (selon contextes) | upsert `id,email?,name?` ; lecture `name/email` pour historique/ouvreurs | `id -> auth.user` | `core/supabase_client.dart:18-25`, `core/share_notifications.dart:218-223`, `share_link_sheet.dart:261-266` |
| `photos` (Storage bucket) | URLs publiques | upload binaire, list/remove | chemins `<addressId>/...` | `address_form_screen.dart:156-164`, `landmark_form_sheet.dart:88-90`, `core/photo_storage.dart:6-50` |
| `share_links` | `id, address_id, created_by, token, status, expires_at, max_uses, used_count, created_at, revoked_at` (modèle/client) + champs lus dans migrations | création/révocation via RPC (insert/update direct révoqué par migration 20261104_000002) | `address_id -> addresses`, `created_by -> user` | `models/share_link.dart:141-193`, `share_link_sheet.dart:67-71,220-223`, migrations `20261104_*` |
| `share_link_redemptions` | `share_link_id, user_id, redeemed_at` (indirect/count/select owner) | insert via RPC `redeem_share_link` | `share_link_id -> share_links`, `user_id -> auth.users` | `share_link_sheet.dart:76-88`, migrations `20261104_000001...:42-103,167-178` |
| `share_link_uses` | `share_link_id, used_by, used_at`, jointure `profiles(name,email)` ; sélection historique/notifications | insert via RPC (client insert révoqué migration 20261104_000001) | `share_link_id -> share_links`, `used_by -> auth.users` | `share_link_uses` queries `core/share_notifications.dart:79-86,261-266`, `share_link_sheet.dart:261-266`, migrations `20261021,20261023,20261102,20261104_000001` |
| `address_permissions` | `address_id` filtré par `user_id` et `revoked_at is null` | aucune écriture trouvée | `address_id -> addresses`, `user_id -> auth.user` (supposé) | `lib/features/search/search_screen.dart:95-104` |

### Fonctions RPC utilisées par l’app
| RPC | Paramètres observés | Usage | Définition visible dans dépôt |
|---|---|---|---|
| `create_share_link` | `p_address_id, p_max_uses, p_duration_minutes` | création de lien | Oui : `supabase/migrations/20261104_000002_creation_lien_cote_serveur.sql:11-80` |
| `revoke_share_link` | `p_link_id` | révocation lien | Oui : `supabase/migrations/20261104_000001_limite_partage_liens.sql:299-326` |
| `redeem_share_link` | `p_token` | ouvrir/consommer lien partagé (lecture contenu) | Oui : `supabase/migrations/20261104_000001_limite_partage_liens.sql:105-263` |
| `get_my_shared_addresses` | — | liste “Partagées avec moi” | Oui : `supabase/migrations/20261104_000001_limite_partage_liens.sql:329-374` (et version antérieure `20261021...`) |

### Buckets Storage
| Bucket | Usage | Preuves |
|---|---|---|
| `photos` | upload photos adresses/repères, URL publiques, suppression fichier/dossier | `address_form_screen.dart:156-164`, `landmark_form_sheet.dart:88-90`, `core/photo_storage.dart:6-50` |

### Écarts modèle dépôt ↔ app (factuels)
- **Défini en SQL mais jamais appelé par l’app (dans `lib/`)** : `record_share_open`, `get_shared_address_full`, `list_shared_with_me` (drop) apparaissent dans migrations (`20261021...`, `20261102...`) ; migrations 20261104 révoquent explicitement `get_shared_address_full` et `record_share_open` pour clients (`20261104_000001...:386-393`). L’app utilise `redeem_share_link` à la place.
- **Appelé/lu par l’app sans définition SQL visible dans le dépôt** : table `address_permissions` (`search_screen.dart:95-104`) ; tables de base `addresses`, `landmarks`, `route_steps`, `favorites`, `profiles`, bucket/policies Storage, et politiques RLS complètes (seules des policies spécifiques partage sont ajoutées dans migrations fournies).

## 6. Permissions et intégrations

### Permissions Android (déclarées vs usage observé)

| Permission / feature | Déclarée | Usage observé dans le code | Remarque |
|---|---|---|---|
| `INTERNET` | Oui (`AndroidManifest.xml:3`) | Supabase, MapTiler, OSRM, partage web | Cohérent |
| `ACCESS_FINE_LOCATION` | Oui (`:6`) | `Geolocator` position/capture/stream (`address_form_screen.dart:133`, `trajet_widgets.dart:73`, `navigation_screen.dart:107-129`) | Cohérent |
| `ACCESS_COARSE_LOCATION` | Oui (`:7`) | Idem (plugin) | Cohérent |
| `CAMERA` | Oui (`:10`) | Non observé : `ImagePicker().pickImage(source: ImageSource.gallery...)` uniquement (`address_form_screen.dart:77-78`, `landmark_form_sheet.dart:66-67`) | **Déclarée mais non utilisée directement** dans le code app |
| `READ_MEDIA_IMAGES` | Oui (`:11`) | Accès galerie via `image_picker` (Android 13+) | Cohérent (dépend plugin) |
| `READ_EXTERNAL_STORAGE` maxSdk 32 | Oui (`:12-14`) | Galerie anciennes versions | Cohérent (dépend plugin) |
| `hardware.location.gps` required=false | Oui (`:17`) | GPS utilisé si dispo | Cohérent |
| `hardware.camera` required=false | Oui (`:18`) | Caméra non utilisée explicitement | Déclarée mais usage direct non prouvé |

**Intents/deep links Android** : launcher (`:39-42`), reset `carnetadresses://reset-password` (`:44-51`), App Link https `mampionona-rakotovao.github.io/a/*` avec `autoVerify=true` (`:53-64`), fallback `carnetadresses://a/<id>` (`:66-73`).

### iOS
- Descriptions usage localisation/caméra/photothèque présentes (`ios/Runner/Info.plist:23-30`).
- **Aucune configuration Universal Links / URL schemes custom détectée** dans `Info.plist` (pas de `CFBundleURLTypes` pour `carnetadresses`, pas d’entitlement visible dans dépôt). L’ouverture de liens partagés/reset côté iOS n’est donc pas prouvée.

### Services externes et dépendances clés
| Service / intégration | Usage prouvé | Dépendance clé/quota/réseau |
|---|---|---|
| Supabase (Auth, PostgREST, RPC, Storage, Realtime stream) | auth, données, photos, partage | URL/clé anon hardcodées `supabase_client.dart:38-39` ; réseau requis ; règles serveur non entièrement versionnées |
| MapTiler | tuiles carte plan/satellite | `MAPTILER_KEY` via `--dart-define` (`carte_widget.dart:11`, `README.md:25-57`) ; quota/service externe |
| OSRM public (`router.project-osrm.org`) | itinéraire voiture + étapes | endpoint public sans clé, timeout 15s (`route_service.dart:74-80`) ; disponibilité/qualité non garanties |
| Google Maps (app externe) | navigation externe | `url_launcher` vers `google.com/maps` (`navigation_launcher.dart:5-11`) |
| GitHub Pages (`mampionona-rakotovao.github.io`) | URL de partage, App Link Android | hardcodé (`share_link_sheet.dart:34`, `router.dart:66`, `AndroidManifest.xml:62`) ; `assetlinks.json`/pages non présents dans dépôt |
| Google Sign-In | auth native/web | `google_sign_in`, `webClientId` hardcodé (`google_auth_service.dart:3-4`) ; config console requise |
| Messagerie système / mailto | support | dépend d’un client mail installé (`support.dart:44-60`) |

## 7. Écarts et anomalies (preuves)

1. **Erreurs de compilation statique détectées par l’analyseur** : `lib/features/address_detail/widgets/share_link_sheet.dart:199-201` contient un doublon de fermeture `],` dans `AlertDialog.actions` (`Expected an identifier`, `Expected to find ')'` — `flutter analyze`). Le fichier peut rester exécutable selon contexte mais l’analyse échoue.
2. **10 tests en échec** (52 total, 42 passés) : échecs signalés sur `test/app_bottom_nav_test.dart` (ex. ancrage/hauteur attendue 588 vs 592, hauteurTotale 150 vs 121.5 aux lignes ~380/413/469 selon sortie) et autres cas listés en fin de `flutter test` (goldens/background/nav inclus). `flutter analyze` rapporte aussi 24 issues.
3. **Lien partage côté client suppose consultation publique web, serveur l’exige authentifié** : l’aide et la page `/a/:token` évoquent un flux accessible via lien/navigateur/Messenger (`help_content.dart:1669-1688`, `shared_link_screen.dart:217-223`) mais `redeem_share_link` retourne `auth_required` si `auth.uid()` est null (`supabase/migrations/20261104_000001_limite_partage_liens.sql:120-123`) ; anciennes RPC publiques ont été révoquées (`20261104_000001...:386-393`).
4. **`/share/open` ouvert depuis la barre shell mais sans item dédié explicite** : le shell définit 3 onglets (`Accueil/Recherche/Favoris`) et rattache `/share/open` à l’onglet Accueil (`lib/core/app_scaffold.dart:47-52,60-61,72-84`) ; l’utilisateur peut y arriver via navigation interne mais la barre n’expose pas un 4e onglet nommé — risque d’ambiguïté UX/testé différemment.
5. **Recherche « Partagées avec moi » codée mais non exposée** : `SearchScope.sharedWithMe` et requête `address_permissions` existent (`lib/features/search/search_screen.dart:12,93-104`) mais `SegmentedButton` ne propose que Tout/Mes adresses/Publiques (`search_screen.dart:197-225`). Comportement potentiellement partiel/inaccessible.
6. **Notifications d’ouverture incomplètes côté client** : `share_link_uses` est interrogé globalement puis filtré côté app (`core/share_notifications.dart:79-121`) ; en pratique la visibilité dépend des RLS/policies non complètes dans le dépôt, et l’app doit refaire des lectures `share_links/addresses/profiles` (`share_notifications.dart:151-224`) pouvant échouer silencieusement (`catch` vide).
7. **`_webRedirectFallback` inutilisé** dans `GoogleSignInButton` (`lib/features/auth/widgets/google_sign_in_button.dart:12`, warning analyze). `AppSkeleton` défini mais jamais utilisé (`lib/ui/app_skeleton.dart`, grep).
8. **Incohérences d’identifiants/packaging** : `applicationId` Gradle `com.pokanel.carnet` (`android/app/build.gradle.kts:26`) vs `namespace` `com.example...` (`:9`), manifest label `carnet_adresses_repere` (`AndroidManifest.xml:21`), `userAgentPackageName` MapTiler `com.example.carnet_adresses_repere` (`carte_widget.dart:99`).
9. **Secrets/config sensibles en dur** : URL et clé Supabase anon dans le binaire/source (`lib/core/supabase_client.dart:38-39`), `webClientId` Google en dur (`services/google_auth_service.dart:3-4`). Clé MapTiler correctement externalisée (`carte_widget.dart:11`, `dart_defines.example.json`).
10. **Textes d’aide potentiellement divergents du comportement réel** : aide affirme consultation possible via navigateur/page « Installer l’application » pour lien reçu (`help_content.dart:1669-1688,1792-1815`) mais le rachat serveur impose auth (`20261104_000001...:120-123`) ; aide mentionne permission caméra dans dépannage photo (`help_content.dart:2140-2143`) alors que le code n’utilise que la galerie (`address_form_screen.dart:77-78`).

## 8. Qualité et tests

### `flutter analyze` (exécuté)
- **Résultat** : 24 issues (2 erreurs, 1 warning, 21 infos) — exécution en ~17.8s.
- **Erreurs** : `lib/features/address_detail/widgets/share_link_sheet.dart:199` `missing_identifier`, `expected_token`.
- **Warning** : `lib/features/auth/widgets/google_sign_in_button.dart:12` `unused_element` (`_webRedirectFallback`).
- **Infos notables** : `deprecated_member_use` (`supabase_client.dart:39` `anonKey`, `route_step_form_sheet.dart:163` `value`), `use_build_context_synchronously` (`address_form_screen.dart` multiples, `search_screen.dart:321`), `prefer_const_constructors/literals` (`app_theme.dart`, `app_skeleton.dart`, `trajet_widgets.dart`).

### `flutter test` (exécuté)
- **Résultat** : 52 tests, **42 passés, 10 échoués** (arrêt avec « Some tests failed »).
- **Échecs observés en sortie** :
  - `test/app_bottom_nav_test.dart` : « la barre s'ancre en bas de l'écran du shell » (attendu 588, obtenu 592.0, ~l.380), « ancrée en bas même posée dans le slot bottomNavigationBar » (588 vs 592.0, ~l.413), « hauteurTotale inclut la zone de sécurité » (150 vs 121.5, ~l.469), et autres listés en fin (« Goldens — 3, 4 et 5 onglets... » etc., 6+ supplémentaires).
- **Tests passés couvrant** : recherche d’aide/normalisation/tokens/suggestions/contenu (`test/help_search_test.dart`), navigation aide/404/articles-catégories inconnus/routes (`test/help_navigation_test.dart`, plusieurs cas passants), fond/app_background (plusieurs cas passants), barre nav (cas passants), widget placeholder (`test/widget_test.dart`).

### Couverture par catégorie (factuelle)
| Catégorie | Couverture test prouvée | Non couvert prouvé |
|---|---|---|
| Aide et accompagnement | Recherche aide, contenu, navigation aide/routes erreurs (`help_search_test.dart`, `help_navigation_test.dart`) | UI complète centre d’aide, feedback persistance, tour onboarding, support mail réel |
| Interface/design | Bottom nav, fonds/goldens, déterminisme/perf fond (partiel) (`app_bottom_nav_test.dart`, `app_background_test.dart`) | Thème persistance, accessibilité, animations réelles multi-écrans |
| Compte/auth | — | Login/signup/confirm/reset/Google, gardes routeur auth |
| Adresses/repères/étapes | — | CRUD, formulaires, upload photos, suppression/cascades |
| Favoris/recherche | — | Requêtes Supabase, favoris, périmètres recherche |
| Carte/trajet | — | MapTiler, OSRM, GPS/guidage, Google Maps |
| Partage | — | RPC partage, deep links `/a/:token`, états expiré/complet/révoqué |
| Robustesse/plateforme | — | Gestion offline réelle, intents Android, iOS/web |

## 9. Limites connues pour l’utilisateur (langage simple)

- L’application a besoin d’Internet pour la connexion, la synchronisation, la carte, le calcul d’itinéraire/guidage et le partage en ligne ; il n’y a pas de mode hors-ligne complet prouvé.
- La carte nécessite une clé MapTiler fournie à la compilation ; sans clé, la carte affiche un message d’indisponibilité.
- L’itinéraire calculé dans l’app et le guidage intégré sont prévus pour la voiture uniquement (pas de mode piéton/vélo prouvé).
- Le calcul d’itinéraire dépend d’un service externe (OSRM public) : il peut échouer ou être imprécis selon les zones.
- Les liens de partage demandent une connexion à un compte pour ouvrir l’adresse dans l’app (selon la logique serveur actuelle) ; ils peuvent expirer, être complets ou révoqués.
- Le partage de liens et l’ouverture par lien sont configurés autour d’un site GitHub Pages précis ; le bon fonctionnement hors de ce cadre n’est pas garanti.
- La suppression d’une adresse est définitive ; la suppression de compte n’est pas proposée.
- Le support iOS n’est pas prouvé au même niveau qu’Android (notamment ouverture de liens/app links non configurée dans `Info.plist`).
- Certaines actions dépendent des droits/configuration côté serveur Supabase (règles d’accès, stockage), non entièrement vérifiables dans ce dépôt.

## 10. Annexe : fonctionnalités à confirmer (non vérifiables par le code seul)

1. **Schéma DB complet et politiques RLS/Storage** : les migrations fournies ne couvrent que le partage (`supabase/migrations/*.sql`) ; tables de base (`addresses`, `landmarks`, `route_steps`, `favorites`, `profiles`, `address_permissions`) et policies complètes absentes. *Question : pouvez-vous fournir le schéma SQL/RLS complet (y compris `address_permissions`, bucket `photos` policies) ?*
2. **Comportement réel Supabase Auth (templates, OTP, redirect allow-list)** : la réussite des flux e-mail/code/lien dépend de la configuration projet Supabase. *Question : la confirmation e-mail, le reset par code 6-10 chiffres et les redirects `carnetadresses://...` sont-ils configurés et testés sur le projet actuel ?*
3. **Configuration Google Sign-In** : `webClientId` est hardcodé (`services/google_auth_service.dart:3-4`) mais SHA-1/package/OAuth consent ne sont pas dans le dépôt. *Question : la connexion Google est-elle fonctionnelle sur Android (release/debug) et web avec ce client ?*
4. **App Links / site externe de partage** : l’app pointe vers `https://mampionona-rakotovao.github.io/a/` et déclare `autoVerify` Android, mais `assetlinks.json`, page secours, `404.html` et site ne sont pas dans le dépôt. *Question : le domaine GitHub Pages publie-t-il bien `/.well-known/assetlinks.json`, les pages `/a/<token>` de secours et les deep links fonctionnent-ils en production ?*
5. **Support iOS réel** : absence d’Universal Links/URL schemes custom dans `ios/Runner/Info.plist`. *Question : l’ouverture de `carnetadresses://` et des liens partagés est-elle prévue/configurée sur iOS (entitlements, URL types) ?*
6. **Build/release Android** : incohérences `applicationId`/namespace/package (`android/app/build.gradle.kts:9,26`, manifest/label) et signature release utilisant debug keys (`build.gradle.kts:43-46`). *Question : quel est le package final de publication et la configuration de signature/App Links associée ?*
7. **Notifications d’ouverture au propriétaire** : la fiabilité dépend des policies `share_link_uses/share_links/addresses/profiles` et de données historiques non entièrement modélisées ici. *Question : un propriétaire reçoit-il effectivement une notification à la connexion quand un destinataire ouvre un lien, en conditions réelles RLS ?*
8. **Disponibilité et limites des services externes** : MapTiler (quota/clé valide en build), OSRM public (disponibilité), Google Maps installé. *Question : les clés/quotas MapTiler et la disponibilité OSRM sont-ils validés pour la démonstration/production ?*
9. **Résultats tests en environnement cible** : 10 échecs observés localement (dont goldens et bottom nav). *Question : ces échecs sont-ils attendus dans votre environnement (polices, rendu, version Flutter) ou doivent-ils être considérés comme régressions ?*
10. **Accès lecture partagé anonyme** : l’aide suggère un parcours via page web/navigateur, mais la RPC exige un utilisateur authentifié. *Question : le parcours destinataire attendu est-il “app installée + compte obligatoire” uniquement, ou un accès web anonyme doit-il exister ?*
