/// Catégories du centre d'aide, dans l'ordre d'affichage.
///
/// Les libellés vivent ici uniquement : les écrans et les articles les
/// réutilisent pour éviter les divergences.
enum HelpCategory {
  demarrer('Démarrer', 'Les bases pour utiliser le carnet'),
  adresses('Adresses', 'Créer, modifier et supprimer vos lieux'),
  reperes('Repères', 'Les points visibles qui guident vers le lieu'),
  etapes('Étapes du trajet', 'Décrire le chemin jusqu’à la destination'),
  carte('Carte', 'Plan, satellite et position'),
  trajet('Trajet', 'Itinéraire, guidage et navigation'),
  partage('Partage', 'Envoyer une adresse à quelqu’un'),
  favorisRecherche('Favoris et recherche', 'Retrouver rapidement une adresse'),
  confidentialite(
      'Confidentialité et compte', 'Qui voit quoi, et comment se déconnecter'),
  depannage('Dépannage', 'Ça ne marche pas');

  const HelpCategory(this.label, this.description);

  final String label;
  final String description;
}

/// Article d'aide stocké dans l'application, consultable hors connexion.
class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.categorie,
    required this.titre,
    required this.motsCles,
    required this.resume,
    required this.etapes,
    this.astuces = const [],
    this.articlesLies = const [],
    this.openLabel,
    this.openRoute,
  });

  final String id;
  final HelpCategory categorie;
  final String titre;

  /// Synonymes, variantes et fautes courantes utiles à la recherche.
  final List<String> motsCles;

  /// Résumé en une ou deux phrases.
  final String resume;

  /// Instructions numérotées, dans l'ordre.
  final List<String> etapes;

  /// Conseils courts et facultatifs.
  final List<String> astuces;

  /// Ids d'articles à proposer dans « Voir aussi ».
  final List<String> articlesLies;

  /// Action facultative vers un écran réel de l'application.
  final String? openLabel;
  final String? openRoute;
}
