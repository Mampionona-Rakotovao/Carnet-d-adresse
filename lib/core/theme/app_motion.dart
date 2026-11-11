import 'package:flutter/material.dart';

/// Durées et courbes communes à toute l'application.
///
/// Les animations restent courtes et décelérées : elles accompagnent l'action,
/// elles ne se font pas remarquer. Un seul élément bouge à la fois.
abstract final class AppMotion {
  static const Duration rapide = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration lent = Duration(milliseconds: 300);
  static const Duration page = Duration(milliseconds: 250);
  static const Duration succes = Duration(milliseconds: 1500);
  static const Duration skeleton = Duration(milliseconds: 1100);

  static const Curve entree = Curves.easeOutCubic;
  static const Curve sortie = Curves.easeInCubic;
  static const Curve etat = Curves.easeInOutCubic;
  static const Curve appui = Curves.easeOut;
  static const Curve relachement = Curves.easeOutBack;

  /// Vrai quand le système demande de réduire les animations.
  static bool reduit(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Durée à utiliser : nulle si l'utilisateur a demandé moins de mouvement.
  static Duration duree(BuildContext context, Duration duration) =>
      reduit(context) ? Duration.zero : duration;
}
