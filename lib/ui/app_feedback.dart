import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/theme/app_spacing.dart';

/// Traduit une exception technique en un message que l'utilisateur comprend.
///
/// Les erreurs brutes de Supabase (« Exception: column … violates not-null
/// constraint », « PostgrestException … ») sont incompréhensibles et font
/// perdre confiance dans l'application. On affiche donc une phrase simple,
/// et le détail technique reste réservé au mode debug.
String friendlyErrorMessage(Object error, {String fallback = 'Une erreur est survenue. Réessayez.'}) {
  final raw = error.toString();
  final text = raw.toLowerCase();

  // --- Réseau / serveur -----------------------------------------------
  if (text.contains('failed to fetch') ||
      text.contains('socketexception') ||
      text.contains('connection refused') ||
      text.contains('host lookup') ||
      text.contains('no address associated')) {
    return "Impossible de joindre le serveur. Vérifiez votre connexion internet.";
  }
  if (text.contains('timed out') || text.contains('timeout')) {
    return 'Le serveur met trop de temps à répondre. Réessayez dans un instant.';
  }

  // --- Authentification -----------------------------------------------
  if (text.contains('invalid login credentials')) {
    return 'Email ou mot de passe incorrect.';
  }
  if (text.contains('user already registered') || text.contains('already been registered')) {
    return 'Un compte existe déjà avec cet email. Essayez de vous connecter.';
  }
  if (text.contains('email not confirmed')) {
    return "Votre email n'est pas encore confirmé. Vérifiez votre boîte de réception.";
  }
  if (text.contains('password should be at least')) {
    return 'Le mot de passe doit contenir au moins 6 caractères.';
  }
  if (text.contains('unable to validate email') || text.contains('invalid email')) {
    return "Cette adresse email n'est pas valide.";
  }
  if (text.contains('too many requests') || text.contains('rate limit')) {
    return 'Trop de tentatives. Patientez quelques instants avant de réessayer.';
  }

  // --- Base de données -------------------------------------------------
  if (text.contains('row-level security') || text.contains('row level security')) {
    return "Vous n'avez pas les droits nécessaires pour cette action.";
  }
  if (text.contains('duplicate key')) {
    return 'Cet élément existe déjà.';
  }
  if (text.contains('not-null') || text.contains('violates not null')) {
    return "Un champ obligatoire est manquant.";
  }
  if (text.contains('foreign key') || text.contains('violates foreign key')) {
    return "Cette action est impossible : des données liées à cet élément existent encore.";
  }
  if (text.contains('invalid input syntax') || text.contains('could not parse')) {
    return "Une des informations saisies n'est pas valide.";
  }

  // --- Fichiers --------------------------------------------------------
  if (text.contains('exceeded the maximum allowed size') ||
      text.contains('payload too large')) {
    return "La photo est trop lourde. Choisis une image plus légère.";
  }
  if (text.contains('bucket not found') || text.contains('storage')) {
    return "Le stockage des photos est momentanément indisponible.";
  }

  return fallback;
}

/// Détail technique, affiché uniquement en développement pour aider au
/// diagnostic sans jamais polluer l'interface en production.
String? debugErrorDetail(Object error) =>
    kDebugMode ? error.toString() : null;

enum AppMessageKind { info, success, error, warning }

extension AppMessageKindX on AppMessageKind {
  IconData get icon => switch (this) {
        AppMessageKind.info => Icons.info_outline,
        AppMessageKind.success => Icons.check_circle_outline,
        AppMessageKind.error => Icons.error_outline,
        AppMessageKind.warning => Icons.warning_amber_rounded,
      };

  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      AppMessageKind.info => scheme.onInverseSurface,
      AppMessageKind.success => const Color(0xFF7BD88F),
      AppMessageKind.error => const Color(0xFFFFB4AB),
      AppMessageKind.warning => const Color(0xFFFFCF8B),
    };
  }
}

/// Point d'entrée unique des messages de retour utilisateur.
///
/// Remplace les `ScaffoldMessenger.of(context).showSnackBar(...)` dispersés
/// dans les écrans : la forme, la durée et l'icône sont toujours les mêmes, et
/// les erreurs techniques passent par [friendlyErrorMessage].
abstract final class AppSnack {
  static void _show(
    BuildContext context,
    String message, {
    required AppMessageKind kind,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          content: Row(
            children: [
              Icon(kind.icon, color: kind.color(context), size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
  }

  static void info(BuildContext context, String message) =>
      _show(context, message, kind: AppMessageKind.info);

  static void success(BuildContext context, String message) =>
      _show(context, message, kind: AppMessageKind.success);

  static void warning(BuildContext context, String message) =>
      _show(context, message, kind: AppMessageKind.warning);

  /// Affiche un message d'erreur lisible, sans jamais laisser remonter
  /// l'exception brute à l'écran.
  static void error(BuildContext context, Object error, {String? fallback}) {
    final detail = debugErrorDetail(error);
    if (detail != null) debugPrint('AppSnack.error → $detail');
    _show(
      context,
      friendlyErrorMessage(error, fallback: fallback ?? 'Une erreur est survenue. Réessayez.'),
      kind: AppMessageKind.error,
    );
  }

  /// Message accompagné d'une action d'annulation, utilisé après une
  /// suppression ou un changement de favori.
  static void withUndo(
    BuildContext context,
    String message, {
    required String undoLabel,
    required VoidCallback onUndo,
  }) =>
      _show(
        context,
        message,
        kind: AppMessageKind.info,
        actionLabel: undoLabel,
        onAction: onUndo,
        duration: const Duration(seconds: 6),
      );
}
