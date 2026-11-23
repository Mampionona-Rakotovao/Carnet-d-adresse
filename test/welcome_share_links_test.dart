import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:carnet_adresses_repere/models/address.dart';
import 'package:carnet_adresses_repere/models/share_link.dart';
import 'package:carnet_adresses_repere/ui/address_actions_menu.dart';
import 'package:carnet_adresses_repere/ui/address_list_card.dart';

ShareLink _link({
  ShareLinkStatus status = ShareLinkStatus.active,
  DateTime? expiresAt,
  int? maxUses,
  int usedCount = 0,
  DateTime? revokedAt,
}) =>
    ShareLink(
      id: 'link-1',
      addressId: 'address-1',
      createdBy: 'owner-1',
      token: 'token-12345678',
      status: status,
      expiresAt: expiresAt,
      maxUses: maxUses,
      usedCount: usedCount,
      revokedAt: revokedAt,
      createdAt: DateTime(2026),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async => call.method == 'getAll' ? <String, Object>{} : null,
    );
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  group('règle du lien actif partagée', () {
    test('un lien simple est actif', () {
      expect(_link().isEffectivelyActive, isTrue);
      expect(_link().statusLabel, 'Actif');
    });

    test('révoqué, expiré et complet ne sont pas actifs', () {
      expect(_link(status: ShareLinkStatus.revoked).isEffectivelyActive, isFalse);
      expect(_link(revokedAt: DateTime(2026)).statusLabel, 'Révoqué');
      expect(
        _link(expiresAt: DateTime(2020)).statusLabel,
        'Expiré',
      );
      expect(
        _link(maxUses: 2, usedCount: 2).statusLabel,
        'Complet',
      );
    });
  });

  testWidgets('la carte expose un menu « Plus d’actions » sans voler l’appui',
      (tester) async {
    final address = Address(
      id: 'address-1',
      ownerId: 'owner-1',
      name: 'Maison',
      visibility: AddressVisibility.private,
      latitude: 0,
      longitude: 0,
    );
    var cardTaps = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AddressListCard(
          address: address,
          onTap: () => cardTaps++,
          actions: AddressActionsMenu(
            address: address,
            isFavorite: false,
            onFavoriteChanged: (_) {},
            onDeleted: (_) {},
          ),
        ),
      ),
    ));

    final semantics = tester.ensureSemantics();
    final button = find.byTooltip("Plus d'actions");
    expect(button, findsOneWidget);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel("Plus d'actions"), findsWidgets);
    semantics.dispose();

    await tester.tap(find.text('Maison'));
    expect(cardTaps, 1);

    await tester.tap(button);
    await tester.pump();
    expect(cardTaps, 1);
    expect(find.text('Ajouter aux favoris'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Supprimer'), findsNothing);
  });
}
