import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Demande confirmation avant de fermer l'application.
///
/// Un geste involontaire doit toujours pouvoir être annulé sans quitter
/// l'application. Le dialogue est utilisé par toutes les pages principales,
/// qu'elles soient dans le shell (onglets) ou hors shell (connexion, fiches).
Future<bool?> showConfirmationSortie(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.exit_to_app, color: scheme.error),
      title: const Text(
        'Quitter l’application ?',
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'Vous êtes sur le point de fermer le carnet. '
        'Choisissez « Annuler » si ce n’était pas volontaire.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quitter'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Demande au système de fermer l'application.
///
/// [SystemNavigator.pop] est préféré à `dart:io` `exit` : ce dernier ferait
/// croire à une fermeture brutale (crash) aux systèmes mobiles.
Future<void> quitterApplication() => SystemNavigator.pop();

/// Intercepte le retour système sur la dernière page d'une navigation.
///
/// Placée dans chaque page construite par `appPage` et dans le shell
/// `AppScaffold`, cette enveloppe laisse le retour fonctionner normalement
/// quand une page est empilée au-dessus ([canPop] vrai). Sur la racine, elle
/// bloque le pop, ce qui déclenche
/// [onPopInvokedWithResult] avec `didPop == false` : le dialogue de
/// confirmation s'ouvre alors à la place d'une sortie immédiate.
class ConfirmationSortie extends StatefulWidget {
  const ConfirmationSortie({super.key, required this.child});

  final Widget child;

  @override
  State<ConfirmationSortie> createState() => _ConfirmationSortieState();
}

class _ConfirmationSortieState extends State<ConfirmationSortie> {
  /// Évite d'empiler plusieurs dialogues si le retour est pressé deux fois.
  bool _dialogueOuvert = false;

  Future<void> _demanderConfirmation() async {
    if (!mounted || _dialogueOuvert) return;
    _dialogueOuvert = true;
    try {
      final confirme = await showConfirmationSortie(context);
      if (!mounted) return;
      if (confirme == true) {
        await quitterApplication();
      }
    } finally {
      if (mounted) _dialogueOuvert = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final peutRevenirEnArriere = Navigator.of(context).canPop();
    return PopScope<void>(
      canPop: peutRevenirEnArriere,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _demanderConfirmation();
      },
      child: widget.child,
    );
  }
}
