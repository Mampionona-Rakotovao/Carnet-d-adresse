import 'package:flutter/material.dart';
import '../../../core/supabase_client.dart';
import '../../../models/landmark.dart';
import '../../../models/route_step.dart';

/// Ouvre un formulaire en bas d'écran pour créer ou modifier une étape.
/// Retourne true si l'enregistrement a réussi.
Future<bool?> showRouteStepFormSheet(
  BuildContext context, {
  required String addressId,
  required List<Landmark> landmarks,
  required int nextStepOrder,
  RouteStep? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RouteStepFormSheet(
      addressId: addressId,
      landmarks: landmarks,
      nextStepOrder: nextStepOrder,
      existing: existing,
    ),
  );
}

class _RouteStepFormSheet extends StatefulWidget {
  final String addressId;
  final List<Landmark> landmarks;
  final int nextStepOrder;
  final RouteStep? existing;

  const _RouteStepFormSheet({
    required this.addressId,
    required this.landmarks,
    required this.nextStepOrder,
    this.existing,
  });

  @override
  State<_RouteStepFormSheet> createState() => _RouteStepFormSheetState();
}

class _RouteStepFormSheetState extends State<_RouteStepFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _instructionController;
  late final TextEditingController _distanceController;
  late final TextEditingController _directionController;
  String? _selectedLandmarkId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _instructionController =
        TextEditingController(text: widget.existing?.instruction ?? '');
    _distanceController = TextEditingController(
      text: widget.existing?.distance?.toString() ?? '',
    );
    _directionController =
        TextEditingController(text: widget.existing?.direction ?? '');
    _selectedLandmarkId = widget.existing?.landmarkId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final step = RouteStep(
        id: widget.existing?.id,
        addressId: widget.addressId,
        stepOrder: widget.existing?.stepOrder ?? widget.nextStepOrder,
        instruction: _instructionController.text.trim(),
        distance: _distanceController.text.trim().isEmpty
            ? null
            : double.tryParse(_distanceController.text.trim()),
        direction: _directionController.text.trim().isEmpty
            ? null
            : _directionController.text.trim(),
        landmarkId: _selectedLandmarkId,
      );

      if (widget.existing != null) {
        await supabase
            .from('route_steps')
            .update(step.toInsertJson())
            .eq('id', widget.existing!.id!);
      } else {
        await supabase.from('route_steps').insert(step.toInsertJson());
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing != null
                  ? "Modifier l'étape"
                  : 'Nouvelle étape (#${widget.nextStepOrder})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instructionController,
              decoration: const InputDecoration(
                labelText: 'Instruction *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Instruction obligatoire' : null,
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
                const DropdownMenuItem<String?>(value: null, child: Text('Aucun')),
                ...widget.landmarks.map(
                  (l) => DropdownMenuItem<String?>(value: l.id, child: Text(l.name)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedLandmarkId = v),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}