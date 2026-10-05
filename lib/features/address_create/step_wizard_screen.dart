import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';
import '../address_detail/widgets/landmark_form_sheet.dart';
import '../../core/theme/app_spacing.dart';

/// Écran affiché juste après la création d'une adresse : guide l'utilisateur
/// dans l'ordre « repères » puis « étapes du trajet », sans quitter l'écran.
class StepWizardScreen extends StatefulWidget {
  final String addressId;
  final String addressName;

  const StepWizardScreen({
    super.key,
    required this.addressId,
    required this.addressName,
  });

  @override
  State<StepWizardScreen> createState() => _StepWizardScreenState();
}

class _StepWizardScreenState extends State<StepWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instructionController = TextEditingController();
  final _distanceController = TextEditingController();
  final _directionController = TextEditingController();
  String? _selectedLandmarkId;

  final List<RouteStep> _steps = [];
  List<Landmark> _landmarks = [];
  bool _saving = false;
  String? _error;

  /// 0 = repères, 1 = étapes.
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    final rows = await supabase
        .from('landmarks')
        .select()
        .eq('address_id', widget.addressId)
        .order('position_order');
    if (!mounted) return;
    setState(() {
      _landmarks = (rows as List).map((r) => Landmark.fromJson(r)).toList();
    });
  }

  Future<void> _addLandmark() async {
    final ok = await showLandmarkFormSheet(
      context,
      addressId: widget.addressId,
      nextPositionOrder: _landmarks.length + 1,
    );
    if (ok == true) await _loadLandmarks();
  }

  Future<void> _addStep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final step = RouteStep(
        addressId: widget.addressId,
        stepOrder: _steps.length + 1,
        instruction: _instructionController.text.trim(),
        distance: _distanceController.text.trim().isEmpty
            ? null
            : double.tryParse(_distanceController.text.trim()),
        direction: _directionController.text.trim().isEmpty
            ? null
            : _directionController.text.trim(),
        landmarkId: _selectedLandmarkId,
      );

      final inserted = await supabase
          .from('route_steps')
          .insert(step.toInsertJson())
          .select()
          .single();

      setState(() {
        _steps.add(RouteStep.fromJson(inserted));
        // Formulaire vidé, prêt pour l'étape suivante.
        _instructionController.clear();
        _distanceController.clear();
        _directionController.clear();
        _selectedLandmarkId = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _finish() {
    // Remplace cet écran par le détail de l'adresse (pas d'empilement inutile).
    context.pushReplacement('/address/${widget.addressId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finaliser · ${widget.addressName}'),
        automaticallyImplyLeading: false, // on force à passer par "Terminer"
        actions: [
          if (_page == 1)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Retour aux repères',
              onPressed: () => setState(() => _page = 0),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: _PageChip(
                    label: 'Repères (${_landmarks.length})',
                    icon: Icons.place,
                    active: _page == 0,
                    onTap: () => setState(() => _page = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PageChip(
                    label: 'Étapes (${_steps.length})',
                    icon: Icons.route,
                    active: _page == 1,
                    onTap: () => setState(() => _page = 1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _page == 0 ? _buildLandmarksPage() : _buildStepsPage(),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              child: _page == 0
                  ? FilledButton.icon(
                      onPressed: () => setState(() => _page = 1),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Passer aux étapes du trajet'),
                    )
                  : OutlinedButton(
                      onPressed: _finish,
                      child: Text(
                        _steps.isEmpty
                            ? "Terminer sans ajouter d'étape"
                            : 'Terminer (${_steps.length} étape${_steps.length > 1 ? 's' : ''} ajoutée${_steps.length > 1 ? 's' : ''})',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarksPage() {
    return ListView(
      padding: AppSpacing.form,
      children: [
        Text('Repères', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          "Ce sont les points visibles qui mènent vers la destination "
          "(panneau, portail, borne, commerce...).",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: _addLandmark,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(
            _landmarks.isEmpty ? 'Ajouter un premier repère' : 'Ajouter un repère',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_landmarks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Aucun repère pour l'instant. Tu peux en créer ici ou plus tard "
              "depuis le détail de l'adresse.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._landmarks.map(
            (l) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: l.photoUrl != null ? NetworkImage(l.photoUrl!) : null,
                  child: l.photoUrl == null ? const Icon(Icons.place) : null,
                ),
                title: Text(l.name),
                subtitle: l.description != null ? Text(l.description!) : null,
                trailing: Text('${l.positionOrder}',
                    style: const TextStyle(color: Colors.grey)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStepsPage() {
    return Column(
      children: [
        // ---- Liste des étapes déjà ajoutées ----
        if (_steps.isNotEmpty)
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final s = _steps[index];
                final matches = _landmarks.where((l) => l.id == s.landmarkId);
                final landmark = matches.isEmpty ? null : matches.first;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${s.stepOrder}')),
                    title: Text(s.instruction),
                    subtitle: Text([
                      if (s.distance != null) '${s.distance!.toStringAsFixed(0)} m',
                      if (s.direction != null) s.direction!,
                      if (landmark != null) 'Repère : ${landmark.name}',
                    ].join(' · ')),
                  ),
                );
              },
            ),
          ),

        const Divider(height: 1),

        // ---- Formulaire pour la prochaine étape ----
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: AppSpacing.form,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Étape ${_steps.length + 1}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _instructionController,
                    decoration: const InputDecoration(
                      labelText: 'Instruction *',
                      hintText: 'Ex: Prendre le chemin à droite après le grand arbre',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Instruction obligatoire'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _distanceController,
                          decoration: const InputDecoration(
                            labelText: 'Distance (m)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _directionController,
                          decoration: const InputDecoration(
                            labelText: 'Direction',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedLandmarkId,
                    decoration: const InputDecoration(
                      labelText: 'Repère associé (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucun'),
                      ),
                      ..._landmarks.map(
                        (l) => DropdownMenuItem<String?>(
                          value: l.id,
                          child: Text(l.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedLandmarkId = v),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _addStep,
                    icon: _saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text('Ajouter cette étape (#${_steps.length + 1})'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton d'en-tête permettant de basculer entre la page « repères »
/// et la page « étapes » du wizard.
class _PageChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _PageChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}