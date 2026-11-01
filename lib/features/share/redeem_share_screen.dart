import 'package:flutter/material.dart';
import '../../core/app_scaffold.dart';
import '../../core/shared_with_me.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/shared_address_content.dart';

/// Écran où un destinataire colle un code/lien de partage reçu.
/// Toute la vérification (existence, expiration, révocation) se fait
/// côté serveur via la fonction SQL get_shared_address_full — jamais
/// fait confiance au client (RG20, RG21, RG22).
class RedeemShareScreen extends StatefulWidget {
  const RedeemShareScreen({super.key});

  @override
  State<RedeemShareScreen> createState() => _RedeemShareScreenState();
}

class _RedeemShareScreenState extends State<RedeemShareScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];

  String _extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('/')) return trimmed.split('/').last;
    return trimmed;
  }

  Future<void> _verify() async {
    final token = _extractToken(_controller.text);
    if (token.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _address = null;
      _landmarks = [];
      _steps = [];
    });

    try {
      final result = await supabase
          .rpc('get_shared_address_full', params: {'p_token': token});

      if (result == null) {
        setState(() => _error =
            'Lien invalide, expiré ou révoqué. Vérifie le code ou demande un nouveau lien au propriétaire.');
        return;
      }

      // Enregistrer l'ouverture pour qu'elle apparaisse dans "Partagées avec
      // moi" et pour prévenir le propriétaire à sa prochaine connexion.
      // Aucun message n'est affiché au destinataire : seul le propriétaire
      // reçoit la notification.
      await recordShareOpen(token);

      final data = result as Map<String, dynamic>;
      final address = Address.fromJson(data['address'] as Map<String, dynamic>);
      final landmarks = (data['landmarks'] as List)
          .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
          .toList();
      final steps = (data['steps'] as List)
          .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
          .toList();

      setState(() {
        _address = address;
        _landmarks = landmarks;
        _steps = steps;
      });
    } catch (e) {
      setState(() => _error = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ouvrir un lien')),
      body: ListView(
        padding: AppSpacing.form,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Code ou lien reçu',
              border: OutlineInputBorder(),
              hintText: 'Ex: 8f3c2a1b9d4e...',
            ),
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _loading ? null : _verify,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Vérifier'),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: AppSpacing.form,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          if (_address != null)
            SharedAddressContent(
              address: _address!,
              landmarks: _landmarks,
              steps: _steps,
            ),
        ],
      ),
      bottomNavigationBar: ShellNavigationBar.of(context),
    );
  }
}
