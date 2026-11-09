# Carnet d’adresses par repères

Application Flutter qui permet d’enregistrer un lieu à partir de repères visibles
(portail, boutique, arbre…), puis de le retrouver, de le partager et d’expliquer
comment y aller.

## Fonctionnalités principales

- Création d’adresses avec photo, localité, position GPS et niveau de visibilité.
- Repères et étapes pour décrire précisément le chemin jusqu’au lieu.
- Carte avec vues plan et satellite.
- Recherche par nom, localité ou repère, et adresses favorites.
- Partage d’adresses par lien temporaire.
- Centre d’aide intégré avec recherche, articles, aides contextuelles et visite guidée.
- Contact du support par e-mail avec message pré-rempli.

## Prérequis

- Flutter stable récent (Dart `>=3.3.0`).
- Android SDK pour générer un APK.
- Un compte et une clé [MapTiler](https://www.maptiler.com/) pour afficher la carte.
- Une connexion Internet pour Supabase, la carte et le calcul d’itinéraire.

## Configuration de la clé MapTiler

La clé n’est jamais stockée dans le dépôt. Elle est lue à la compilation via
`--dart-define-from-file`.

1. Copier le fichier d’exemple :

   ```bash
   cp dart_defines.example.json dart_defines.json
   ```

2. Remplacer la valeur d’exemple dans `dart_defines.json` :

   ```json
   {
     "MAPTILER_KEY": "votre_vraie_cle"
   }
   ```

3. Ne jamais committer `dart_defines.json`. Il est déjà ignoré par Git :

   ```bash
   git check-ignore -v dart_defines.json
   ```

Le fichier `dart_defines.example.json`, versionné, ne contient qu’un
emplacement vide et peut être partagé sans risque.

## Lancer l’application

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

Sans clé MapTiler, l’application se lance mais la carte affiche un message
indiquant que la clé est manquante.

## Générer un APK

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```

L’APK est généré dans `build/app/outputs/flutter-apk/`.

Pour un lancement ou une build sans fichier de configuration, il est aussi
possible de passer directement la clé :

```bash
flutter run --dart-define=MAPTILER_KEY=votre_vraie_cle
```

## Configuration de l’e-mail du support

L’adresse utilisée par le bouton « Contacter le support » se trouve dans
`lib/features/help/support.dart` :

```dart
const String supportEmail = 'mampyyonona@gmail.com';
```

Le message pré-rempli contient la version de l’application, lue avec
`package_info_plus`, et la description du système. La version affichée vient de
`pubspec.yaml` ; il suffit donc de modifier le champ `version` du `pubspec.yaml`
pour les prochaines releases.

Si aucune messagerie n’est disponible, l’adresse est automatiquement copiée
dans le presse-papiers et un message le signale à l’utilisateur.

## Tests et analyse statique

```bash
flutter analyze
flutter test
```

Les tests couvrent notamment la recherche dans l’aide et la navigation depuis
les articles, les aides contextuelles et les écrans d’erreur.

## Structure du projet

```text
lib/
  core/           Routeur, thème, Supabase, partage, onboarding, services communs
  features/
    address_create/ Création et modification d’adresses, assistant d’étapes
    address_detail/ Fiche d’adresse, repères, étapes, partage
    auth/           Connexion, inscription, confirmation et mot de passe
    favorites/      Adresses favorites
    help/           Centre d’aide, articles, recherche et support
    home/           Écran d’accueil
    navigation/     Guidage et itinéraire
    search/         Recherche d’adresses
    share/          Liens partagés et adresses reçues
  models/         Modèles de données
  services/       Services externes
  ui/             Composants d’interface communs
  widgets/        Widgets réutilisables (carte, boutons de carte)
test/             Tests unitaires et de widgets
assets/           Sons et ressources embarquées
android/ ios/ web/ Configurations des plateformes
```

## Sécurité

- Ne jamais committer de clé API, de mot de passe ou de fichier `.env`.
- `dart_defines.json` et `.env` sont ignorés par Git.
- Les secrets Supabase de production ne doivent pas être ajoutés à la
  documentation.
