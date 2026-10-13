import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_feedback.dart';

/// Étape 2 de la réinitialisation : l'utilisateur saisit le code à 6 chiffres
/// reçu par email. verifyOTP(recovery) crée une session temporaire, puis
/// l'écran suivant permet de choisir le nouveau mot de passe.
class ResetCodeScreen extends StatefulWidget {
  final String email;
  const ResetCodeScreen({super.key, required this.email});

  @override
  State<ResetCodeScreen> createState() => _ResetCodeScreenState();
}

class _ResetCodeScreenState extends State<ResetCodeScreen> {
  static const _resendCooldownSeconds = 30;

  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    // On ne garde que les chiffres : un espace collé ferait échouer la
    // vérification, et la longueur du code est réglable côté Supabase.
    final code = _codeController.text.replaceAll(RegExp(r'\D'), '');
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.auth.verifyOTP(
        type: OtpType.recovery,
        email: widget.email,
        token: code,
      );
      // Session temporaire créée : on passe au choix du nouveau mot de passe.
      if (mounted) context.go('/reset-password');
    } on AuthException catch (e) {
      final message = e.message.toLowerCase();
      setState(() => _error = (message.contains('expired') ||
              message.contains('invalid') ||
              message.contains('token'))
          ? 'Code invalide ou expiré. Utilise le dernier code reçu.'
          : friendlyErrorMessage(e));
    } catch (e) {
      setState(() => _error = friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      // Pas de type `recovery` dans resend() : on renvoie un nouvel email de
      // réinitialisation, ce qui régénère le code.
      await supabase.auth.resetPasswordForEmail(widget.email);
      if (!mounted) return;
      AppSnack.success(context, 'Un nouveau code a été envoyé.');
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      final message = e is AuthException ? e.message.toLowerCase() : '';
      AppSnack.error(
        context,
        e,
        fallback: message.contains('rate') || message.contains('too many')
            ? 'Trop de demandes. Patiente un instant avant de réessayer.'
            : null,
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = _resendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canResend = !_resending && _cooldown == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_reset, size: 56, color: scheme.primary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Saisis le code reçu à',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    maxLength: 10,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Code de réinitialisation',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (_error != null) setState(() => _error = null);
                    },
                    onSubmitted: (_) => _verify(),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Valider'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(
                      _resending
                          ? 'Envoi...'
                          : _cooldown > 0
                              ? 'Renvoyer le code (${_cooldown}s)'
                              : 'Renvoyer le code',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
