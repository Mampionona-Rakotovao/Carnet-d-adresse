import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/app_feedback.dart';
import 'supabase_client.dart';

bool _initialized = false;
bool _checking = false;

/// Prévient le propriétaire d'un lien partagé, au moment où il se connecte,
/// que des personnes ont ouvert ses liens depuis sa dernière connexion.
///
/// La notification (message + son) est affichée sur l'appareil du propriétaire
/// dès que son compte est connecté. La date de dernière vérification est
/// mémorisée localement par compte pour ne pas rejouer deux fois la même
/// alerte.
void initShareOpenNotifications() {
  if (_initialized) return;
  _initialized = true;

  supabase.auth.onAuthStateChange.listen((state) {
    final userId = state.session?.user.id;
    if (userId == null) return;
    if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.initialSession) {
      _scheduleCheck(userId);
    }
  });

  // Au démarrage, la session restaurée est déjà disponible : l'événement
  // initialSession a été émis pendant initSupabase(), avant cet abonnement.
  final currentUserId = supabase.auth.currentUser?.id;
  if (currentUserId != null) _scheduleCheck(currentUserId);
}

void _scheduleCheck(String userId) {
  // Attendre la première frame pour que le ScaffoldMessenger soit monté, puis
  // laisser la navigation post-connexion s'installer avant d'afficher le
  // message.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 600),
        () => _notifyPendingShareOpens(userId),
      ),
    );
  });
}

Future<void> _notifyPendingShareOpens(String userId) async {
  if (_checking) return;
  _checking = true;

  try {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenKey = 'share_open_last_seen_$userId';
    final lastSeenRaw = prefs.getString(lastSeenKey);
    final lastSeen =
        lastSeenRaw != null ? DateTime.tryParse(lastSeenRaw)?.toUtc() : null;

    // La politique RLS `share_link_uses_select_owner` limite ces lignes aux
    // ouvertures des liens appartenant à l'utilisateur connecté.
    final result = await supabase
        .from('share_link_uses')
        .select('share_link_id, used_by, used_at')
        .order('used_at', ascending: false);

    final rows = (result as List).cast<Map<String, dynamic>>();
    final pending = <Map<String, dynamic>>[];
    DateTime? newest;

    for (final row in rows) {
      final usedAt =
          DateTime.tryParse(row['used_at'] as String? ?? '')?.toUtc();
      if (usedAt == null) continue;
      if (newest == null || usedAt.isAfter(newest)) newest = usedAt;
      if (lastSeen == null || usedAt.isAfter(lastSeen)) pending.add(row);
    }

    if (pending.isEmpty) {
      if (lastSeen == null) {
        // Première connexion : on mémorise maintenant pour ne pas rejouer
        // d'anciennes ouvertures au prochain démarrage.
        await prefs.setString(
          lastSeenKey,
          DateTime.now().toUtc().toIso8601String(),
        );
      }
      return;
    }

    final message = await _buildMessage(pending);
    await _showNotification(message);

    if (newest != null) {
      await prefs.setString(lastSeenKey, newest.toIso8601String());
    }
  } catch (_) {
    // Une notification manquée ne doit jamais perturber l'application.
  } finally {
    _checking = false;
  }
}

Future<String> _buildMessage(List<Map<String, dynamic>> pending) async {
  final linkIds = pending
      .map((row) => row['share_link_id'])
      .whereType<String>()
      .toSet()
      .toList();

  final names = <String>{};
  try {
    final links = await supabase
        .from('share_links')
        .select('id, address_id')
        .inFilter('id', linkIds);

    final addressIds = (links as List)
        .map((row) => row['address_id'])
        .whereType<String>()
        .toSet()
        .toList();

    if (addressIds.isNotEmpty) {
      final addresses = await supabase
          .from('addresses')
          .select('name')
          .inFilter('id', addressIds);
      for (final row in addresses as List) {
        final name = (row as Map<String, dynamic>)['name'] as String?;
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }
  } catch (_) {
    // Sans les noms, on garde un message générique.
  }

  if (pending.length == 1) {
    final opener = await _openerName(pending.first['used_by'] as String?);
    final address =
        names.isNotEmpty ? '« ${names.first} »' : 'ton lien partagé';
    return opener != null
        ? '$opener a ouvert $address'
        : 'Quelqu\'un a ouvert $address';
  }

  final count = pending.length;
  if (names.isEmpty) {
    return '$count ouvertures sur tes liens partagés';
  }
  final list = names.map((n) => '« $n »').join(', ');
  return '$count ouvertures sur tes liens partagés : $list';
}

Future<String?> _openerName(String? usedBy) async {
  if (usedBy == null) return null;
  try {
    final profile = await supabase
        .from('profiles')
        .select('name')
        .eq('id', usedBy)
        .maybeSingle();
    final name = profile?['name'] as String?;
    return name != null && name.isNotEmpty ? name : null;
  } catch (_) {
    return null;
  }
}

Future<void> _showNotification(String message) async {
  var messenger = appMessengerKey.currentState;
  if (messenger == null) {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    messenger = appMessengerKey.currentState;
  }
  AppSnack.notificationOn(messenger, message);
}
