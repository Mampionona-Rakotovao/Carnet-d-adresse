import 'package:flutter/services.dart';

/// Point d'entrée unique des retours haptiques.
///
/// Facilement désactivable (tests, accessibilité, appareil sans vibreur).
/// Aucune permission n'est nécessaire.
abstract final class AppHaptics {
  static bool enabled = true;

  static Future<void> selectionClick() async {
    if (!enabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Le vibreur est un bonus : on n'interrompt jamais l'action.
    }
  }

  static Future<void> lightImpact() async {
    if (!enabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> mediumImpact() async {
    if (!enabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
