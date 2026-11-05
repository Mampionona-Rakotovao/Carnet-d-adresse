import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/favorites.dart';
import '../../core/photo_storage.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../help/widgets/contextual_help_button.dart';
import 'widgets/detail_widgets.dart';
import 'widgets/landmark_detail_sheet.dart';
import 'widgets/landmark_form_sheet.dart';
import 'widgets/route_step_detail_sheet.dart';
import 'widgets/route_step_form_sheet.dart';
import 'widgets/share_link_sheet.dart';
import 'widgets/trajet_widgets.dart';
import '../../ui/app_feedback.dart';
import '../../ui/app_states.dart';
import '../../ui/status_chip.dart';

class AddressDetailScreen extends StatefulWidget {
  final String addressId;

  const AddressDetailScreen({super.key, required this.addressId});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  Address? _address;
  List<Landmark> _landmarks = [];
  List<RouteStep> _steps = [];
  bool _isFavorite = false;
  bool _loading = true;
  bool _notFound = false;
  bool _deleting = false;
  bool _busy = false;
  Object? _error;

  /// Seul le propriétaire voit les actions de modification. La RLS protège
  /// déjà le serveur, mais l'interface ne doit pas non plus proposer des
  /// actions interdites à un simple visiteur (public ou autorisé en lecture).
  bool get _isOwner =>
      _address != null && _address!.ownerId == supabase.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (!mounted) return;
    setState(() {
      if (showLoading) _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final addressRow = await supabase
          .from('addresses')
          .select()
          .eq('id', widget.addressId)
          .maybeSingle();

      if (addressRow == null) {
        if (!mounted) return;
        setState(() {
          _address = null;
          _landmarks = [];
          _steps = [];
          _notFound = true;
        });
        return;
      }

      final landmarkRows = await supabase
          .from('landmarks')
          .select()
          .eq('address_id', widget.addressId)
          .order('position_order');

      final stepRows = await supabase
          .from('route_steps')
          .select()
          .eq('address_id', widget.addressId)
          .order('step_order');

      final favorite = await isFavorite(widget.addressId);
      if (!mounted) return;

      setState(() {
        _address = Address.fromJson(addressRow);
        _landmarks =
            (landmarkRows as List).map((r) => Landmark.fromJson(r)).toList();
        _steps = (stepRows as List).map((r) => RouteStep.fromJson(r)).toList();
        _isFavorite = favorite;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.red,
              backgroundColor: Colors.red.shade50,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _leaveDeleted() {
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/');
    }
  }

  Future<void> _deleteAddress() async {
    final address = _address;
    final addressId = address?.id;
    if (address == null || addressId == null || _deleting) return;

    if (!await _confirm(
      'Supprimer cette adresse ?',
      'Cette action est irréversible : "${address.name}" et toutes ses '
          'données associées (repères, étapes, favoris, liens de partage) '
          'seront supprimés.',
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _deleting = true);
    try {
      final deleted = await supabase
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .select();

      if ((deleted as List).isEmpty) {
        if (!mounted) return;
        AppSnack.error(
          context,
          Exception('delete address returned no row'),
          fallback: "Suppression impossible : l'adresse n'a pas été supprimée. "
              'Vérifiez vos droits puis réessayez.',
        );
        return;
      }

      await removePhotoFolder(addressId);
      if (!mounted) return;
      _leaveDeleted();
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(
        context,
        e,
        fallback:
            "Suppression impossible. Vérifiez votre connexion et réessayez.",
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _editLandmark(Landmark l) async {
    final ok = await showLandmarkFormSheet(
      context,
      addressId: _address!.id!,
      existing: l,
    );
    if (ok == true) _loadAll();
  }

  Future<void> _deleteLandmark(Landmark l) async {
    final landmarkId = l.id;
    if (landmarkId == null || _busy) return;

    if (!await _confirm(
      'Supprimer ce repère ?',
      '"${l.name}" sera supprimé.',
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final deleted = await supabase
          .from('landmarks')
          .delete()
          .eq('id', landmarkId)
          .select();

      if ((deleted as List).isEmpty) {
        if (!mounted) return;
        AppSnack.error(
          context,
          Exception('delete landmark returned no row'),
          fallback: 'Suppression impossible : le repère n\'a pas été supprimé.',
        );
        return;
      }

      await removePhotoAtUrl(l.photoUrl);
      await _loadAll(showLoading: false);
      if (mounted) AppSnack.success(context, 'Repère supprimé.');
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(
        context,
        e,
        fallback: "Suppression du repère impossible. Réessayez.",
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editStep(RouteStep s) async {
    final ok = await showRouteStepFormSheet(
      context,
      addressId: _address!.id!,
      landmarks: _landmarks,
      nextStepOrder: _steps.length + 1,
      existing: s,
    );
    if (ok == true) _loadAll();
  }

  Future<void> _deleteStep(RouteStep s) async {
    final stepId = s.id;
    if (stepId == null || _busy) return;

    if (!await _confirm(
      'Supprimer cette étape ?',
      'L\'étape sera supprimée.',
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final deleted =
          await supabase.from('route_steps').delete().eq('id', stepId).select();

      if ((deleted as List).isEmpty) {
        if (!mounted) return;
        AppSnack.error(
          context,
          Exception('delete route step returned no row'),
          fallback: 'Suppression impossible : l\'étape n\'a pas été supprimée.',
        );
        return;
      }

      await _loadAll(showLoading: false);
      if (mounted) AppSnack.success(context, 'Étape supprimée.');
    } catch (e) {
      if (!mounted) return;
      AppSnack.error(
        context,
        e,
        fallback: "Suppression de l'étape impossible. Réessayez.",
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Détail d'un repère : tout son contenu plus les étapes du trajet qui lui
  /// correspondent, chacune affichée en entier et modifiable sur place.
  /// Le feuillet renvoie l'action demandée, l'écran l'exécute.
  Future<void> _openLandmarkDetail(Landmark l) async {
    final action = await showLandmarkDetailSheet(
      context,
      landmark: l,
      steps: _steps,
      isOwner: _isOwner,
    );
    if (!mounted || action == null) return;

    if (action == landmarkDetailEdit) {
      await _editLandmark(l);
    } else if (action == landmarkDetailDelete) {
      await _deleteLandmark(l);
    } else if (action.startsWith(landmarkDetailStepEditPrefix)) {
      final step = _stepFromAction(action, landmarkDetailStepEditPrefix);
      if (step != null) await _editStep(step);
    } else if (action.startsWith(landmarkDetailStepDeletePrefix)) {
      final step = _stepFromAction(action, landmarkDetailStepDeletePrefix);
      if (step != null) await _deleteStep(step);
    }
  }

  /// Détail d'une étape, avec un lien vers son repère associé.
  Future<void> _openStepDetail(RouteStep s) async {
    final matches = _landmarks.where((l) => l.id == s.landmarkId);
    final action = await showRouteStepDetailSheet(
      context,
      step: s,
      landmark: matches.isEmpty ? null : matches.first,
      isOwner: _isOwner,
    );
    if (!mounted || action == null) return;

    if (action == routeStepDetailEdit) {
      await _editStep(s);
    } else if (action == routeStepDetailDelete) {
      await _deleteStep(s);
    } else if (action == routeStepDetailLandmark && matches.isNotEmpty) {
      await _openLandmarkDetail(matches.first);
    }
  }

  /// Le feuillet encode l'action et l'id de l'étape sous la forme
  /// `<préfixe><id>` : on en ressort l'étape concernée.
  RouteStep? _stepFromAction(String action, String prefix) {
    final stepId = action.substring(prefix.length);
    final matches = _steps.where((s) => s.id == stepId);
    return matches.isEmpty ? null : matches.first;
  }

  /// Bascule l'étoile : l'icône change immédiatement, l'écriture en base
  /// suit. En cas d'échec on restaure l'état précédent et on prévient.
  Future<void> _toggleFavorite() async {
    final addressId = _address?.id;
    if (addressId == null) return;

    final previous = _isFavorite;
    setState(() => _isFavorite = !previous);

    try {
      await toggleFavorite(addressId, previous);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = previous);
      AppSnack.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AppLoading());
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppErrorState(
          error: _error,
          onRetry: _loadAll,
        ),
      );
    }
    if (_notFound || _address == null) {
      return Scaffold(
        appBar: AppBar(),
        body: AppEmptyState(
          icon: Icons.location_off_outlined,
          title: 'Cette adresse n\'existe plus',
          message: 'Elle a peut-être été supprimée depuis un autre appareil. '
              'La liste va être mise à jour.',
          actionLabel: 'Retour à la liste',
          actionIcon: Icons.arrow_back,
          onAction: _leaveDeleted,
        ),
      );
    }

    final address = _address!;
    final isOwner = _isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(address.name),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_outline),
            tooltip:
                _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            color: _isFavorite ? Colors.amber : null,
            onPressed: _toggleFavorite,
          ),
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Partager',
              onPressed: () =>
                  showShareLinkSheet(context, addressId: address.id!),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Modifier',
              onPressed: () async {
                await context.push<bool>('/address/${address.id}/edit',
                    extra: address);
                _loadAll();
              },
            ),
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _deleting ? null : _deleteAddress,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: AppSpacing.list,
        children: [
          if (address.photoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                address.photoUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  AppStatusChip.visibility(address.visibility, dense: true),
                  AppStatusChip.gpsType(address.gpsType, dense: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (address.locality != null) ...[
            Text('Localité', style: Theme.of(context).textTheme.titleSmall),
            Text(address.locality!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (address.description != null) ...[
            Text('Description', style: Theme.of(context).textTheme.titleSmall),
            Text(address.description!),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Coordonnées GPS',
              style: Theme.of(context).textTheme.titleSmall),
          Text(
              '${address.latitude.toStringAsFixed(6)}, ${address.longitude.toStringAsFixed(6)}'),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Trajet', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const ContextualHelpButton(
                articleIds: [
                  'difference-trajet',
                  'itineraire',
                  'guidage',
                  'naviguer-google-maps',
                  'limites-trajet',
                ],
                title: 'Aide sur le trajet',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TrajetSection(
            destination: LatLng(address.latitude, address.longitude),
            nom: address.name,
            landmarks: _landmarks,
            markerIcon: address.gpsType == GpsType.exact
                ? Icons.location_on
                : Icons.flag,
            onLandmarkTap: _openLandmarkDetail,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),

          // ---- Repères ----
          Row(
            children: [
              Text('Repères', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const ContextualHelpButton(
                articleIds: [
                  'quest-ce-repere',
                  'ajouter-repere',
                  'bien-choisir-repere',
                  'modifier-supprimer-repere',
                ],
                title: 'Aide sur les repères',
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter un repère',
                  onPressed: () async {
                    final ok = await showLandmarkFormSheet(context,
                        addressId: address.id!);
                    if (ok == true) _loadAll();
                  },
                ),
            ],
          ),
          if (_landmarks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucun repère pour le moment.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ..._landmarks.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: LandmarkCard(
                  landmark: l,
                  onTap: () => _openLandmarkDetail(l),
                  trailing: isOwner
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: _busy ? null : () => _editLandmark(l),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed:
                                  _busy ? null : () => _deleteLandmark(l),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.md),
          const Divider(),

          // ---- Étapes ----
          Row(
            children: [
              Text('Étapes du trajet',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const ContextualHelpButton(
                articleIds: [
                  'ajouter-etape',
                  'ordre-etapes',
                  'bonne-description-etape',
                  'modifier-supprimer-etape',
                ],
                title: 'Aide sur les étapes',
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Ajouter une étape',
                  onPressed: () async {
                    final ok = await showRouteStepFormSheet(
                      context,
                      addressId: address.id!,
                      landmarks: _landmarks,
                      nextStepOrder: _steps.length + 1,
                    );
                    if (ok == true) _loadAll();
                  },
                ),
            ],
          ),
          if (_steps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucune étape pour le moment.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ..._steps.map((s) {
              final matches = _landmarks.where((l) => l.id == s.landmarkId);
              final landmark = matches.isEmpty ? null : matches.first;
              return Card(
                child: ListTile(
                  onTap: () => _openStepDetail(s),
                  leading: CircleAvatar(child: Text('${s.stepOrder}')),
                  title: Text(s.instruction),
                  subtitle: Text([
                    if (s.distance != null)
                      '${s.distance!.toStringAsFixed(0)} m',
                    if (s.direction != null) s.direction!,
                    if (landmark != null) 'Repère : ${landmark.name}',
                  ].join(' · ')),
                  trailing: isOwner
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: _busy ? null : () => _editStep(s),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: _busy ? null : () => _deleteStep(s),
                            ),
                          ],
                        )
                      : const Icon(Icons.chevron_right),
                ),
              );
            }),
        ],
      ),
    );
  }
}
