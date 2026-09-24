import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';

/// Écran temporaire pour vérifier que la connexion Flutter <-> Supabase
/// fonctionne. À remplacer plus tard par de vrais écrans inscription/connexion.
class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _status = 'En attente...';
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _status = 'Inscription en cours...';
    });
    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _status = 'Inscrit ! user_id = ${res.user?.id}');
    } catch (e) {
      setState(() => _status = 'Erreur inscription : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _status = 'Connexion en cours...';
    });
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _status = 'Connecté ! user_id = ${res.user?.id}');
    } catch (e) {
      setState(() => _status = 'Erreur connexion : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test connexion Supabase')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _signUp,
              child: const Text("S'inscrire"),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _signIn,
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            Text(_status, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}