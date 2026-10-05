import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rend la barre de navigation aux écrans qui vivent dans le shell.
///
/// La barre est exposée comme widget et non posée sur un `Scaffold` parent :
/// chaque écran a besoin de son propre `Scaffold` (AppBar, SnackBar, bouton
/// flottant), et un `Scaffold` imbriqué ignore la barre du parent. Résultat
/// avant ce correctif : le bouton flottant de l'accueil passait *derrière* la
/// barre et la dernière carte de la liste était inaccessible.
///
/// Usage dans un écran :
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: const Text('Favoris')),
///   body: ...,
///   bottomNavigationBar: ShellNavigationBar.of(context),
/// )
/// ```
class ShellNavigationBar extends InheritedWidget {
  const ShellNavigationBar(
      {super.key, required this.bar, required super.child});

  final Widget bar;

  /// La barre du shell, ou `null` hors du shell (login, lien partagé, détail).
  static Widget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellNavigationBar>()?.bar;

  @override
  bool updateShouldNotify(ShellNavigationBar oldWidget) => false;
}

/// Enveloppe de navigation des écrans racine.
///
/// Le shell contient les trois onglets plus « Ouvrir un lien », qui s'ouvre
/// depuis l'accueil. Le détail d'une adresse, le formulaire et l'assistant
/// d'étapes restent dehors : ce sont des écrans de tâche, et y faire figurer
/// la barre revenait à proposer une navigation qui téléporte hors du
/// formulaire en cours de saisie.
class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  /// Chemins des trois onglets, dans l'ordre de [_destinations].
  static const List<String> _tabPaths = ['/', '/search', '/favorites'];

  /// Écrans du shell rattachés à l'onglet « Accueil » sans en être un :
  /// la barre doit y rester allumée, sinon elle clignote quand on y arrive.
  static const Set<String> _homeOwnedPaths = {'/share/open'};

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Recherche',
    ),
    NavigationDestination(
      icon: Icon(Icons.star_border),
      selectedIcon: Icon(Icons.star),
      label: 'Favoris',
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

    return ShellNavigationBar(
      bar: NavigationBar(
        selectedIndex: currentIndex,
        // `go` et non `push` : changer d'onglet ne doit jamais empiler une page
        // sur l'autre, sinon la pile grossit à chaque aller-retour.
        onDestinationSelected: (index) => context.go(_tabPaths[index]),
        destinations: _destinations,
      ),
      child: child,
    );
  }
}
