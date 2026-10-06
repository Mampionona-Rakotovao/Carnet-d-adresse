import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférence de thème : clair, sombre, ou suivi du système.
///
/// Exposée comme [ChangeNotifier] plutôt que par Riverpod : l'application
/// n'utilise Riverpod nulle part, et un seul écran doit écrire cette valeur.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs) {
    _mode = _decode(_prefs.getString(_key)) ?? ThemeMode.system;
  }

  /// Clé de stockage. Les noms de mode sont stockés en clair (`light`,
  /// `dark`, `system`) : relisible dans les préférences de l'appareil.
  static const String _key = 'theme_mode';

  final SharedPreferences _prefs;

  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Applique [mode] et le mémorise. Ne notifie que sur changement réel, pour
  /// ne pas reconstruire l'application entière quand on rouvre le menu.
  Future<void> set(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, _encode(mode));
  }

  /// Les trois valeurs, dans l'ordre où le menu les propose.
  static const List<ThemeMode> choices = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  /// Passe à la valeur suivante : un tap fait tourner Clair → Sombre →
  /// Système → Clair, sans avoir à viser une entrée précise du menu.
  Future<void> cycle() async {
    final next = choices[(choices.indexOf(_mode) + 1) % choices.length];
    await set(next);
  }

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode? _decode(String? raw) => switch (raw) {
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  // --- Libellés et icônes -------------------------------------------------

  static String label(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Système',
        ThemeMode.light => 'Clair',
        ThemeMode.dark => 'Sombre',
      };

  static IconData icon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}

/// Rend le [ThemeModeController] accessible à tous les écrans.
///
/// Placé au-dessus de `MaterialApp` : `ThemeModeScope.of` enregistre le build
/// appelant comme dépendant, donc changer de mode reconstruit proprement
/// l'application (nouveau `themeMode`) et les écrans qui lisent la portée
/// (dont le menu de l'accueil, qui affiche le mode courant).
class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  const ThemeModeScope({
    super.key,
    required ThemeModeController notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Mode de thème courant, avec suivi des dépendances.
  ///
  /// Retourne [ThemeMode.system] si aucune portée n'est présente (défaut sûr,
  /// utile dans les aperçus et les tests isolés).
  static ThemeMode of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeModeScope>()?.notifier?.mode ??
      ThemeMode.system;

  /// Contrôleur de la portée, sans abonnement (pour écrire le mode).
  static ThemeModeController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ThemeModeScope>()?.notifier;

  /// Sélectionne [mode] quand la portée existe, sinon ne fait rien.
  static Future<void> set(BuildContext context, ThemeMode mode) async {
    await maybeOf(context)?.set(mode);
  }
}