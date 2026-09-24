import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/supabase_client.dart';
import '../../models/address.dart';

class AddressCreateScreen extends StatefulWidget {
  const AddressCreateScreen({super.key});

  @override
  State<AddressCreateScreen> createState() => _AddressCreateScreenState();
}

class _AddressCreateScreenState extends State<AddressCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localityController = TextEditingController();

  AddressVisibility _visibility = AddressVisibility.private;
  GpsType _gpsType = GpsType.exact;

  double? _latitude;
  double? _longitude;
  bool _locatingGps = false;
  bool _saving = false;
  String? _errorMessage;

  Future<void> _captureGps() async {
    setState(() {
      _locatingGps = true;
      _errorMessage = null;
    });
    try {
      // Vérifie que le service de localisation est activé.
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Le GPS est désactivé sur cet appareil.';
      }

      // Gère la permission (RG : le GPS peut être indisponible ou refusé).
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
      setState(() => _errorMessage = 'Capture la position GPS avant d\'enregistrer.');
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final userId = supabase.auth.currentUser!.id;
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

      await supabase.from('addresses').insert(address.toInsertJson());

      if (mounted) {
        context.pop(true); // true = adresse créée avec succès
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle adresse')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}