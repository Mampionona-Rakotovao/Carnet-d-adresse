import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/google_auth_service.dart';
import '../../../core/supabase_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../ui/app_feedback.dart';

/// Utilisé uniquement pour le web (flux navigateur). Sur Android, on utilise
/// la connexion native : aucun deep link n'est nécessaire.
const _webRedirectFallback = '';

/// Séparateur « ou » + bouton « Continuer avec Google ».
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        // Web : flux navigateur classique.
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        // Android : connexion native, sans navigateur.
        await signInWithGoogle();
        // Crée le profil s'il n'existe pas encore (comme pour l'inscription
        // par email). go_router redirige ensuite via onAuthStateChange.
        await ensureProfile();
      }
    } on GoogleSignInException catch (e) {
      // L'utilisateur a annulé ou Google a refusé : on log seulement.
      debugPrint('Google: $e');
      if (mounted && e.code != GoogleSignInExceptionCode.canceled) {
        AppSnack.error(context, e);
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'ou',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: _loading ? null : _signIn,
          icon: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.account_circle_outlined),
          label: const Text('Continuer avec Google'),
        ),
      ],
    );
  }
}