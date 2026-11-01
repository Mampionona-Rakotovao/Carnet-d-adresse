import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/shared_with_me.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../../ui/app_states.dart';
import 'widgets/shared_address_content.dart';

/// Écran ouvert par un lien partagé :
/// https://mampionona-rakotovao.github.io/a/<token>
/// La vérification (existence, expiration, révocation) reste côté serveur
/// via la fonction SQL get_shared_address_full.
class SharedLinkScreen extends StatefulWidget {
  const SharedLinkScreen({super.key, required this.token});

  final String token;

  @override
  State<SharedLinkScreen> createState() => _SharedLinkScreenState();
}

class _SharedLinkScreenState extends State<SharedLinkScreen> {
  bool _loading = true;
  bool _invalid = false;
  Object? _error;
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _invalid = false;
      _error = null;
    });

    try {
      final result = await supabase.rpc(
        'get_shared_address_full',
        params: {'p_token': widget.token},
      );

      if (result == null) {
        if (mounted) setState(() => _invalid = true);
        return;
      }

      // Enregistre l'ouverture : l'adresse apparaîtra dans « Partagées avec
      // moi » tant que le lien est valide. Une erreur ici ne doit pas
      // empêcher l'affichage de l'adresse.
      await recordShareOpen(widget.token);

      final data = result as Map<String, dynamic>;
      final address = Address.fromJson(data['address'] as Map<String, dynamic>);
      final landmarks = (data['landmarks'] as List)
          .map((r) => Landmark.fromJson(r as Map<String, dynamic>))
          .toList();
      final steps = (data['steps'] as List)
          .map((r) => RouteStep.fromJson(r as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _address = address;
          _landmarks = landmarks;
          _steps = steps;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goHome() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse partagée'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: _goHome,
        ),
      ),
      body: _loading
          ? const AppLoading()
          : _invalid
              ? AppErrorState(
                  title: 'Lien invalide ou expiré',
                  message:
                      'Demandez un nouveau lien au propriétaire de l\'adresse.',
                  onRetry: _load,
                )
              : _error != null
                  ? AppErrorState(error: _error, onRetry: _load)
                  : ListView(
                      padding: AppSpacing.form,
                      children: [
                        SharedAddressContent(
                          address: _address!,
                          landmarks: _landmarks,
                          steps: _steps,
                        ),
                      ],
                    ),
    );
  }
}
