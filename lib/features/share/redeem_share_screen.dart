import 'package:flutter/material.dart';
import '../../core/app_scaffold.dart';
import '../../core/shared_with_me.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/shared_address_content.dart';

/// Écran où un destinataire colle un code/lien de partage reçu.
/// Toute la vérification (existence, expiration, révocation, limite) se fait
/// côté serveur via la fonction SQL redeem_share_link — jamais fait confiance
/// au client (RG20, RG21, RG22).
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('/')) return trimmed.split('/').last;
    return trimmed;
  }

  Future<void> _open() async {
    if (_loading) return;

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
      final result = await redeemShareLink(token);
      if (!mounted) return;

      if (!result.ok || result.address == null) {
        setState(() {
          _error = shareRedeemErrorMessage(result.error);
        });
        return;
      }

      setState(() {
        _address = result.address;
        _landmarks = result.landmarks;
        _steps = result.steps;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur : $e');
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
            onSubmitted: (_) => _open(),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _loading ? null : _open,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Ouvrir l'adresse"),
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
