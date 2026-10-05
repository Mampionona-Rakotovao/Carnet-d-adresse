import 'package:flutter/material.dart';

/// Échelle d'espacement unique pour toute l'application.
///
/// Toutes les marges et tous les écarts verticaux doivent venir d'ici : c'est
/// ce qui donne à l'interface sa régularité. Un espacement « à l'œil » est
/// presque toujours une erreur de lecture.
abstract final class AppSpacing {
  /// 4 — ajustements très fins (écart entre une icône et son texte).
  static const double xxs = 4;

  /// 8 — espacement interne serré (pastille, badge).
  static const double xs = 8;

  /// 12 — espacement interne standard (carte, feuille).
  static const double sm = 12;

  /// 16 — marge d'écran par défaut.
  static const double md = 16;

  /// 24 — séparation entre deux blocs.
  static const double lg = 24;

  /// 32 — respiration d'un grand bloc.
  static const double xl = 32;

  /// 48 — respiration d'un écran entier.
  static const double xxl = 48;

  /// Marge horizontale d'écran, utilisée par tous les écrans.
  static const double screenH = md;

  /// Padding de liste : évite que le dernier élément soit collé au bord.
  static const EdgeInsets list = EdgeInsets.fromLTRB(md, sm, md, xl);

  /// Padding de formulaire.
  static const EdgeInsets form = EdgeInsets.fromLTRB(md, md, md, xl);

  /// Marge entre le contenu et la barre d'état système.
  static EdgeInsets safeBottom(BuildContext context, {double extra = 0}) =>
      EdgeInsets.only(bottom: extra + MediaQuery.paddingOf(context).bottom);
}

/// Échelle de rayons unique : cartes, champs, dialogues et feuilles.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 28;

  /// Rayon « pastille » (chips, boutons ronds).
  static const Radius pill = Radius.circular(999);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius dialogRadius =
      BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius sheetTopRadius =
      BorderRadius.vertical(top: Radius.circular(xl));
}
