import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Solution de secours : ouvre l'itinéraire dans Google Maps.
Future<bool> ouvrirNavigation(LatLng destination) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=${destination.latitude},${destination.longitude}'
    '&travelmode=driving',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
