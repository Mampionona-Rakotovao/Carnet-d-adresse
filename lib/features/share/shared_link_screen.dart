import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/shared_with_me.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/share_link.dart';
import '../../ui/app_states.dart';
import 'widgets/shared_address_content.dart';

/// Écran ouvert par un lien partagé :
/// https://mampionona-rakotovao.github.io/a/<token>
///
/// La place n'est consommée qu'après appui explicite sur « Voir cette
/// adresse ». Aucune requête d'ouverture n'est faite à l'affichage.
class SharedLinkScreen extends StatefulWidget {
  const SharedLinkScreen({super.key, required this.token});

  final String token;

  @override
  State<SharedLinkScreen> createState() => _SharedLinkScreenState();
}

class _SharedLinkScreenState extends State<SharedLinkScreen> {
  bool _redeeming = false;
  ShareRedeemResult? _result;
  String? _errorCode;
  Object? _error;
  Timer? _countdownTimer;
  Timer? _expiryTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startExpiryTimers(DateTime? expiresAt) {
    _countdownTimer?.cancel();
    _expiryTimer?.cancel();

    if (expiresAt == null) return;

    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });

    _scheduleExpiryCheck(expiresAt);
  }

  void _scheduleExpiryCheck(DateTime expiresAt) {
    _expiryTimer?.cancel();

    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _markExpired();
      return;
    }

    final delay = remaining > const Duration(hours: 1)
        ? const Duration(hours: 1)
        : remaining;
    _expiryTimer = Timer(delay, () {
      if (!mounted) return;
      if (expiresAt.isAfter(DateTime.now())) {
        _scheduleExpiryCheck(expiresAt);
      } else {
        _markExpired();
      }
    });
  }

  void _markExpired() {
    if (!mounted) return;
    _countdownTimer?.cancel();
    _expiryTimer?.cancel();
    setState(() {
      _result = null;
      _error = null;
      _errorCode = 'expired';
    });
  }

  Future<void> _redeem() async {
    if (_redeeming) return;

    _countdownTimer?.cancel();
    _expiryTimer?.cancel();

    setState(() {
      _redeeming = true;
      _error = null;
      _errorCode = null;
    });

    try {
      final result = await redeemShareLink(widget.token);
      if (!mounted) return;

      if (!result.ok) {
        setState(() => _errorCode = result.error);
        return;
      }

      if (result.address == null) {
        setState(() => _errorCode = 'not_found');
        return;
      }

      setState(() => _result = result);
      _startExpiryTimers(result.expiresAt);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  void _goHome() => context.go('/');

  void _handleErrorAction() {
    if (_errorCode == 'auth_required') {
      context.go('/login');
    } else {
      _redeem();
    }
  }

  String _errorTitle(String? code) {
    switch (code) {
      case 'expired':
        return 'Ce lien a expiré';
      case 'revoked':
        return 'Ce lien a été désactivé';
      case 'full':
        return 'Lien complet';
      case 'auth_required':
        return 'Connexion requise';
      default:
        return 'Lien invalide';
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final address = result?.address;
    final expiredNow = result?.expiresAt != null &&
        !result!.expiresAt!.isAfter(DateTime.now());
    final notice =
        result == null ? null : recipientExpirationNotice(result.expiresAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse partagée'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: _goHome,
        ),
      ),
      body: expiredNow
          ? AppErrorState(
              title: 'Ce lien a expiré',
              message: shareRedeemErrorMessage('expired'),
            )
          : result != null && address != null
              ? ListView(
                  padding: AppSpacing.form,
                  children: [
                    if (notice != null) ...[
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.5),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  notice,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    SharedAddressContent(
                      address: address,
                      landmarks: result.landmarks,
                      steps: result.steps,
                    ),
                  ],
                )
              : _error != null
                  ? AppErrorState(error: _error, onRetry: _redeem)
                  : _errorCode != null
                      ? AppErrorState(
                          title: _errorTitle(_errorCode),
                          message: shareRedeemErrorMessage(_errorCode),
                          onRetry: _errorCode == 'auth_required'
                              ? _handleErrorAction
                              : null,
                        )
                      : _buildIntro(context),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_location_outlined,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Une adresse a été partagée avec toi',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Pour la consulter, appuie sur le bouton. Cette action '
                'associe le lien à ton compte et peut utiliser une place du '
                'partage.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 320,
                ),
                child: FilledButton.icon(
                  onPressed: _redeeming ? null : _redeem,
                  icon: _redeeming
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined),
                  label: const Text('Voir cette adresse'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
