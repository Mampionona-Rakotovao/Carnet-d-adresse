import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../models/address.dart';

/// Canal natif déclaré dans `MainActivity.kt` (Android uniquement).
const String screenSecurityChannelName = 'carnet_adresses/screen_security';

/// Protection des écrans contre les captures, l'enregistrement d'écran et
/// l'aperçu dans les applications récentes (Android `FLAG_SECURE`).
///
/// Un compteur de références permet d'empiler plusieurs écrans protégés
/// (lien partagé → repère → photo → guidage) : la protection n'est retirée
/// que quand le dernier écran quitte la page. Les appels natifs sont
/// sérialisés pour que `disable` ne puisse jamais précéder un `enable`
/// encore en vol.
class ScreenSecurity {
  ScreenSecurity({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(screenSecurityChannelName);

  final MethodChannel _channel;

  int _references = 0;
  Future<void> _appels = Future.value();

  /// Nombre d'écrans protégés actifs.
  int get referenceCount => _references;

  /// Vrai tant qu'au moins un écran demande la protection.
  bool get estActive => _references > 0;

  bool get _plateformeConcernee =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Active la protection quand on passe de 0 à 1 référence.
  Future<void> acquire() {
    if (!_plateformeConcernee) return Future.value();
    _references++;
    if (_references != 1) return _appels;
    return _appliquer(true);
  }

  /// Désactive la protection quand on revient à 0 référence.
  Future<void> release() {
    if (!_plateformeConcernee) return Future.value();
    if (_references == 0) return _appels;
    _references--;
    if (_references != 0) return _appels;
    return _appliquer(false);
  }

  /// Remet l'état à zéro (démarrage, déconnexion) : la protection est retirée
  /// même si un écran protégé n'a pas pu appeler [release].
  Future<void> reset() {
    _references = 0;
    if (!_plateformeConcernee) return Future.value();
    return _appliquer(false);
  }

  Future<void> _appliquer(bool activer) {
    final appel = _appels.then(
      (_) => _invoquer(activer),
      onError: (_) => _invoquer(activer),
    );
    _appels = appel;
    return appel;
  }

  Future<void> _invoquer(bool activer) async {
    try {
      await _channel.invokeMethod<void>(activer ? 'enable' : 'disable');
    } on MissingPluginException catch (_) {
      // Plateforme sans implémentation native (tests, navigateur, iOS).
    } on PlatformException catch (_) {
      // Une panne native ne doit jamais faire planter l'affichage.
    }
  }
}

/// Singleton utilisé par tous les écrans.
final ScreenSecurity screenSecurity = ScreenSecurity();

/// Règle unique d'activation de la protection.
///
/// Une adresse privée vue par quelqu'un d'autre que son propriétaire doit
/// être protégée. Un utilisateur non connecté est toujours un non-propriétaire.
/// [address] peut être une [Address] complète ou une entrée de la liste
/// « Partagées avec moi ». [estProprietaireConfirmee] relaye le champ
/// `is_owner` renvoyé par la RPC `redeem_share_link` : les liens partagés ne
/// contiennent pas `owner_id`, seule la base peut affirmer que le lecteur est
/// le propriétaire.
bool doitProtegerCapture(
  AdresseAvecVisibilite address,
  User? user, {
  bool? estProprietaireConfirmee,
}) {
  if (address.visibility != AddressVisibility.private) return false;
  final ownerId = address.ownerId;
  final proprietaire = estProprietaireConfirmee ??
      (ownerId != null && ownerId.isNotEmpty && ownerId == user?.id);
  return !proprietaire;
}
