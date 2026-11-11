import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/app_bottom_nav.dart';

/// Enveloppe de navigation des écrans racine.
///
/// Le shell contient les trois onglets plus « Ouvrir un lien », qui s'ouvre
/// depuis l'accueil. Le détail d'une adresse, le formulaire et l'assistant
/// d'étapes restent dehors : ce sont des écrans de tâche, et y faire figurer
/// la barre revenait à proposer une navigation qui téléporte hors du
/// formulaire en cours de saisie.
///
/// Ce widget porte le `Scaffold` le plus haut et y accroche la barre UNE
/// SEULE FOIS, dans le `body` (`Stack` + `Align` bas), et non dans le slot
/// `bottomNavigationBar` : la bulle de l'onglet actif dépasse au-dessus de
/// la barre et doit rester cliquable, ce qu'un slot ne permet pas. Les
/// écrans du shell gardent leur propre `Scaffold` (AppBar, SnackBar) et se
/// contentent de réserver la hauteur de la barre en bas de leurs listes via
/// [AppBottomNav.hauteurTotale].
///
/// `resizeToAvoidBottomInset` est désactivé ici : ce Scaffold ne rétrécit
/// pas pour le clavier. Les `Scaffold` des écrans gardent ainsi la main sur
/// leur propre contenu, et la barre — dans le body, pas dans un slot — voit
/// les `viewInsets` et se masque d'elle-même quand le clavier est ouvert.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  /// Chemins des trois onglets, dans l'ordre de [_onglets].
  static const List<String> _tabPaths = ['/', '/search', '/favorites'];

  /// Écrans du shell rattachés à l'onglet « Accueil » sans en être un :
  /// la barre doit y rester allumée, sinon elle clignote quand on y arrive.
  static const Set<String> _homeOwnedPaths = {'/share/open'};

  /// Onglet allumé lors du précédent passage dans le shell.
  ///
  /// Le shell est reconstruit à chaque changement de page (le routeur
  /// n'utilise pas de branches persistantes), donc la barre repart de zéro :
  /// ce souvenir lui permet d'animer la bulle depuis l'onglet précédent
  /// plutôt que d'apparaître déjà en place.
  static int _ongletPrecedent = 0;

  static const List<AppBottomNavItem> _onglets = [
    AppBottomNavItem(
      label: 'Accueil',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppBottomNavItem(
      label: 'Recherche',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
    ),
    AppBottomNavItem(
      label: 'Favoris',
      icon: Icons.star_border,
      selectedIcon: Icons.star,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Correspondance exacte, et non par préfixe : '/' est un préfixe de tous
    // les chemins, donc '/search' et '/favorites' s'allumaient sur « Accueil ».
    // Les écrans de [_homeOwnedPaths] ne sont pas des onglets et retombent
    // donc sur « Accueil », l'onglet qui mène à cet écran.
    final tabIndex = _tabPaths.indexOf(location);
    final currentIndex = tabIndex < 0 ? 0 : tabIndex;

    assert(
      tabIndex >= 0 || _homeOwnedPaths.contains(location),
      'Route "$location" dans le shell mais absente des onglets ni de '
      '_homeOwnedPaths : la barre affichera un onglet qui ne mène nulle part.',
    );

    final bar = AppBottomNav(
      items: _onglets,
      currentIndex: currentIndex,
      previousIndex: _ongletPrecedent,
      // `go` et non `push` : changer d'onglet ne doit jamais empiler une page
      // sur l'autre, sinon la pile grossit à chaque aller-retour.
      onTap: (index) => context.go(_tabPaths[index]),
    );
    // À lire avant la mise à jour : la prochaine barre créée saura d'où
    // faire glisser sa bulle.
    _ongletPrecedent = currentIndex;

    return Scaffold(
      // Le contenu défile jusqu'en bas de l'écran, derrière la barre
      // flottante posée par-dessus.
      extendBody: true,
      // Voir la doc de classe : le clavier est géré par les écrans, la
      // barre se masque d'elle-même.
      resizeToAvoidBottomInset: false,
      body: Stack(
        // La bulle de l'onglet actif et l'ombre de la barre dépassent
        // légèrement le cadre : jamais rognées.
        clipBehavior: Clip.none,
        children: [
          child,
          Align(
            alignment: Alignment.bottomCenter,
            child: bar,
          ),
        ],
      ),
    );
  }
}
