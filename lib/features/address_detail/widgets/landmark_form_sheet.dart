import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/supabase_client.dart';
import '../../../models/landmark.dart';

/// Ouvre un formulaire en bas d'écran pour créer ou modifier un repère.
/// Retourne true si l'enregistrement a réussi.
///
/// [nextPositionOrder] est utilisé uniquement en création : il place le
/// nouveau repère à la bonne place dans l'ordre du trajet.
Future<bool?> showLandmarkFormSheet(
  BuildContext context, {
  required String addressId,
  Landmark? existing,
  int? nextPositionOrder,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LandmarkFormSheet(
      addressId: addressId,
      existing: existing,
      nextPositionOrder: nextPositionOrder,
    ),
  );
}

class _LandmarkFormSheet extends StatefulWidget {
  final String addressId;
  final Landmark? existing;
  final int? nextPositionOrder;
  const _LandmarkFormSheet({
    required this.addressId,
    this.existing,
    this.nextPositionOrder,
  });

  @override
  State<_LandmarkFormSheet> createState() => _LandmarkFormSheetState();
}

class _LandmarkFormSheetState extends State<_LandmarkFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  Uint8List? _pickedBytes;
  String? _pickedFileName;
  String? _existingPhotoUrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _existingPhotoUrl = widget.existing?.photoUrl;
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _pickedFileName = picked.name;
    });
  }

  Future<String?> _uploadPhotoIfNeeded() async {
    if (_pickedBytes == null) return _existingPhotoUrl;

    // On ignore le nom d'origine (peut contenir espaces, accents,
    // apostrophes... refusés par Supabase Storage) et on ne garde
    // que l'extension, avec un nom généré sûr et unique.
    final rawExt = (_pickedFileName != null && _pickedFileName!.contains('.'))
        ? _pickedFileName!.split('.').last.toLowerCase()
        : 'jpg';
    final ext = RegExp(r'^[a-z0-9]{1,5}$').hasMatch(rawExt) ? rawExt : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '${widget.addressId}/$fileName';

    await supabase.storage.from('photos').uploadBinary(path, _pickedBytes!);
    return supabase.storage.from('photos').getPublicUrl(path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final photoUrl = await _uploadPhotoIfNeeded();
      final landmark = Landmark(
        id: widget.existing?.id,
        addressId: widget.addressId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        photoUrl: photoUrl,
        positionOrder:
            widget.existing?.positionOrder ?? widget.nextPositionOrder ?? 0,
      );

      if (widget.existing != null) {
        await supabase
            .from('landmarks')
            .update(landmark.toInsertJson())
            .eq('id', widget.existing!.id!);
      } else {
        await supabase.from('landmarks').insert(landmark.toInsertJson());
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
              widget.existing != null ? 'Modifier le repère' : 'Nouveau repère',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_pickedBytes!, fit: BoxFit.cover),
                      )
                    : (_existingPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          )),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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