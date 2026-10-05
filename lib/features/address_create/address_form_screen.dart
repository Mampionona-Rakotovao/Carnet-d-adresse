import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/supabase_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/address.dart';
import '../../ui/app_feedback.dart';
import '../../ui/section.dart';
import '../../ui/status_chip.dart';

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
  bool _locationBlocked = false;

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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _localityController.dispose();
    super.dispose();
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

  Future<void> _removePhoto() async {
    setState(() {
      _pickedPhotoBytes = null;
      _pickedPhotoExt = null;
      _existingPhotoUrl = null;
    });
  }

  Future<void> _captureGps() async {
    setState(() {
      _locatingGps = true;
      _locationBlocked = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        AppSnack.warning(context, 'Le GPS est désactivé sur cet appareil. Activez-le et réessayez.');
        setState(() => _locatingGps = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationBlocked = true;
          _locatingGps = false;
        });
        AppSnack.error(
          context,
          'L\'accès à la localisation est refusé définitivement. Vous pouvez le réactiver dans les paramètres.',
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        AppSnack.warning(context, 'L\'accès à la localisation est refusé.');
        setState(() => _locatingGps = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      AppSnack.success(context, 'Position GPS récupérée avec succès');
    } catch (e) {
      AppSnack.error(context, e);
    } finally {
      if (mounted) setState(() => _locatingGps = false);
    }
  }

  Future<void> _openSettingsAndRetry() async {
    await openAppSettings();
  }
  Future<String?> _uploadPhotoIfNeeded(String addressId) async {
    if (_pickedPhotoBytes == null) return _existingPhotoUrl;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.${_pickedPhotoExt ?? 'jpg'}';
    final path = '$addressId/cover_$fileName';
    await supabase.storage.from('photos').uploadBinary(path, _pickedPhotoBytes!);
    return supabase.storage.from('photos').getPublicUrl(path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      AppSnack.warning(context, 'Veuillez capturer la position GPS avant d\'enregistrer.');
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = supabase.auth.currentUser!.id;

      if (widget.isEditMode) {
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
        if (mounted) context.pop(true);
      } else {
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
          context.pushReplacement(
            '/address/$newId/steps',
            extra: _nameController.text.trim(),
          );
        }
      }
    } catch (e) {
      AppSnack.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? "Modifier l'adresse" : 'Nouvelle adresse'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.form,
          children: [
            FormSection(
              title: 'Photo du point de repère',
              icon: Icons.photo_camera_outlined,
              description: 'Ajoutez une photo pour faciliter la reconnaissance du lieu.',
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: AppRadius.cardRadius,
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.cardRadius,
                      child: _pickedPhotoBytes != null
                          ? Image.memory(
                              _pickedPhotoBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : (_existingPhotoUrl != null
                              ? Image.network(
                                  _existingPhotoUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 44,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'Appuyer pour ajouter une photo',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Optionnel',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                )),
                    ),
                  ),
                ),
                if (_pickedPhotoBytes != null || _existingPhotoUrl != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _removePhoto,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer la photo'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              title: 'Informations du lieu',
              icon: Icons.place_outlined,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du lieu *',
                    hintText: 'Ex. : Parking derrière la mairie',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Le nom est obligatoire'
                      : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Remarques sur le lieu (facultatif)',
                  ),
                  maxLines: 3,
                ),
                TextFormField(
                  controller: _localityController,
                  decoration: const InputDecoration(
                    labelText: 'Localité',
                    hintText: 'Commune, quartier, village (facultatif)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              title: 'Localisation',
              icon: Icons.gps_fixed,
              description: GpsType.exact.explanation,
              children: [
                SegmentedButton<GpsType>(
                  segments: const [
                    ButtonSegment(
                      value: GpsType.exact,
                      label: Text('Position exacte'),
                      icon: Icon(Icons.gps_fixed),
                    ),
                    ButtonSegment(
                      value: GpsType.accessPoint,
                      label: Text("Point d'accès"),
                      icon: Icon(Icons.route),
                    ),
                  ],
                  selected: {_gpsType},
                  onSelectionChanged: (s) {
                    setState(() => _gpsType = s.first);
                  },
                ),
                if (_gpsType == GpsType.accessPoint)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      GpsType.accessPoint.explanation,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _locatingGps ? null : _captureGps,
                  icon: _locatingGps
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _latitude == null || _longitude == null
                        ? 'Capturer ma position actuelle'
                        : 'Position : ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                  ),
                ),
                if (_locationBlocked)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.settings),
                      label: const Text('Ouvrir les paramètres du téléphone'),
                      onPressed: _openSettingsAndRetry,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              title: 'Visibilité',
              icon: Icons.visibility_outlined,
              description: 'Définissez qui peut voir cette adresse.',
              children: [
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
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    _visibility == AddressVisibility.public
                        ? AddressVisibility.public.explanation
                        : AddressVisibility.private.explanation,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
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
