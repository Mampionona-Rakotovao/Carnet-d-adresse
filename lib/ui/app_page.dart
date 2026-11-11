import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_motion.dart';

/// Transition de page unique pour toute l'application : fondu + glissement
/// vertical de 20 px, 250 ms, identique à l'aller et au retour.
CustomTransitionPage<void> appPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppMotion.page,
    reverseTransitionDuration: AppMotion.page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (AppMotion.reduit(context)) return child;

      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.entree,
        reverseCurve: AppMotion.sortie,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}
