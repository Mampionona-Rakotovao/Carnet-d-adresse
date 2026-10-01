import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/landmark.dart';
import '../../models/route_step.dart';

/// Écran affiché juste après la création d'une adresse : permet d'ajouter
/// les étapes du trajet une par une, dans l'ordre, sans quitter l'écran.
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
    setState(() {
      _landmarks = (rows as List).map((r) => Landmark.fromJson(r)).toList();
    });
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
        title: Text('Étapes · ${widget.addressName}'),
        automaticallyImplyLeading: false, // on force à passer par "Terminer"
      ),
      body: Column(
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
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${s.stepOrder}')),
                      title: Text(s.instruction),
                      subtitle: Text([
                        if (s.distance != null) '${s.distance!.toStringAsFixed(0)} m',
                        if (s.direction != null) s.direction!,
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
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Étape ${_steps.length + 1}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: _selectedLandmarkId,
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
                    if (_landmarks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "Aucun repère créé pour l'instant — tu pourras en "
                          "ajouter depuis le détail de l'adresse.",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 12),
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

          // ---- Bouton de fin ----
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: OutlinedButton(
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
}