import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';

/// Formulaire unique pour créer OU modifier une adresse.
/// Si [existingAddress] est fourni, l'écran passe en mode édition
/// (champs pré-remplis, update au lieu d'insert).
class AddressFormScreen extends StatefulWidget {
  final Address? existingAddress;

  const AddressFormScreen({super.key, this.existingAddress});

  bool get isEditMode => existingAddress != null;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _localityController;

  late AddressVisibility _visibility;
  late GpsType _gpsType;
  double? _latitude;
  double? _longitude;
  Uint8List? _pickedPhotoBytes;
  String? _pickedPhotoExt;
  String? _existingPhotoUrl;

  bool _locatingGps = false;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAddress;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _localityController = TextEditingController(text: existing?.locality ?? '');
    _visibility = existing?.visibility ?? AddressVisibility.private;
    _gpsType = existing?.gpsType ?? GpsType.exact;
    _latitude = existing?.latitude;
    _longitude = existing?.longitude;
    _existingPhotoUrl = existing?.photoUrl;
  }

  Future<void> _pickPhoto() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final rawExt = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'jpg';
    setState(() {
      _pickedPhotoBytes = bytes;
      _pickedPhotoExt = RegExp(r'^[a-z0-9]{1,5}$').hasMatch(rawExt) ? rawExt : 'jpg';
    });
  }

  Future<void> _captureGps() async {
    setState(() {
      _locatingGps = true;
      _errorMessage = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Le GPS est désactivé sur cet appareil.';
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "L'autorisation de localisation a été refusée.";
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Autorisation refusée définitivement. Active-la dans les paramètres.';
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      setState(() => _errorMessage = "Capture la position GPS avant d'enregistrer.");
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;

      if (widget.isEditMode) {
        // Édition : l'id existe déjà, on peut uploader directement dessous.
        final photoUrl = await _uploadPhotoIfNeeded(widget.existingAddress!.id!);
        final address = Address(
          ownerId: userId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          locality: _localityController.text.trim().isEmpty
              ? null
              : _localityController.text.trim(),
          visibility: _visibility,
          latitude: _latitude!,
          longitude: _longitude!,
          gpsType: _gpsType,
          photoUrl: photoUrl,
        );
        await supabase
            .from('addresses')
            .update(address.toInsertJson())
            .eq('id', widget.existingAddress!.id!);
      } else {
        // Création : il faut d'abord insérer pour obtenir l'id généré
        // par la base, PUIS uploader la photo sous ce dossier, PUIS
        // mettre à jour la ligne avec l'URL de la photo.
        final address = Address(
          ownerId: userId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          locality: _localityController.text.trim().isEmpty
              ? null
              : _localityController.text.trim(),
          visibility: _visibility,
          latitude: _latitude!,
          longitude: _longitude!,
          gpsType: _gpsType,
        );

        final inserted = await supabase
            .from('addresses')
            .insert(address.toInsertJson())
            .select()
            .single();
        final newId = inserted['id'] as String;

        if (_pickedPhotoBytes != null) {
          final photoUrl = await _uploadPhotoIfNeeded(newId);
          await supabase.from('addresses').update({'photo_url': photoUrl}).eq('id', newId);
        }

        if (mounted) {
          // On enchaîne directement sur l'ajout des étapes, dans l'ordre,
          // au lieu de revenir en arrière.
          context.pushReplacement(
            '/address/$newId/steps',
            extra: _nameController.text.trim(),
          );
          return;
        }
      }

      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Upload la photo sélectionnée sous le dossier de l'adresse et
  /// retourne son URL publique. Retourne l'URL existante si aucune
  /// nouvelle photo n'a été choisie.
  Future<String?> _uploadPhotoIfNeeded(String addressId) async {
    if (_pickedPhotoBytes == null) return _existingPhotoUrl;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.${_pickedPhotoExt ?? 'jpg'}';
    final path = '$addressId/cover_$fileName';
    await supabase.storage.from('photos').uploadBinary(path, _pickedPhotoBytes!);
    return supabase.storage.from('photos').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? "Modifier l'adresse" : 'Nouvelle adresse'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Photo de couverture', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedPhotoBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_pickedPhotoBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : (_existingPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(_existingPhotoUrl!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Ajouter une photo (optionnel)', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _localityController,
              decoration: const InputDecoration(
                labelText: 'Localité',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Type de position', style: Theme.of(context).textTheme.titleSmall),
            RadioListTile<GpsType>(
              title: const Text('Position exacte'),
              subtitle: const Text('Le GPS pointe directement sur la destination'),
              value: GpsType.exact,
              groupValue: _gpsType,
              onChanged: (v) => setState(() => _gpsType = v!),
            ),
            RadioListTile<GpsType>(
              title: const Text("Point d'accès"),
              subtitle: const Text(
                'Le GPS pointe vers le dernier point atteignable ; les étapes complètent le trajet',
              ),
              value: GpsType.accessPoint,
              groupValue: _gpsType,
              onChanged: (v) => setState(() => _gpsType = v!),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _locatingGps ? null : _captureGps,
              icon: _locatingGps
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _latitude == null
                    ? 'Capturer ma position actuelle'
                    : 'Position : ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
              ),
            ),
            const SizedBox(height: 20),
            Text('Visibilité', style: Theme.of(context).textTheme.titleSmall),
            SegmentedButton<AddressVisibility>(
              segments: const [
                ButtonSegment(
                  value: AddressVisibility.public,
                  label: Text('Publique'),
                  icon: Icon(Icons.public),
                ),
                ButtonSegment(
                  value: AddressVisibility.private,
                  label: Text('Privée'),
                  icon: Icon(Icons.lock),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() => _visibility = s.first),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditMode ? 'Enregistrer les modifications' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}