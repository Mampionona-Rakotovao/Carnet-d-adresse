import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../ui/app_feedback.dart';
import 'widgets/google_sign_in_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (_isSignUp) {
        final email = _emailController.text.trim();
        final res = await supabase.auth.signUp(
          email: email,
          password: _passwordController.text.trim(),
          // Le nom est conservé dans les métadonnées du compte ; le profil
          // est ensuite créé/complété par ensureProfile().
          data: {'name': _nameController.text.trim()},
        );

        // Si « Confirm email » est activé côté Supabase, signUp() ne crée
        // pas encore de session : il faut d'abord valider le code reçu
        // par email avant de pouvoir se connecter.
        if (res.session == null) {
          if (mounted) context.push('/confirm-email', extra: email);
        } else {
          // Confirmation désactivée : la session existe déjà, on peut créer
          // le profil tout de suite.
          await ensureProfile();
        }
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      // Sinon, pas de navigation manuelle : go_router détecte le
      // changement de session (onAuthStateChange) et redirige seul.
    } catch (e) {
      if (mounted) AppSnack.error(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text);
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Adresse e-mail',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    try {
      // Supabase envoie un email de réinitialisation. S'il contient le code
      // à 6 chiffres (`{{ .Token }}` dans le template), l'utilisateur le
      // saisit sur l'écran suivant ; le lien éventuel reste géré en secours.
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _resetRedirectUrl(),
      );
      if (!mounted) return;
      AppSnack.info(
        context,
        'Si ce compte existe, un code de réinitialisation vient '
        "d'être envoyé par email.",
      );
      context.push('/reset-code', extra: email);
    } catch (e) {
      if (mounted) AppSnack.error(context, e);
    }
  }

  /// Schéma d'URL (deep link) qui rouvre l'application sur mobile.
  /// Déclaré dans android/app/src/main/AndroidManifest.xml.
  static const _mobileScheme = 'carnetadresses';

  /// URL vers laquelle Supabase redirige après le clic sur le lien de
  /// réinitialisation reçu par email.
  ///
  /// - Web : on cible `/reset-password` afin que go_router ouvre directement
  ///   l'écran de saisie du nouveau mot de passe.
  /// - Mobile : on utilise un deep link (`carnetadresses://reset-password`)
  ///   que le système remet à l'application.
  String _resetRedirectUrl() {
    if (!kIsWeb) return '$_mobileScheme://reset-password';
    return Uri.base
        .replace(path: '/reset-password', query: null, fragment: null)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 36,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "Carnet d'adresses",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _isSignUp
                              ? 'Créez votre compte pour enregistrer vos lieux'
                              : 'Connectez-vous pour accéder à votre carnet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          hintText: 'Votre nom',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'exemple@mail.com',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'L\'e-mail est obligatoire';
                        }
                        final email = v.trim();
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(email)) {
                          return 'Format d\'e-mail invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscure ? 'Afficher' : 'Masquer',
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }
                        if (_isSignUp && v.trim().length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                    ] else
                      const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUp ? "S'inscrire" : 'Se connecter'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const GoogleSignInButton(),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? "Déjà un compte ? Se connecter"
                            : "Pas de compte ? S'inscrire",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
