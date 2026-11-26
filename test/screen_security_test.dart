import 'dart:async';

import 'package:carnet_adresses_repere/core/screen_security.dart';
import 'package:carnet_adresses_repere/models/address.dart';
import 'package:carnet_adresses_repere/models/shared_address.dart';
import 'package:carnet_adresses_repere/ui/screen_protection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Enregistre les appels natifs sans avoir besoin d'un appareil Android.
final class _ChannelEspion {
  _ChannelEspion() {
    channel = const MethodChannel(screenSecurityChannelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      methodes.add(call.method);
      return null;
    });
  }

  late final MethodChannel channel;
  final List<String> methodes = <String>[];

  void dispose() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

/// Compteur de cycles de vie, sans canal natif.
final class _SecuriteCompteur extends ScreenSecurity {
  int acquisitions = 0;
  int releases = 0;

  @override
  Future<void> acquire() async {
    acquisitions++;
  }

  @override
  Future<void> release() async {
    releases++;
  }
}

User _utilisateur(String id) => User(
      id: id,
      appMetadata: const <String, dynamic>{},
      userMetadata: null,
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    );

Address _adresse({
  required AddressVisibility visibilite,
  required String proprietaire,
}) =>
    Address(
      id: 'a1',
      ownerId: proprietaire,
      name: 'Adresse',
      visibility: visibilite,
      latitude: 0,
      longitude: 0,
    );

void main() {
  group('ScreenSecurity', () {
    late TargetPlatform? plateformeInitiale;

    setUp(() {
      plateformeInitiale = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = plateformeInitiale;
    });

    test('active une seule fois, désactive au dernier écran', () async {
      final espion = _ChannelEspion();
      addTearDown(espion.dispose);
      final securite = ScreenSecurity(channel: espion.channel);

      await securite.acquire();
      await securite.acquire();
      expect(securite.referenceCount, 2);
      expect(securite.estActive, isTrue);
      expect(espion.methodes, ['enable']);

      await securite.release();
      expect(securite.referenceCount, 1);
      expect(espion.methodes, ['enable']);

      await securite.release();
      expect(securite.referenceCount, 0);
      expect(securite.estActive, isFalse);
      expect(espion.methodes, ['enable', 'disable']);

      // Un release supplémentaire ne retire pas deux fois le drapeau.
      await securite.release();
      expect(espion.methodes, ['enable', 'disable']);
    });

    test('sérialise enable et disable même si les appels se chevauchent',
        () async {
      final espion = _ChannelEspion();
      addTearDown(espion.dispose);
      final ordre = <String>[];
      final barrier = Completer<void>();
      final premierAppel = Completer<void>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(espion.channel, (call) async {
        ordre.add('${call.method}:debut');
        if (call.method == 'enable') {
          if (!premierAppel.isCompleted) premierAppel.complete();
          await barrier.future;
        }
        ordre.add('${call.method}:fin');
        return null;
      });

      final securite = ScreenSecurity(channel: espion.channel);
      final premier = securite.acquire();
      final second = securite.acquire();
      // Deux références → deux libérations avant de retirer le drapeau.
      final premiereLiberation = securite.release();
      final derniereLiberation = securite.release();

      await premierAppel.future;
      expect(ordre, ['enable:debut']);
      barrier.complete();
      await Future.wait([
        premier,
        second,
        premiereLiberation,
        derniereLiberation,
      ]);

      expect(ordre, [
        'enable:debut',
        'enable:fin',
        'disable:debut',
        'disable:fin',
      ]);
    });

    test('reset ramène le compteur à zéro et retire la protection', () async {
      final espion = _ChannelEspion();
      addTearDown(espion.dispose);
      final securite = ScreenSecurity(channel: espion.channel);

      await securite.acquire();
      await securite.acquire();
      await securite.reset();

      expect(securite.referenceCount, 0);
      expect(espion.methodes, ['enable', 'disable']);
      await securite.release();
      expect(espion.methodes, ['enable', 'disable']);
    });

    test('un plugin natif absent ne fait pas planter l’écran', () async {
      final securite = ScreenSecurity(
        channel: const MethodChannel('carnet_adresses/sans_plugin'),
      );

      await securite.acquire();
      await securite.release();

      expect(securite.referenceCount, 0);
    });
  });

  group('doitProtegerCapture', () {
    test('protège une adresse privée lue par un autre compte', () {
      final privee = _adresse(
        visibilite: AddressVisibility.private,
        proprietaire: 'proprietaire',
      );

      expect(doitProtegerCapture(privee, _utilisateur('visiteur')), isTrue);
    });

    test('ne protège pas une adresse privée lue par son propriétaire', () {
      final privee = _adresse(
        visibilite: AddressVisibility.private,
        proprietaire: 'proprietaire',
      );

      expect(
          doitProtegerCapture(privee, _utilisateur('proprietaire')), isFalse);
    });

    test('un utilisateur non connecté est toujours un non-propriétaire', () {
      final privee = _adresse(
        visibilite: AddressVisibility.private,
        proprietaire: 'proprietaire',
      );

      expect(doitProtegerCapture(privee, null), isTrue);
    });

    test('une adresse publique n’est jamais protégée', () {
      final publique = _adresse(
        visibilite: AddressVisibility.public,
        proprietaire: 'proprietaire',
      );

      expect(doitProtegerCapture(publique, null), isFalse);
      expect(
        doitProtegerCapture(publique, _utilisateur('visiteur')),
        isFalse,
      );
    });

    test('is_owner de la RPC prime sur owner_id absent du lien', () {
      final sansProprietaire = _adresse(
        visibilite: AddressVisibility.private,
        proprietaire: '',
      );

      expect(
        doitProtegerCapture(
          sansProprietaire,
          _utilisateur('visiteur'),
          estProprietaireConfirmee: false,
        ),
        isTrue,
      );
      expect(
        doitProtegerCapture(
          sansProprietaire,
          _utilisateur('visiteur'),
          estProprietaireConfirmee: true,
        ),
        isFalse,
      );
    });

    test('applique la même règle aux entrées « Partagées avec moi »', () {
      const entre = SharedAddressEntry(
        token: 'jeton',
        expiresAt: null,
        name: 'Adresse',
        visibility: AddressVisibility.private,
        sharedById: 'proprietaire',
      );

      expect(doitProtegerCapture(entre, _utilisateur('visiteur')), isTrue);
      expect(doitProtegerCapture(entre, _utilisateur('proprietaire')), isFalse);
    });

    test('une visibilité absente du payload est traitée comme privée', () {
      final entre = SharedAddressEntry.fromJson({
        'token': 'jeton',
        'expires_at': null,
        'address': {
          'id': 'a1',
          'name': 'Adresse',
          'photo_url': 'https://example.fr/photo.jpg',
        },
        'shared_by': {'id': 'proprietaire', 'name': 'Camille'},
      });

      expect(entre.visibility, AddressVisibility.private);
      expect(entre.sharedById, 'proprietaire');
      expect(doitProtegerCapture(entre, _utilisateur('visiteur')), isTrue);
    });
  });

  testWidgets('ScreenProtection acquiert et libère une seule fois',
      (tester) async {
    final securite = _SecuriteCompteur();
    Widget ecran({required bool actif}) => MaterialApp(
          home: SizedBox.expand(
            child: ScreenProtection(
              enabled: actif,
              security: securite,
              child: const Text('Contenu protégé'),
            ),
          ),
        );

    await tester.pumpWidget(ecran(actif: false));
    expect(securite.acquisitions, 0);

    await tester.pumpWidget(ecran(actif: true));
    expect(securite.acquisitions, 1);
    expect(
      find.text('Adresse privée : les captures d’écran sont désactivées'),
      findsOneWidget,
    );

    await tester.pumpWidget(ecran(actif: true));
    expect(securite.acquisitions, 1);

    await tester.pumpWidget(ecran(actif: false));
    expect(securite.releases, 1);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(securite.releases, 1);
  });
}
