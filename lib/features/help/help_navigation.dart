import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Routes racines portées par le `ShellRoute` (barre d'onglets).
///
/// Elles ne doivent jamais être empilées : la page du shell existe déjà au
/// bas de la pile. Un `push` duplique sa clé et fait planter go_router
/// (« Null check operator used on a null value » après l'assertion des clés
/// dupliquées). On sélectionne donc l'onglet avec `go`.
const Set<String> helpShellRoutes = {
  '/',
  '/search',
  '/favorites',
  '/share/open',
};

/// Ouvre l'écran associé à une action du centre d'aide.
///
/// - route racine / onglet : `go`, pour ne pas empiler la page du shell ;
/// - écran de tâche (formulaire, adresses partagées…) : `push`, pour garder
///   le bouton Retour de l'écran.
void openHelpRoute(BuildContext context, String route) {
  if (helpShellRoutes.contains(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}
