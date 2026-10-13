import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

/// Demande le code à 6 chiffres reçu par email juste après l'inscription.
class ConfirmEmailScreen extends StatefulWidget {
  final String email;
  const ConfirmEmailScreen({super.key, required this.email});

  @override
  State<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;

  Future<void> _verify() async {
    // On ne garde que les chiffres : un espace ou un retour à la ligne
    // collé avec le code ferait échouer la vérification.
    final code = _codeController.text.replaceAll(RegExp(r'\D'), '');
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await supabase.auth.verifyOTP(
        type: OtpType.signup,
        email: widget.email,
        token: code,
      );
      // Succès : une session est créée, go_router redirige seul vers l'accueil.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await supabase.auth.resend(type: OtpType.signup, email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau code envoyé.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirme ton email')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Un code de confirmation a été envoyé à\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code de confirmation',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 4),
                  // La longueur du code est un réglage Supabase (6 à 10
                  // chiffres) : on n'impose pas 6 côté app, c'est verifyOTP
                  // qui décide si le code est valide.
                  maxLength: 10,
                  onSubmitted: (_) => _verify(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                FilledButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Valider'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Envoi...' : 'Renvoyer le code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}