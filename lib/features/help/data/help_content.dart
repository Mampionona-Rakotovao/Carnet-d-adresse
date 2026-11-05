import '../models/help_article.dart';

/// Tous les articles du centre d'aide.
///
/// Ce fichier est la seule source des textes : les écrans, les aides
/// contextuelles et la recherche y puisent tous. Les fonctionnalités
/// décrites sont celles réellement présentes dans l'application.
const List<HelpArticle> helpArticles = [
  // -------------------------------------------------------------------------
  // Démarrer
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'presentation',
    categorie: HelpCategory.demarrer,
    titre: 'À quoi sert Carnet d\'adresses ?',
    motsCles: [
      'application',
      'carnet',
      'adresse',
      'adresses',
      'lieu',
      'lieux',
      'carte',
      'repère',
      'repere',
      'enregistrer',
      'partager',
      'itinéraire',
      'itineraire',
      'gps',
      'position',
    ],
    resume:
        'Carnet d\'adresses vous aide à enregistrer un lieu, le retrouver sur une carte et expliquer comment y aller avec des repères et des étapes.',
    etapes: [
      'Créez un compte ou connectez-vous.',
      'Ajoutez une adresse avec son nom, sa localité et sa position GPS.',
      'Ajoutez une photo, des repères et des étapes pour décrire le chemin.',
      'Retrouvez vos adresses dans Accueil, Recherche et Favoris.',
      'Partagez une adresse avec un lien temporaire.',
    ],
    astuces: [
      'L\'aide et le carnet restent consultables sans connexion une fois l\'application ouverte.',
      'La carte et le calcul d\'itinéraire, eux, ont besoin d\'Internet.',
    ],
    articlesLies: ['accueil', 'creer-adresse', 'creer-partage'],
  ),
  HelpArticle(
    id: 'creer-compte',
    categorie: HelpCategory.demarrer,
    titre: 'Créer un compte',
    motsCles: [
      'inscription',
      'inscrire',
      'compte',
      'créer',
      'creer',
      'nouveau',
      'email',
      'e-mail',
      'mot de passe',
      'google',
    ],
    resume:
        'Un compte permet d\'enregistrer vos adresses et de les retrouver sur un autre téléphone.',
    etapes: [
      'Sur l\'écran de connexion, appuyez sur « Pas de compte ? S\'inscrire ».',
      'Saisissez votre nom, votre adresse e-mail et un mot de passe d\'au moins 6 caractères.',
      'Appuyez sur « S\'inscrire ».',
      'Si un code est demandé, ouvrez l\'e-mail reçu et saisissez le code sur l\'écran « Confirme ton email ».',
    ],
    astuces: [
      'Si vous avez déjà un compte, utilisez « Déjà un compte ? Se connecter ».',
      'Un mot de passe de 6 caractères est le minimum ; choisissez-en un plus long si possible.',
    ],
    articlesLies: ['confirmer-email', 'connexion', 'mot-de-passe'],
  ),
  HelpArticle(
    id: 'confirmer-email',
    categorie: HelpCategory.demarrer,
    titre: 'Confirmer mon adresse e-mail',
    motsCles: [
      'confirmation',
      'confirmer',
      'code',
      'email',
      'e-mail',
      'inscription',
      'valider',
      'renvoyer',
    ],
    resume:
        'Après l\'inscription, un code peut être demandé pour confirmer votre adresse e-mail.',
    etapes: [
      'Ouvrez l\'e-mail envoyé par le service.',
      'Relevez le code de confirmation.',
      'Saisissez-le sur l\'écran « Confirme ton email », puis appuyez sur « Valider ».',
      'Si vous n\'avez rien reçu, appuyez sur « Renvoyer le code ».',
    ],
    astuces: [
      'Vérifiez aussi le dossier « Spam » ou « Courrier indésirable ».',
      'Le code peut contenir 6 à 10 chiffres.',
    ],
    articlesLies: ['creer-compte', 'connexion', 'connexion-impossible'],
  ),
  HelpArticle(
    id: 'connexion',
    categorie: HelpCategory.demarrer,
    titre: 'Se connecter',
    motsCles: [
      'connexion',
      'connecter',
      'login',
      'email',
      'e-mail',
      'mot de passe',
      'google',
      'compte',
    ],
    resume:
        'Connectez-vous avec votre e-mail et votre mot de passe, ou avec votre compte Google.',
    etapes: [
      'Saisissez votre adresse e-mail et votre mot de passe.',
      'Appuyez sur « Se connecter ».',
      'Vous pouvez aussi appuyer sur « Continuer avec Google » et choisir votre compte Google.',
    ],
    astuces: [
      'Si vous avez oublié votre mot de passe, appuyez sur « Mot de passe oublié ? ».',
    ],
    articlesLies: ['mot-de-passe', 'creer-compte', 'connexion-impossible'],
  ),
  HelpArticle(
    id: 'mot-de-passe',
    categorie: HelpCategory.demarrer,
    titre: 'Réinitialiser mon mot de passe',
    motsCles: [
      'mot de passe',
      'oublié',
      'oublie',
      'réinitialiser',
      'reinitialiser',
      'code',
      'reset',
      'connexion',
    ],
    resume:
        'Si vous ne vous souvenez plus de votre mot de passe, recevez un code par e-mail puis choisissez-en un nouveau.',
    etapes: [
      'Sur l\'écran de connexion, appuyez sur « Mot de passe oublié ? ».',
      'Saisissez votre adresse e-mail, puis appuyez sur « Envoyer ».',
      'Ouvrez l\'e-mail reçu et relevez le code de réinitialisation.',
      'Saisissez le code sur l\'écran « Saisis le code reçu à », puis appuyez sur « Valider ».',
      'Choisissez un nouveau mot de passe, confirmez-le, puis appuyez sur « Valider ».',
    ],
    astuces: [
      'Le bouton « Renvoyer le code » attend 30 secondes entre deux envois.',
      'Vérifiez le dossier « Spam » si l\'e-mail n\'arrive pas.',
    ],
    articlesLies: ['connexion', 'confirmer-email', 'connexion-impossible'],
  ),
  HelpArticle(
    id: 'accueil',
    categorie: HelpCategory.demarrer,
    titre: 'Vue d\'ensemble de l\'écran d\'accueil',
    motsCles: [
      'accueil',
      'menu',
      'navigation',
      'liste',
      'adresses récentes',
      'recentes',
      'onglets',
      'déconnexion',
      'deconnexion',
    ],
    resume:
        'L\'accueil regroupe vos adresses récentes, le menu principal et les onglets de navigation.',
    etapes: [
      'La barre du bas propose « Accueil », « Recherche » et « Favoris ».',
      'Sur l\'accueil, la liste « Adresses récentes » montre vos adresses.',
      'Le menu ⋮ en haut à droite propose « Apparence », « Ajouter une adresse », « Partagées avec moi », « Aide » et « Se déconnecter ».',
      'Appuyez sur une adresse pour ouvrir sa fiche complète.',
    ],
    astuces: [
      'Quand la liste est vide, le bouton « Ajouter une adresse » permet de commencer.',
      'La ligne « Partagées avec moi » affiche les adresses reçues par lien et encore valides.',
    ],
    articlesLies: [
      'presentation',
      'creer-adresse',
      'apparence',
      'partagees-avec-moi'
    ],
    openLabel: 'Ouvrir l\'accueil',
    openRoute: '/',
  ),
  HelpArticle(
    id: 'apparence',
    categorie: HelpCategory.demarrer,
    titre: 'Changer l\'apparence (clair ou sombre)',
    motsCles: [
      'thème',
      'theme',
      'apparence',
      'sombre',
      'clair',
      'noir',
      'mode',
      'couleur',
    ],
    resume:
        'L\'application peut suivre le réglage du téléphone ou rester en clair ou en sombre.',
    etapes: [
      'Sur l\'accueil, ouvrez le menu ⋮.',
      'Dans la section « Apparence », choisissez « Système », « Clair » ou « Sombre ».',
      'Le choix est mémorisé sur ce téléphone.',
    ],
    astuces: [
      '« Système » suit le réglage clair/sombre de votre téléphone.',
    ],
    articlesLies: ['accueil'],
  ),

  // -------------------------------------------------------------------------
  // Adresses
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'creer-adresse',
    categorie: HelpCategory.adresses,
    titre: 'Créer une adresse',
    motsCles: [
      'créer',
      'creer',
      'ajouter',
      'adresse',
      'nouveau lieu',
      'nom du lieu',
      'localité',
      'localite',
      'photo',
      'position',
      'gps',
    ],
    resume:
        'Créez une adresse avec un nom, une position GPS et, si vous le souhaitez, une photo et une description.',
    etapes: [
      'Depuis l\'accueil, ouvrez le menu ⋮ puis « Ajouter une adresse ».',
      'Ajoutez une photo si vous le souhaitez (facultatif).',
      'Saisissez le « Nom du lieu » (obligatoire), puis éventuellement une « Description » et une « Localité ».',
      'Appuyez sur « Capturer ma position actuelle », puis ajustez la position sur la carte.',
      'Choisissez « Position exacte » ou « Point d\'accès », puis « Publique » ou « Privée ».',
      'Appuyez sur « Enregistrer ». L\'écran « Finaliser » s\'ouvre pour ajouter des repères et des étapes.',
    ],
    astuces: [
      'Le nom doit permettre de reconnaître le lieu : « Parking derrière la mairie » est plus utile que « Maison ».',
      'Vous pourrez modifier l\'adresse plus tard avec l\'icône crayon de sa fiche.',
    ],
    articlesLies: [
      'position-gps',
      'position-carte',
      'photo-adresse',
      'type-reperage',
      'visibilite',
      'ajouter-repere',
      'ajouter-etape',
    ],
    openLabel: 'Ouvrir le formulaire d\'adresse',
    openRoute: '/address/create',
  ),
  HelpArticle(
    id: 'position-gps',
    categorie: HelpCategory.adresses,
    titre: 'Capturer ma position GPS',
    motsCles: [
      'gps',
      'position',
      'localisation',
      'localiser',
      'capturer',
      'géolocalisation',
      'geolocalisation',
      'autorisation',
      'permission',
    ],
    resume:
        'Le bouton « Capturer ma position actuelle » demande l\'autorisation puis place le point sur votre position.',
    etapes: [
      'Dans le formulaire d\'adresse, appuyez sur « Capturer ma position actuelle ».',
      'Si le téléphone demande l\'autorisation, choisissez « Autoriser » ou « Lors de l\'utilisation de l\'application ».',
      'Attendez quelques secondes : le bouton affiche ensuite les coordonnées trouvées.',
      'Si l\'accès est refusé définitivement, appuyez sur « Ouvrir les paramètres du téléphone » et autorisez la localisation.',
    ],
    astuces: [
      'Placez-vous à l\'extérieur ou près d\'une fenêtre si la position met du temps à arriver.',
      'Activez le GPS dans les réglages du téléphone si un message vous le demande.',
    ],
    articlesLies: [
      'position-carte',
      'type-reperage',
      'position-introuvable',
      'coordonnees-gps',
    ],
  ),
  HelpArticle(
    id: 'position-carte',
    categorie: HelpCategory.adresses,
    titre: 'Choisir la position en déplaçant la carte',
    motsCles: [
      'carte',
      'épingle',
      'epingle',
      'déplacer',
      'deplacer',
      'position',
      'point',
      'ajuster',
      'pin',
      'centrer',
    ],
    resume:
        'Après la capture GPS, l\'épingle reste au centre : faites glisser la carte pour placer le point exact.',
    etapes: [
      'Après « Capturer ma position actuelle », une carte apparaît avec une épingle fixe au centre.',
      'Faites glisser la carte avec un doigt pour amener l\'épingle sur le bon endroit.',
      'Le texte sous l\'épingle affiche les coordonnées retenues.',
      'Utilisez le bouton en haut à droite pour passer en vue plan ou satellite.',
      'Appuyez ensuite sur « Enregistrer ».',
    ],
    astuces: [
      'L\'épingle ne bouge pas : c\'est la carte qui se déplace dessous.',
      'Zoomez avec deux doigts pour être plus précis.',
    ],
    articlesLies: ['position-gps', 'plan-satellite', 'type-reperage'],
  ),
  HelpArticle(
    id: 'photo-adresse',
    categorie: HelpCategory.adresses,
    titre: 'Ajouter une photo à une adresse',
    motsCles: [
      'photo',
      'image',
      'galerie',
      'appareil photo',
      'ajouter',
      'supprimer',
      'aperçu',
      'apercu',
    ],
    resume:
        'La photo est facultative. Elle aide à reconnaître le lieu depuis la route.',
    etapes: [
      'Dans le formulaire, appuyez sur le cadre « Appuyer pour ajouter une photo ».',
      'Choisissez une image dans la galerie du téléphone.',
      'L\'aperçu s\'affiche dans le cadre.',
      'Pour la retirer, appuyez sur « Supprimer la photo », puis enregistrez.',
    ],
    astuces: [
      'La photo est facultative mais aide à reconnaître le lieu.',
      'Une photo nette de l\'entrée ou du portail est souvent plus utile qu\'une photo de loin.',
    ],
    articlesLies: ['creer-adresse', 'photo-ne-senvoie-pas'],
  ),
  HelpArticle(
    id: 'modifier-adresse',
    categorie: HelpCategory.adresses,
    titre: 'Modifier une adresse',
    motsCles: [
      'modifier',
      'éditer',
      'editer',
      'changer',
      'crayon',
      'adresse',
      'photo',
      'position',
      'visibilité',
      'visibilite',
    ],
    resume:
        'Le propriétaire peut modifier le nom, la description, la localité, la photo, la position et la visibilité.',
    etapes: [
      'Ouvrez l\'adresse depuis l\'accueil, la recherche ou les favoris.',
      'Sur la fiche, appuyez sur l\'icône crayon « Modifier ».',
      'Changez le nom, la description, la localité, la photo, la position ou la visibilité.',
      'Appuyez sur « Enregistrer les modifications ».',
    ],
    astuces: [
      'Seul le propriétaire de l\'adresse voit les icônes « Modifier » et « Supprimer ».',
    ],
    articlesLies: ['creer-adresse', 'supprimer-adresse'],
  ),
  HelpArticle(
    id: 'supprimer-adresse',
    categorie: HelpCategory.adresses,
    titre: 'Supprimer une adresse',
    motsCles: [
      'supprimer',
      'effacer',
      'corbeille',
      'adresse',
      'irréversible',
      'irreversible',
      'perdu',
      'disparu',
    ],
    resume:
        'La suppression d\'une adresse est définitive et emporte aussi ses repères, ses étapes et ses liens de partage.',
    etapes: [
      'Ouvrez la fiche de l\'adresse.',
      'Appuyez sur l\'icône corbeille « Supprimer ».',
      'Lisez la confirmation, puis appuyez sur « Supprimer ».',
    ],
    astuces: [
      'La suppression est irréversible.',
      'Elle supprime aussi les repères, les étapes, les favoris et les liens de partage liés à cette adresse.',
      'Les personnes qui avaient reçu un lien ne peuvent plus ouvrir l\'adresse.',
    ],
    articlesLies: ['modifier-adresse', 'adresse-disparue'],
  ),
  HelpArticle(
    id: 'coordonnees-gps',
    categorie: HelpCategory.adresses,
    titre: 'À quoi servent les coordonnées GPS ?',
    motsCles: [
      'coordonnées',
      'coordonnees',
      'gps',
      'latitude',
      'longitude',
      'position',
      'chiffres',
      'point',
    ],
    resume:
        'Les coordonnées indiquent l\'emplacement exact du lieu sur la carte. Elles servent à afficher le point et à calculer un itinéraire.',
    etapes: [
      'Ouvrez une adresse : la section « Coordonnées GPS » affiche deux nombres.',
      'Le premier est la latitude, le second la longitude.',
      'Ces nombres sont utilisés par la carte, l\'itinéraire et le guidage.',
      'Pour changer le point, modifiez l\'adresse et déplacez la carte.',
    ],
    astuces: [
      'Vous n\'avez pas besoin de recopier ces nombres : l\'application les utilise automatiquement.',
      'Un « Point d\'accès » peut se trouver à l\'entrée d\'une zone, plus loin que le lieu lui-même.',
    ],
    articlesLies: ['position-carte', 'type-reperage', 'itineraire'],
  ),
  HelpArticle(
    id: 'visibilite',
    categorie: HelpCategory.adresses,
    titre: 'Adresse publique ou privée',
    motsCles: [
      'publique',
      'public',
      'privée',
      'privee',
      'visibilité',
      'visibilite',
      'qui voit',
      'partage',
    ],
    resume:
        'Une adresse privée n\'est visible que par vous. Une adresse publique apparaît dans la recherche des autres utilisateurs.',
    etapes: [
      'Dans le formulaire d\'adresse, trouvez la section « Visibilité ».',
      'Choisissez « Publique » ou « Privée ».',
      'Le texte sous le choix explique la conséquence.',
      'Appuyez sur « Enregistrer ».',
    ],
    astuces: [
      '« Privée » signifie visible uniquement par vous, sauf si vous créez un lien de partage.',
      '« Publique » rend l\'adresse visible par les autres utilisateurs dans la recherche « Publiques ».',
    ],
    articlesLies: ['qui-voit-adresses', 'creer-adresse', 'creer-partage'],
  ),
  HelpArticle(
    id: 'type-reperage',
    categorie: HelpCategory.adresses,
    titre: 'Position exacte ou point d\'accès ?',
    motsCles: [
      'position exacte',
      'point d\'accès',
      'point dacces',
      'type',
      'repérage',
      'reperage',
      'gps',
      'accès',
      'acces',
    ],
    resume:
        '« Position exacte » place l\'adresse aux coordonnées GPS. « Point d\'accès » désigne le dernier point atteignable, puis les repères et étapes expliquent la suite.',
    etapes: [
      'Dans la section « Localisation », lisez « Type de repérage à confirmer ».',
      'Choisissez « Position exacte » si le point GPS est le lieu lui-même.',
      'Choisissez « Point d\'accès » si le véhicule ne peut pas aller jusqu\'au lieu.',
      'Ajoutez alors des repères et des étapes pour décrire la fin du trajet.',
    ],
    astuces: [
      'En cas de doute, choisissez « Point d\'accès » et ajoutez un repère visible.',
    ],
    articlesLies: ['position-gps', 'ajouter-repere', 'ajouter-etape'],
  ),

  // -------------------------------------------------------------------------
  // Repères
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'quest-ce-repere',
    categorie: HelpCategory.reperes,
    titre: 'Qu\'est-ce qu\'un repère ?',
    motsCles: [
      'repère',
      'repere',
      'point visible',
      'panneau',
      'portail',
      'pharmacie',
      'arbre',
      'photo',
      'description',
    ],
    resume:
        'Un repère est un élément visible sur le chemin : un portail, une pharmacie, un arbre, un panneau. Il aide à reconnaître le bon endroit.',
    etapes: [
      'Les repères apparaissent dans la fiche de l\'adresse, sous la carte.',
      'Ils peuvent avoir une photo et une description.',
      'Ils peuvent être associés à une étape du trajet.',
      'Ils s\'affichent aussi sur la carte quand ils ont des coordonnées.',
    ],
    astuces: [
      'Un bon repère se voit depuis la route et ne change pas souvent.',
      'Ajoutez un repère par point important, pas trop d\'un coup.',
    ],
    articlesLies: ['ajouter-repere', 'bien-choisir-repere', 'ajouter-etape'],
  ),
  HelpArticle(
    id: 'ajouter-repere',
    categorie: HelpCategory.reperes,
    titre: 'Ajouter un repère',
    motsCles: [
      'ajouter',
      'créer',
      'creer',
      'repère',
      'repere',
      'photo',
      'nom',
      'description',
      'finaliser',
    ],
    resume:
        'Ajoutez un repère depuis la fiche d\'une adresse ou depuis l\'écran « Finaliser » après sa création.',
    etapes: [
      'Ouvrez la fiche d\'une adresse dont vous êtes propriétaire.',
      'Dans la section « Repères », appuyez sur l\'icône + « Ajouter un repère ».',
      'Ajoutez une photo si vous le souhaitez.',
      'Saisissez le « Nom » (obligatoire) et une « Description ».',
      'Appuyez sur « Enregistrer ».',
    ],
    astuces: [
      'Vous pouvez aussi ajouter un repère juste après la création de l\'adresse, sur l\'écran « Finaliser ».',
    ],
    articlesLies: [
      'quest-ce-repere',
      'bien-choisir-repere',
      'modifier-supprimer-repere',
    ],
  ),
  HelpArticle(
    id: 'modifier-supprimer-repere',
    categorie: HelpCategory.reperes,
    titre: 'Modifier ou supprimer un repère',
    motsCles: [
      'modifier',
      'supprimer',
      'repère',
      'repere',
      'corbeille',
      'changer',
      'photo',
      'description',
    ],
    resume:
        'Appuyez sur un repère pour ouvrir son détail, puis utilisez « Modifier le repère » ou l\'icône corbeille.',
    etapes: [
      'Dans la fiche de l\'adresse, appuyez sur la carte du repère.',
      'Le détail du repère s\'ouvre avec sa photo, sa description et les étapes associées.',
      'Appuyez sur « Modifier le repère » pour changer son nom, sa description ou sa photo.',
      'Appuyez sur l\'icône corbeille « Supprimer » pour le supprimer, puis confirmez.',
    ],
    astuces: [
      'Supprimer un repère ne supprime pas les étapes : celles-ci restent, mais sans repère associé.',
    ],
    articlesLies: ['ajouter-repere', 'modifier-supprimer-etape'],
  ),
  HelpArticle(
    id: 'bien-choisir-repere',
    categorie: HelpCategory.reperes,
    titre: 'Bien choisir un repère',
    motsCles: [
      'bon repère',
      'bon repere',
      'choisir',
      'exemple',
      'pharmacie',
      'portail bleu',
      'arbre',
      'virage',
      'description',
    ],
    resume:
        'Choisissez un élément facile à voir et à décrire, placé avant le lieu ou juste à son entrée.',
    etapes: [
      'Préférez un détail stable : « pharmacie en face », « portail bleu », « grand arbre après le virage ».',
      'Évitez les éléments qui changent souvent : voiture garée, affiche temporaire, couleur d\'un mur.',
      'Ajoutez la distance ou la direction dans la description si elle aide.',
      'Si possible, joignez une photo prise depuis la route.',
    ],
    astuces: [
      'Un repère doit être compris par quelqu\'un qui ne connaît pas le quartier.',
      'Utilisez le même nom que celui que vous diriez à voix haute au chauffeur.',
    ],
    articlesLies: [
      'quest-ce-repere',
      'ajouter-repere',
      'bonne-description-etape'
    ],
  ),

  // -------------------------------------------------------------------------
  // Étapes
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'ajouter-etape',
    categorie: HelpCategory.etapes,
    titre: 'Ajouter une étape du trajet',
    motsCles: [
      'ajouter',
      'créer',
      'creer',
      'étape',
      'etape',
      'instruction',
      'distance',
      'direction',
      'repère associé',
      'repere associe',
    ],
    resume:
        'Une étape décrit une action à faire sur le chemin, avec éventuellement une distance, une direction et un repère.',
    etapes: [
      'Ouvrez la fiche de l\'adresse, puis la section « Étapes du trajet ».',
      'Appuyez sur l\'icône + « Ajouter une étape ».',
      'Saisissez l\'« Instruction » (obligatoire).',
      'Ajoutez si besoin une « Distance (m) », une « Direction » et un « Repère associé ».',
      'Appuyez sur « Enregistrer ».',
    ],
    astuces: [
      'L\'étape est ajoutée à la suite des précédentes.',
      'Vous pouvez aussi ajouter des étapes juste après la création de l\'adresse, sur l\'écran « Finaliser ».',
    ],
    articlesLies: [
      'ordre-etapes',
      'bonne-description-etape',
      'modifier-supprimer-etape'
    ],
  ),
  HelpArticle(
    id: 'ordre-etapes',
    categorie: HelpCategory.etapes,
    titre: 'Comment sont ordonnées les étapes ?',
    motsCles: [
      'ordre',
      'ordonner',
      'numéro',
      'numero',
      'étape',
      'etape',
      'déplacer',
      'deplacer',
      'glisser',
      'réordonner',
      'reordonner',
    ],
    resume:
        'Les étapes sont numérotées automatiquement dans l\'ordre où vous les ajoutez.',
    etapes: [
      'La première étape ajoutée porte le numéro 1, la suivante le numéro 2, et ainsi de suite.',
      'La liste de la fiche suit cet ordre.',
      'Il n\'existe pas encore de bouton pour déplacer une étape par glisser-déposer.',
      'Pour changer l\'ordre, supprimez les étapes concernées puis ajoutez-les dans le bon ordre.',
    ],
    astuces: [
      'Préparez votre itinéraire dans votre tête avant d\'ajouter les étapes pour limiter les corrections.',
    ],
    articlesLies: ['ajouter-etape', 'modifier-supprimer-etape'],
  ),
  HelpArticle(
    id: 'bonne-description-etape',
    categorie: HelpCategory.etapes,
    titre: 'Exemple de bonne description d\'étape',
    motsCles: [
      'exemple',
      'description',
      'étape',
      'etape',
      'instruction',
      'bonne',
      'clair',
      'précis',
      'precis',
    ],
    resume:
        'Une bonne étape indique un point de départ, une action et un repère visible.',
    etapes: [
      'Commencez par le repère que l\'on voit : « Après la pharmacie ».',
      'Indiquez l\'action : « prenez le chemin à droite ».',
      'Ajoutez la distance si elle est utile : « sur 200 m ».',
      'Terminez par le prochain point visible : « jusqu\'au portail bleu ».',
    ],
    astuces: [
      'Exemple complet : « Après la pharmacie en face de l\'école, prenez le chemin à droite sur 200 m, puis arrêtez-vous au portail bleu. »',
      'Évitez les instructions vagues comme « continuez un peu ».',
    ],
    articlesLies: ['ajouter-etape', 'bien-choisir-repere', 'ordre-etapes'],
  ),
  HelpArticle(
    id: 'modifier-supprimer-etape',
    categorie: HelpCategory.etapes,
    titre: 'Modifier ou supprimer une étape',
    motsCles: [
      'modifier',
      'supprimer',
      'étape',
      'etape',
      'corbeille',
      'changer',
      'instruction',
      'distance',
      'direction',
    ],
    resume:
        'Appuyez sur une étape pour ouvrir son détail, puis utilisez « Modifier l\'étape » ou l\'icône corbeille.',
    etapes: [
      'Dans la fiche de l\'adresse, appuyez sur l\'étape concernée.',
      'Le détail de l\'étape s\'ouvre avec son instruction, sa distance, sa direction et son repère associé.',
      'Appuyez sur « Modifier l\'étape » pour la corriger.',
      'Appuyez sur l\'icône corbeille « Supprimer » pour la retirer, puis confirmez.',
    ],
    astuces: [
      'Modifier le texte d\'une étape ne change pas son numéro.',
    ],
    articlesLies: ['ajouter-etape', 'ordre-etapes'],
  ),

  // -------------------------------------------------------------------------
  // Carte
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'plan-satellite',
    categorie: HelpCategory.carte,
    titre: 'Passer en vue plan ou satellite',
    motsCles: [
      'plan',
      'satellite',
      'vue',
      'carte',
      'basculer',
      'changer',
      'image',
    ],
    resume:
        'Le bouton en haut à droite de la carte alterne entre la vue plan et la vue satellite.',
    etapes: [
      'Sur la carte, repérez le bouton en haut à droite.',
      'S\'il affiche une icône de carte, appuyez dessus pour passer en vue plan.',
      'S\'il affiche une icône de satellite, appuyez dessus pour passer en vue satellite.',
      'La carte de la fiche d\'adresse s\'ouvre par défaut en vue satellite.',
    ],
    astuces: [
      'La vue plan est souvent plus lisible pour les noms de rues.',
      'La vue satellite aide à reconnaître les bâtiments et les terrains.',
    ],
    articlesLies: ['zoom-deplacer', 'satellite-flou'],
  ),
  HelpArticle(
    id: 'zoom-deplacer',
    categorie: HelpCategory.carte,
    titre: 'Zoomer et déplacer la carte',
    motsCles: [
      'zoom',
      'zoomer',
      'dézoomer',
      'dezoomer',
      'déplacer',
      'deplacer',
      'glisser',
      'carte',
      'pincer',
    ],
    resume:
        'Pincez avec deux doigts pour zoomer et faites glisser la carte pour la déplacer.',
    etapes: [
      'Pincez avec deux doigts pour zoomer ou dézoomer.',
      'Faites glisser la carte avec un doigt pour la déplacer.',
      'Dans le formulaire d\'adresse, le déplacement sert à ajuster l\'épingle centrale.',
      'Dans le guidage, un déplacement de la carte désactive le suivi automatique.',
    ],
    astuces: [
      'Le niveau de zoom maximal est limité ; au-delà, l\'image peut devenir moins nette.',
    ],
    articlesLies: ['position-carte', 'plan-satellite', 'recentrer-position'],
  ),
  HelpArticle(
    id: 'satellite-flou',
    categorie: HelpCategory.carte,
    titre: 'Pourquoi la carte satellite est parfois floue ?',
    motsCles: [
      'flou',
      'floue',
      'satellite',
      'image',
      'qualité',
      'qualite',
      'net',
      'zoom',
      'campagne',
    ],
    resume:
        'La vue satellite dépend des images disponibles pour la zone et de la connexion. À fort zoom, elle peut être moins nette que la vue plan.',
    etapes: [
      'Essayez de dézoomer légèrement.',
      'Passez en vue plan avec le bouton en haut à droite.',
      'Vérifiez votre connexion internet.',
      'Attendez quelques secondes et réessayez.',
    ],
    astuces: [
      'Dans certaines zones rurales, les images satellite sont anciennes ou peu détaillées.',
      'Le mode plan reste utilisable pour se repérer avec les rues.',
    ],
    articlesLies: ['plan-satellite', 'carte-grise'],
  ),
  HelpArticle(
    id: 'recentrer-position',
    categorie: HelpCategory.carte,
    titre: 'Recentrer la carte sur ma position',
    motsCles: [
      'recentrer',
      'recentrage',
      'position',
      'suivre',
      'suivi',
      'guidage',
      'bouton',
      'flèche',
      'fleche',
    ],
    resume:
        'Pendant le guidage, un bouton flottant permet de revenir sur votre position après avoir déplacé la carte.',
    etapes: [
      'Pendant le guidage, faites glisser la carte pour regarder autour.',
      'Le suivi automatique s\'arrête et un bouton rond avec une flèche apparaît.',
      'Appuyez sur ce bouton pour revenir sur votre position.',
      'Le suivi automatique reprend.',
    ],
    astuces: [
      'Sur la carte d\'une adresse, le bouton de recentrage n\'est pas affiché : utilisez la position de départ de l\'itinéraire.',
    ],
    articlesLies: ['guidage', 'zoom-deplacer'],
  ),

  // -------------------------------------------------------------------------
  // Trajet
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'difference-trajet',
    categorie: HelpCategory.trajet,
    titre: 'Itinéraire, Guidage ou Naviguer : quelle différence ?',
    motsCles: [
      'itinéraire',
      'itineraire',
      'guidage',
      'naviguer',
      'différence',
      'difference',
      'google maps',
      'bouton',
      'trajet',
    ],
    resume:
        '« Itinéraire » affiche le tracé, « Guidage » vous suit en direct, « Naviguer » ouvre Google Maps.',
    etapes: [
      '« Itinéraire » calcule et affiche le tracé, la distance et la durée dans l\'application.',
      '« Guidage » ouvre un écran de suivi en direct avec les instructions de virage.',
      '« Naviguer » ouvre Google Maps pour une navigation externe.',
      'Un bouton coloré indique que son action est active.',
    ],
    astuces: [
      'Utilisez « Itinéraire » pour préparer un trajet, « Guidage » pour être guidé dans l\'application, « Naviguer » si le calcul interne échoue.',
    ],
    articlesLies: ['itineraire', 'guidage', 'naviguer-google-maps'],
  ),
  HelpArticle(
    id: 'itineraire',
    categorie: HelpCategory.trajet,
    titre: 'Calculer un itinéraire',
    motsCles: [
      'itinéraire',
      'itineraire',
      'tracé',
      'trace',
      'distance',
      'durée',
      'duree',
      'calculer',
      'route',
      'trajet',
    ],
    resume:
        'Le bouton « Itinéraire » affiche le tracé, la distance et la durée dans l\'application.',
    etapes: [
      'Ouvrez une adresse.',
      'Appuyez sur « Itinéraire ».',
      'Autorisez la localisation si elle est demandée.',
      'Le tracé apparaît sur la carte avec la distance et la durée.',
      'Appuyez à nouveau sur « Itinéraire » pour masquer le tracé.',
    ],
    astuces: [
      'Le bouton devient coloré quand le tracé est affiché ou en cours de calcul.',
      'Le calcul se fait en voiture et nécessite une connexion internet.',
      'Si aucun itinéraire n\'est trouvé, essayez « Naviguer ».',
    ],
    articlesLies: [
      'difference-trajet',
      'guidage',
      'limites-trajet',
      'aucun-itineraire',
    ],
  ),
  HelpArticle(
    id: 'guidage',
    categorie: HelpCategory.trajet,
    titre: 'Utiliser le guidage en direct',
    motsCles: [
      'guidage',
      'guider',
      'navigation',
      'virage',
      'instruction',
      'recalcul',
      'arrivée',
      'arrivee',
      'suivi',
    ],
    resume:
        'Le guidage suit votre position en direct et affiche la prochaine instruction de virage.',
    etapes: [
      'Ouvrez une adresse, puis appuyez sur « Guidage ».',
      'Autorisez la localisation et activez le GPS si nécessaire.',
      'Suivez la bannière en haut : elle indique la prochaine instruction et la distance.',
      'La barre du bas affiche la distance restante et le temps estimé.',
      'Appuyez sur « Quitter » pour arrêter le guidage.',
    ],
    astuces: [
      'Gardez l\'application ouverte et l\'écran allumé pendant le trajet.',
      'Si vous quittez l\'itinéraire, l\'application recalcule le trajet après quelques secondes.',
      'À l\'arrivée, le message « Vous êtes arrivé » s\'affiche.',
    ],
    articlesLies: [
      'difference-trajet',
      'recentrer-position',
      'guidage-ne-demarre-pas',
      'limites-trajet',
    ],
  ),
  HelpArticle(
    id: 'naviguer-google-maps',
    categorie: HelpCategory.trajet,
    titre: 'Naviguer avec Google Maps',
    motsCles: [
      'naviguer',
      'google maps',
      'google',
      'maps',
      'externe',
      'ouvrir',
      'secours',
    ],
    resume:
        'Le bouton « Naviguer » ouvre Google Maps avec la destination et le mode voiture.',
    etapes: [
      'Ouvrez une adresse.',
      'Appuyez sur « Naviguer ».',
      'Google Maps s\'ouvre avec la destination et le mode voiture.',
      'Revenez à l\'application avec le bouton retour du téléphone.',
    ],
    astuces: [
      '« Naviguer » est utile quand le calcul d\'itinéraire interne ne trouve rien.',
      'L\'application ne contrôle pas l\'interface de Google Maps.',
    ],
    articlesLies: ['difference-trajet', 'aucun-itineraire'],
  ),
  HelpArticle(
    id: 'limites-trajet',
    categorie: HelpCategory.trajet,
    titre: 'Les limites du trajet',
    motsCles: [
      'limite',
      'limites',
      'voiture',
      'rural',
      'campagne',
      'mal cartographié',
      'mal cartographie',
      'internet',
      'piéton',
      'pieton',
      'vélo',
      'velo',
    ],
    resume:
        'Le calcul d\'itinéraire et le guidage sont prévus pour la voiture. Certaines zones rurales sont mal cartographiées.',
    etapes: [
      'Le trajet est calculé en mode voiture uniquement.',
      'Les chemins sans nom ou les zones mal cartographiées peuvent donner un résultat imprécis.',
      'Une connexion internet est nécessaire pour calculer l\'itinéraire et pour le guidage.',
      'En cas d\'échec, utilisez « Naviguer » ou demandez un repère plus précis.',
    ],
    astuces: [
      'Ajoutez des repères et des étapes locales : ils complètent ce que la carte ne montre pas.',
      'Le guidage ne remplace pas le code de la route ni votre jugement.',
    ],
    articlesLies: [
      'itineraire',
      'guidage',
      'naviguer-google-maps',
      'aucun-itineraire',
    ],
  ),

  // -------------------------------------------------------------------------
  // Partage
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'creer-partage',
    categorie: HelpCategory.partage,
    titre: 'Partager une adresse',
    motsCles: [
      'partager',
      'partage',
      'lien',
      'envoyer',
      'créer',
      'creer',
      'sms',
      'messenger',
      'email',
      'e-mail',
    ],
    resume:
        'Créez un lien temporaire, choisissez sa durée et le nombre de personnes, puis envoyez-le.',
    etapes: [
      'Ouvrez l\'adresse dont vous êtes propriétaire.',
      'Appuyez sur l\'icône « Partager » en haut.',
      'Choisissez le « Nombre de personnes » et la « Durée de validité ».',
      'Appuyez sur « Créer le lien ».',
      'Choisissez l\'application de votre choix dans la fenêtre de partage du téléphone.',
    ],
    astuces: [
      'Le lien peut être envoyé par Messenger, SMS, e-mail ou copié.',
      'Seul le propriétaire peut créer et révoquer les liens.',
    ],
    articlesLies: [
      'duree-partage',
      'personnes-partage',
      'revoquer-partage',
      'destinataire-partage',
    ],
  ),
  HelpArticle(
    id: 'duree-partage',
    categorie: HelpCategory.partage,
    titre: 'Choisir la durée d\'un lien de partage',
    motsCles: [
      'durée',
      'duree',
      'validité',
      'validite',
      'expiration',
      'expire',
      '30 minutes',
      '1 heure',
      '7 jours',
      'jamais',
    ],
    resume:
        'La durée de validité va de 30 minutes à « Jamais ». Vous pouvez aussi révoquer un lien avant sa fin.',
    etapes: [
      'Dans le panneau « Partager cette adresse », trouvez « Durée de validité ».',
      'Choisissez une durée : 30 minutes, 1 heure, 2 heures, 5 heures, 12 heures, 24 heures, 7 jours, 30 jours ou Jamais.',
      'Appuyez ensuite sur « Créer le lien ».',
    ],
    astuces: [
      'Une durée courte est plus sûre pour un partage ponctuel.',
      '« Jamais » ne signifie pas que le lien est public : il reste limité aux personnes qui le possèdent.',
      'Vous pouvez révoquer un lien avant sa fin.',
    ],
    articlesLies: ['creer-partage', 'personnes-partage', 'revoquer-partage'],
  ),
  HelpArticle(
    id: 'personnes-partage',
    categorie: HelpCategory.partage,
    titre: 'Limiter le nombre de personnes',
    motsCles: [
      'nombre',
      'personnes',
      'limite',
      'places',
      'illimité',
      'illimite',
      '1 personne',
      '3 personnes',
      '5 personnes',
      'complet',
    ],
    resume:
        'Un lien peut être limité à 1, 3 ou 5 personnes, ou être illimité. Chaque nouvelle personne consomme une place.',
    etapes: [
      'Dans le panneau de partage, ouvrez « Nombre de personnes ».',
      'Choisissez « 1 personne », « 3 personnes », « 5 personnes » ou « Illimité ».',
      'Créez le lien et envoyez-le.',
      'Chaque personne consomme une place en appuyant sur « Voir cette adresse ».',
    ],
    astuces: [
      'Une même personne qui rouvre le lien avec le même compte ne consomme pas une nouvelle place.',
      'Quand toutes les places sont utilisées, le lien devient « Complet ».',
    ],
    articlesLies: [
      'creer-partage',
      'duree-partage',
      'revoquer-partage',
      'erreurs-partage',
    ],
  ),
  HelpArticle(
    id: 'revoquer-partage',
    categorie: HelpCategory.partage,
    titre: 'Révoquer un lien de partage',
    motsCles: [
      'révoquer',
      'revoquer',
      'désactiver',
      'desactiver',
      'lien',
      'supprimer',
      'bloquer',
      'arrêter',
      'arreter',
    ],
    resume:
        'Révoquer un lien empêche toute nouvelle ouverture. Le lien reste visible dans la liste avec le statut « Révoqué ».',
    etapes: [
      'Ouvrez l\'adresse, puis le panneau « Partager cette adresse ».',
      'Dans « Liens existants », repérez le lien à désactiver.',
      'Appuyez sur l\'icône « Révoquer ».',
      'Confirmez : le lien ne fonctionnera plus.',
    ],
    astuces: [
      'Un lien révoqué reste visible dans la liste avec le statut « Révoqué ».',
      'Les personnes qui avaient déjà ouvert l\'adresse peuvent toujours la voir dans « Partagées avec moi » si leur droit n\'a pas expiré.',
    ],
    articlesLies: ['creer-partage', 'erreurs-partage', 'partagees-avec-moi'],
  ),
  HelpArticle(
    id: 'destinataire-partage',
    categorie: HelpCategory.partage,
    titre: 'Que voit la personne qui reçoit le lien ?',
    motsCles: [
      'destinataire',
      'recevoir',
      'reçu',
      'recu',
      'voir',
      'lecture seule',
      'lien',
      'adresse partagée',
      'adresse partagee',
    ],
    resume:
        'Le destinataire voit la fiche complète en lecture seule : photo, carte, repères, étapes et boutons de trajet.',
    etapes: [
      'La personne appuie sur le lien reçu.',
      'Elle voit « Une adresse a été partagée avec toi », puis appuie sur « Voir cette adresse ».',
      'Elle doit être connectée à l\'application.',
      'Elle voit la photo, les informations, les coordonnées, la carte, les repères et les étapes en lecture seule.',
      'Elle peut utiliser « Itinéraire », « Guidage » et « Naviguer ».',
    ],
    astuces: [
      'Le destinataire ne peut pas modifier ni supprimer l\'adresse.',
      'Les liens reçus encore valides apparaissent dans « Partagées avec moi ».',
    ],
    articlesLies: [
      'creer-partage',
      'personnes-partage',
      'erreurs-partage',
      'partagees-avec-moi',
    ],
  ),
  HelpArticle(
    id: 'messenger-partage',
    categorie: HelpCategory.partage,
    titre:
        'Un lien ouvert depuis Messenger affiche « Installer l\'application »',
    motsCles: [
      'messenger',
      'facebook',
      'installer',
      'installer lapplication',
      'navigateur',
      'chrome',
      'ouvrir dans le navigateur',
      'copier',
    ],
    resume:
        'Messenger ouvre parfois les liens dans son navigateur interne, qui ne sait pas lancer l\'application. Il faut ouvrir le lien dans le navigateur du téléphone.',
    etapes: [
      'Sur la page « Installer l\'application », ouvrez le menu ⋮ en haut à droite.',
      'Choisissez « Ouvrir dans le navigateur ».',
      'Si le bouton existe, vous pouvez aussi appuyer sur « Ouvrir dans l\'application ».',
      'Sinon, copiez le lien et collez-le dans Chrome ou dans votre navigateur habituel.',
      'Connectez-vous si l\'application le demande.',
    ],
    astuces: [
      'Le lien reste le même : le copier dans le navigateur ne le casse pas.',
      'Si le lien a expiré entre-temps, demandez-en un nouveau au propriétaire.',
    ],
    articlesLies: [
      'destinataire-partage',
      'erreurs-partage',
      'lien-ne-souvre-pas'
    ],
  ),
  HelpArticle(
    id: 'erreurs-partage',
    categorie: HelpCategory.partage,
    titre: 'Pourquoi un lien ne fonctionne plus ?',
    motsCles: [
      'lien',
      'expiré',
      'expire',
      'complet',
      'révoqué',
      'revoque',
      'désactivé',
      'desactive',
      'invalide',
      'connexion requise',
    ],
    resume:
        'Un lien peut expirer, être complet, être révoqué, ou demander une connexion.',
    etapes: [
      '« Ce lien a expiré » : demandez un nouveau lien au propriétaire.',
      '« Lien complet » : le nombre de personnes autorisé est atteint.',
      '« Ce lien a été désactivé » : le propriétaire l\'a révoqué.',
      '« Connexion requise » : connectez-vous, puis rouvrez le lien.',
      '« Lien invalide » : vérifiez que le lien a été copié en entier.',
    ],
    astuces: [
      'Un lien ouvert depuis Messenger peut aussi afficher une page « Installer l\'application » : ouvrez-le dans le navigateur.',
    ],
    articlesLies: [
      'lien-ne-souvre-pas',
      'messenger-partage',
      'revoquer-partage'
    ],
  ),
  HelpArticle(
    id: 'partagees-avec-moi',
    categorie: HelpCategory.partage,
    titre: 'Retrouver les adresses partagées avec moi',
    motsCles: [
      'partagées avec moi',
      'partagees avec moi',
      'reçu',
      'recu',
      'lien reçu',
      'liste',
      'adresses partagées',
      'adresses partagees',
    ],
    resume:
        'Le menu « Partagées avec moi » liste les adresses reçues par lien et encore valides.',
    etapes: [
      'Sur l\'accueil, ouvrez le menu ⋮.',
      'Appuyez sur « Partagées avec moi ».',
      'La liste affiche les adresses reçues par lien et encore valides.',
      'Appuyez sur une adresse pour afficher ses détails, ou sur l\'icône pour ouvrir la fiche complète.',
      'Tirez la liste vers le bas pour la rafraîchir.',
    ],
    astuces: [
      'Seules les adresses dont le lien est encore valide apparaissent.',
      'L\'icône carte en haut ouvre la première adresse de la liste.',
    ],
    articlesLies: ['destinataire-partage', 'erreurs-partage'],
    openLabel: 'Ouvrir « Partagées avec moi »',
    openRoute: '/shared',
  ),

  // -------------------------------------------------------------------------
  // Favoris et recherche
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'ajouter-favoris',
    categorie: HelpCategory.favorisRecherche,
    titre: 'Ajouter une adresse aux favoris',
    motsCles: [
      'favori',
      'favoris',
      'étoile',
      'etoile',
      'ajouter',
      'retirer',
      'enregistrer',
      'rapide',
    ],
    resume:
        'L\'étoile d\'une adresse l\'ajoute à l\'onglet « Favoris » pour la retrouver plus vite.',
    etapes: [
      'Ouvrez la fiche d\'une adresse.',
      'Appuyez sur l\'étoile en haut à droite.',
      'L\'étoile devient pleine et l\'adresse apparaît dans l\'onglet « Favoris ».',
      'Appuyez à nouveau sur l\'étoile pour la retirer.',
    ],
    astuces: [
      'Vous pouvez aussi ajouter une adresse aux favoris depuis les résultats de recherche, avec l\'étoile à droite.',
      'Dans l\'onglet Favoris, le retrait propose « Annuler ».',
    ],
    articlesLies: ['rechercher-adresse', 'accueil'],
    openLabel: 'Ouvrir les favoris',
    openRoute: '/favorites',
  ),
  HelpArticle(
    id: 'rechercher-adresse',
    categorie: HelpCategory.favorisRecherche,
    titre: 'Rechercher une adresse',
    motsCles: [
      'recherche',
      'rechercher',
      'trouver',
      'nom',
      'localité',
      'localite',
      'repère',
      'repere',
      'filtre',
      'publiques',
    ],
    resume:
        'La recherche trouve une adresse par son nom, sa localité ou le nom d\'un repère.',
    etapes: [
      'Ouvrez l\'onglet « Recherche » dans la barre du bas.',
      'Saisissez un nom, une localité ou un repère.',
      'Choisissez le périmètre : « Tout », « Mes adresses » ou « Publiques ».',
      'Validez avec la touche recherche du clavier.',
      'Appuyez sur un résultat pour ouvrir la fiche.',
    ],
    astuces: [
      'La recherche se lance à la validation clavier ou au changement de périmètre.',
      'Le bouton × efface le champ et relance la recherche.',
      'Les adresses contenant un repère qui correspond sont aussi proposées.',
    ],
    articlesLies: ['astuces-recherche', 'ajouter-favoris'],
    openLabel: 'Ouvrir la recherche',
    openRoute: '/search',
  ),
  HelpArticle(
    id: 'astuces-recherche',
    categorie: HelpCategory.favorisRecherche,
    titre: 'Astuces pour mieux rechercher',
    motsCles: [
      'astuce',
      'recherche',
      'mot',
      'accent',
      'faute',
      'orthographe',
      'localité',
      'localite',
      'repère',
      'repere',
    ],
    resume:
        'Un mot court et distinctif, une localité ou un repère donnent souvent les meilleurs résultats.',
    etapes: [
      'Essayez un mot court et distinctif : « mairie », « portail », « pharmacie ».',
      'Cherchez aussi par localité ou par nom de repère.',
      'Changez le périmètre si le résultat n\'apparaît pas.',
      'Effacez le champ avec × pour revenir à la liste complète.',
    ],
    astuces: [
      'La recherche interne ne corrige pas les fautes de frappe : essayez une autre orthographe.',
      'Les accents peuvent changer le résultat : essayez avec et sans accent.',
    ],
    articlesLies: ['rechercher-adresse', 'ajouter-favoris'],
  ),

  // -------------------------------------------------------------------------
  // Confidentialité et compte
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'qui-voit-adresses',
    categorie: HelpCategory.confidentialite,
    titre: 'Qui peut voir mes adresses ?',
    motsCles: [
      'qui voit',
      'confidentialité',
      'confidentialite',
      'privée',
      'privee',
      'publique',
      'partage',
      'visible',
      'autres',
    ],
    resume:
        'Une adresse privée reste visible par vous seul. Un lien de partage donne un accès en lecture seule pendant la durée choisie.',
    etapes: [
      'Une adresse « Privée » n\'est visible que par vous.',
      'Une adresse « Publique » est visible par les autres utilisateurs dans la recherche « Publiques ».',
      'Un lien de partage donne un accès en lecture seule aux personnes qui l\'ouvrent, pendant la durée choisie.',
      'Seul le propriétaire peut modifier ou supprimer l\'adresse.',
    ],
    astuces: [
      'Ne partagez pas un lien plus longtemps que nécessaire.',
      'Vous pouvez révoquer un lien à tout moment.',
    ],
    articlesLies: ['visibilite', 'position-confidentialite', 'creer-partage'],
  ),
  HelpArticle(
    id: 'position-confidentialite',
    categorie: HelpCategory.confidentialite,
    titre: 'Ma position exacte est-elle visible ?',
    motsCles: [
      'position exacte',
      'coordonnées',
      'coordonnees',
      'gps',
      'visible',
      'confidentialité',
      'confidentialite',
      'privée',
      'privee',
      'sensible',
    ],
    resume:
        'Les coordonnées sont enregistrées avec l\'adresse. Elles sont visibles dans la fiche et sur la carte, et pour les personnes qui ont un lien valide.',
    etapes: [
      'Les coordonnées GPS sont enregistrées avec l\'adresse.',
      'Elles sont affichées dans la fiche et sur la carte.',
      'Une adresse privée n\'est pas visible par les autres utilisateurs, sauf si vous partagez un lien.',
      'Un lien partagé affiche les coordonnées et la carte aux personnes qui l\'ouvrent.',
    ],
    astuces: [
      'Pour un lieu sensible, choisissez « Point d\'accès » et placez le point à l\'entrée plutôt qu\'à la porte.',
      'Révoquez le lien quand il n\'est plus utile.',
    ],
    articlesLies: ['type-reperage', 'visibilite', 'revoquer-partage'],
  ),
  HelpArticle(
    id: 'deconnexion',
    categorie: HelpCategory.confidentialite,
    titre: 'Se déconnecter',
    motsCles: [
      'déconnexion',
      'deconnexion',
      'déconnecter',
      'deconnecter',
      'quitter',
      'compte',
      'supprimer compte',
    ],
    resume:
        'La déconnexion se fait depuis le menu de l\'accueil. Elle ne supprime pas vos adresses.',
    etapes: [
      'Sur l\'accueil, ouvrez le menu ⋮.',
      'Appuyez sur « Se déconnecter ».',
      'Confirmez avec « Déconnexion ».',
      'Vous devrez vous reconnecter pour accéder à vos adresses.',
    ],
    astuces: [
      'La déconnexion ne supprime pas vos adresses.',
      'L\'application ne propose pas encore de suppression de compte.',
    ],
    articlesLies: ['connexion', 'accueil'],
  ),

  // -------------------------------------------------------------------------
  // Dépannage
  // -------------------------------------------------------------------------
  HelpArticle(
    id: 'carte-grise',
    categorie: HelpCategory.depannage,
    titre: 'La carte reste grise ou vide',
    motsCles: [
      'carte',
      'grise',
      'vide',
      'noire',
      'ne charge pas',
      'map',
      'satellite',
      'internet',
      'connexion',
    ],
    resume:
        'La carte a besoin d\'Internet pour charger les images. Un problème de connexion ou de configuration peut la laisser vide.',
    etapes: [
      'Vérifiez que le téléphone est connecté à Internet.',
      'Quittez la fiche et rouvrez-la.',
      'Essayez de passer en vue plan ou satellite avec le bouton en haut à droite.',
      'Si un message « Clé MapTiler manquante » apparaît, l\'application n\'est pas correctement configurée : contactez le support.',
      'Si le problème continue, redémarrez l\'application.',
    ],
    astuces: [
      'La vue satellite peut mettre plus de temps à charger que la vue plan.',
      'L\'aide reste consultable sans connexion, mais pas les images de carte.',
    ],
    articlesLies: ['plan-satellite', 'satellite-flou', 'contact-support'],
  ),
  HelpArticle(
    id: 'position-introuvable',
    categorie: HelpCategory.depannage,
    titre: 'Ma position n\'est pas trouvée',
    motsCles: [
      'position',
      'gps',
      'localisation',
      'introuvable',
      'pas trouvée',
      'pas trouvee',
      'permission',
      'autorisation',
      'réglages',
      'reglages',
    ],
    resume:
        'Le GPS doit être activé et l\'application doit avoir l\'autorisation de localisation.',
    etapes: [
      'Activez le GPS dans les réglages du téléphone.',
      'Vérifiez que la localisation est autorisée pour l\'application : Paramètres > Applications > Carnet d\'adresses > Autorisations > Position.',
      'Sortez à l\'extérieur ou approchez-vous d\'une fenêtre.',
      'Attendez quelques secondes et réessayez « Capturer ma position actuelle ».',
      'Si l\'accès est refusé définitivement, utilisez « Ouvrir les paramètres du téléphone » dans le formulaire.',
    ],
    astuces: [
      'Le nom de l\'application peut apparaître comme « carnet_adresses_repere » dans les réglages Android.',
      'La première position peut prendre plus de temps que les suivantes.',
    ],
    articlesLies: ['position-gps', 'guidage-ne-demarre-pas', 'contact-support'],
  ),
  HelpArticle(
    id: 'aucun-itineraire',
    categorie: HelpCategory.depannage,
    titre: '« Aucun itinéraire trouvé »',
    motsCles: [
      'aucun itinéraire',
      'aucun itineraire',
      'itinéraire',
      'itineraire',
      'pas de route',
      'erreur',
      'trajet',
      'introuvable',
    ],
    resume:
        'Le service de calcul ne trouve pas de route entre votre position et la destination. Cela arrive surtout dans les zones mal cartographiées ou sans connexion.',
    etapes: [
      'Vérifiez votre connexion internet.',
      'Vérifiez que le GPS fonctionne et que votre position est trouvée.',
      'Appuyez sur « Naviguer » pour ouvrir Google Maps.',
      'Si le problème persiste, ajoutez un repère ou un point d\'accès plus facile à atteindre.',
    ],
    astuces: [
      'Le calcul se fait en voiture uniquement.',
      'Un point de destination au milieu d\'une zone sans route peut ne pas être atteignable.',
    ],
    articlesLies: [
      'itineraire',
      'naviguer-google-maps',
      'limites-trajet',
      'contact-support',
    ],
  ),
  HelpArticle(
    id: 'guidage-ne-demarre-pas',
    categorie: HelpCategory.depannage,
    titre: 'Le guidage ne démarre pas ou s\'arrête',
    motsCles: [
      'guidage',
      'démarre pas',
      'demarre pas',
      's\'arrête',
      'sarrete',
      'gps',
      'batterie',
      'écran éteint',
      'ecran eteint',
      'permission',
    ],
    resume:
        'Le guidage a besoin du GPS, de la localisation autorisée et d\'une application maintenue ouverte.',
    etapes: [
      'Vérifiez que le GPS est activé.',
      'Autorisez la localisation pour l\'application.',
      'Gardez l\'application ouverte et l\'écran allumé pendant le trajet.',
      'Vérifiez que le mode économie de batterie ne bloque pas la localisation.',
      'Si le guidage s\'arrête, revenez dans l\'application et relancez-le.',
    ],
    astuces: [
      'Le guidage a besoin d\'Internet pour recalculer l\'itinéraire.',
      'En cas d\'échec répété, utilisez « Naviguer » avec Google Maps.',
    ],
    articlesLies: ['guidage', 'position-introuvable', 'itineraire'],
  ),
  HelpArticle(
    id: 'lien-ne-souvre-pas',
    categorie: HelpCategory.depannage,
    titre: 'Le lien partagé ne s\'ouvre pas',
    motsCles: [
      'lien',
      's\'ouvre pas',
      'souvre pas',
      'partage',
      'expiré',
      'expire',
      'complet',
      'révoqué',
      'revoque',
      'messenger',
      'installer',
    ],
    resume:
        'Un lien peut être incomplet, expiré, complet, révoqué, ou nécessiter une connexion.',
    etapes: [
      'Vérifiez que le lien a été copié en entier.',
      'Connectez-vous à l\'application si « Connexion requise » s\'affiche.',
      'Si le message dit « Ce lien a expiré », demandez un nouveau lien.',
      'Si le message dit « Lien complet », le nombre de personnes est atteint.',
      'Si le message dit « Ce lien a été désactivé », le propriétaire l\'a révoqué.',
      'Si la page « Installer l\'application » s\'affiche depuis Messenger, ouvrez le lien dans le navigateur.',
    ],
    astuces: [
      'Un lien expiré ne peut pas être rallongé : il faut en créer un nouveau.',
      'Le propriétaire peut vérifier l\'état du lien dans « Liens existants ».',
    ],
    articlesLies: [
      'messenger-partage',
      'erreurs-partage',
      'revoquer-partage',
      'contact-support',
    ],
  ),
  HelpArticle(
    id: 'adresse-disparue',
    categorie: HelpCategory.depannage,
    titre: 'Je ne vois plus une adresse',
    motsCles: [
      'adresse',
      'disparue',
      'supprimée',
      'supprimee',
      'plus là',
      'plus la',
      'perdue',
      'introuvable',
      'favori',
    ],
    resume:
        'Une adresse peut avoir été supprimée, ou le lien qui la partageait peut avoir expiré.',
    etapes: [
      'Tirez la liste vers le bas pour la rafraîchir.',
      'Vérifiez si vous avez supprimé l\'adresse par erreur : la suppression est irréversible.',
      'Si l\'adresse vous avait été partagée, le lien a peut-être expiré ou été révoqué.',
      'Si le message « Cette adresse n\'existe plus » s\'affiche, elle a été supprimée par son propriétaire.',
      'Demandez un nouveau lien au propriétaire si nécessaire.',
    ],
    astuces: [
      'Les adresses supprimées ne peuvent pas être restaurées depuis l\'application.',
      'Une adresse retirée des favoris disparaît de l\'onglet Favoris mais reste dans vos adresses.',
    ],
    articlesLies: [
      'supprimer-adresse',
      'erreurs-partage',
      'partagees-avec-moi'
    ],
  ),
  HelpArticle(
    id: 'photo-ne-senvoie-pas',
    categorie: HelpCategory.depannage,
    titre: 'La photo ne s\'envoie pas',
    motsCles: [
      'photo',
      'image',
      'envoie pas',
      'téléverser',
      'televerser',
      'galerie',
      'permission',
      'trop lourde',
      'connexion',
    ],
    resume:
        'L\'application a besoin d\'accéder à la galerie et d\'une connexion pour envoyer la photo.',
    etapes: [
      'Vérifiez que l\'application a accès aux photos : Paramètres > Applications > Carnet d\'adresses > Autorisations > Photos et vidéos.',
      'Choisissez une image plus légère.',
      'Vérifiez votre connexion internet.',
      'Réessayez en enregistrant l\'adresse ou le repère.',
      'Si le message dit que la photo est trop lourde, sélectionnez une autre image.',
    ],
    astuces: [
      'La photo est facultative : vous pouvez enregistrer l\'adresse sans photo.',
      'Une photo prise avec l\'appareil photo puis choisie dans la galerie fonctionne aussi.',
    ],
    articlesLies: ['photo-adresse', 'ajouter-repere', 'contact-support'],
  ),
  HelpArticle(
    id: 'connexion-impossible',
    categorie: HelpCategory.depannage,
    titre: 'Je n\'arrive pas à me connecter',
    motsCles: [
      'connexion',
      'connecter',
      'impossible',
      'mot de passe',
      'email',
      'e-mail',
      'google',
      'confirmé',
      'confirme',
      'trop de tentatives',
    ],
    resume:
        'Vérifiez vos identifiants, la confirmation de l\'e-mail et la connexion Internet.',
    etapes: [
      'Vérifiez l\'adresse e-mail et le mot de passe.',
      'Si vous avez oublié le mot de passe, appuyez sur « Mot de passe oublié ? ».',
      'Si un message dit que l\'e-mail n\'est pas confirmé, vérifiez votre boîte de réception et confirmez le compte.',
      'Si vous utilisez Google, appuyez sur « Continuer avec Google ».',
      'Après trop de tentatives, attendez quelques instants avant de réessayer.',
    ],
    astuces: [
      'Vérifiez le dossier « Spam » pour les e-mails de confirmation.',
      'La connexion Internet est nécessaire pour se connecter.',
    ],
    articlesLies: [
      'connexion',
      'mot-de-passe',
      'confirmer-email',
      'contact-support',
    ],
  ),
  HelpArticle(
    id: 'contact-support',
    categorie: HelpCategory.depannage,
    titre: 'Contacter le support',
    motsCles: [
      'support',
      'contact',
      'contacter',
      'aide',
      'problème',
      'probleme',
      'signaler',
      'bug',
      'email',
      'e-mail',
      'messagerie',
    ],
    resume:
        'Le bouton « Contacter le support » ouvre votre application de messagerie avec un message pré-rempli.',
    etapes: [
      'Ouvrez le centre d\'aide depuis le menu ⋮ de l\'accueil.',
      'Appuyez sur « Contacter le support ».',
      'Votre application de messagerie s\'ouvre avec un message pré-rempli.',
      'Décrivez le problème et envoyez le message.',
      'Si aucune messagerie n\'est installée, copiez l\'adresse affichée et écrivez depuis un autre appareil.',
    ],
    astuces: [
      'Le message contient la version de l\'application et du système, pas vos adresses ni vos mots de passe.',
      'Ne joignez pas de mot de passe ni de code de connexion.',
    ],
    articlesLies: ['connexion-impossible', 'carte-grise'],
  ),
];

const List<String> _featuredIds = [
  'presentation',
  'creer-adresse',
  'difference-trajet',
  'creer-partage',
];

const List<String> _faqIds = [
  'position-introuvable',
  'lien-ne-souvre-pas',
  'aucun-itineraire',
  'carte-grise',
  'photo-ne-senvoie-pas',
];

/// Mots proposés quand une recherche ne donne aucun résultat.
const List<String> helpSuggestionKeywords = [
  'carte',
  'position',
  'partage',
  'lien',
  'repère',
  'itinéraire',
  'photo',
];

/// Articles mis en avant dans la section « Démarrer ».
List<HelpArticle> get helpFeaturedArticles => helpArticlesByIds(_featuredIds);

/// Questions fréquentes affichées sous la section « Démarrer ».
List<HelpArticle> get helpFaqArticles => helpArticlesByIds(_faqIds);

/// Tous les articles d'une catégorie, dans l'ordre du fichier.
List<HelpArticle> helpArticlesForCategory(HelpCategory category) =>
    helpArticles.where((article) => article.categorie == category).toList();

/// Retrouve un article par son identifiant, ou null s'il n'existe pas.
HelpArticle? helpArticleById(String id) {
  for (final article in helpArticles) {
    if (article.id == id) return article;
  }
  return null;
}

/// Retrouve plusieurs articles en conservant l'ordre demandé et en ignorant
/// les identifiants inconnus.
List<HelpArticle> helpArticlesByIds(List<String> ids) {
  final byId = {for (final article in helpArticles) article.id: article};
  return ids
      .map((id) => byId[id])
      .whereType<HelpArticle>()
      .toList(growable: false);
}

/// Convertit un segment d'URL en catégorie, ou null si le nom est inconnu.
HelpCategory? helpCategoryFromName(String name) {
  for (final category in HelpCategory.values) {
    if (category.name == name) return category;
  }
  return null;
}
