import 'dart:async';

import 'package:flutter/material.dart';

import '../core/screen_security.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Enveloppe une adresse privée consultée par un non-propriétaire.
///
/// `acquire()` est appelé une seule fois tant que [enabled] reste vrai, et
/// `release()` une seule fois quand l'écran disparaît ou quand [enabled]
/// repasse à false. Le compteur de références du service empile donc sans
/// risque plusieurs écrans (partage → repère → guidage).
class ScreenProtection extends StatefulWidget {
  const ScreenProtection({
    super.key,
    required this.enabled,
    required this.child,
    this.security,
    this.afficherBandeau = true,
  });

  final bool enabled;
  final Widget child;

  /// Injection pour les tests ; l'application utilise le singleton.
  final ScreenSecurity? security;

  /// Affiche la pastille d'information sur les écrans protégés.
  final bool afficherBandeau;

  @override
  State<ScreenProtection> createState() => _ScreenProtectionState();
}

class _ScreenProtectionState extends State<ScreenProtection> {
  late final ScreenSecurity _security;
  bool _acquired = false;

  @override
  void initState() {
    super.initState();
    _security = widget.security ?? screenSecurity;
    if (widget.enabled) {
      _acquired = true;
      unawaited(_security.acquire());
    }
  }

  @override
  void didUpdateWidget(covariant ScreenProtection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled == widget.enabled) return;
    if (widget.enabled && !_acquired) {
      _acquired = true;
      unawaited(_security.acquire());
    } else if (!widget.enabled && _acquired) {
      _acquired = false;
      unawaited(_security.release());
    }
  }

  @override
  void dispose() {
    if (_acquired) {
      _acquired = false;
      unawaited(_security.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!widget.enabled || !widget.afficherBandeau) return child;

    return Stack(
      // Le child reçoit exactement les contraintes du parent : la pastille
      // est un simple empilement, elle ne change pas la mise en page.
      fit: StackFit.passthrough,
      children: [
        child,
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: IgnorePointer(
              child: Center(
                child: _BandeauPrive(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Petite pastille discrète : le cadenas prévient que la capture est bloquée.
class _BandeauPrive extends StatelessWidget {
  const _BandeauPrive();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      label: 'Adresse privée : les captures d’écran sont désactivées',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: palette.private.withValues(alpha: 0.12),
            border: Border.all(color: palette.private),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 16, color: palette.privateText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Adresse privée : les captures d’écran sont désactivées',
                  maxLines: 2,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.privateText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
