import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Raccourci pour accéder au client Supabase partout dans l'app.
final supabase = Supabase.instance.client;

/// Crée ou complète la ligne `profiles` de l'utilisateur connecté.
///
/// Le nom saisi à l'inscription est transmis dans les métadonnées du compte
/// (`user_metadata.name`). Certaines configurations Supabase ne créent pas de
/// ligne `profiles` automatiquement : on s'en assure ici pour que le nom soit
/// disponible (notamment dans les liens partagés). Idempotent.
Future<void> ensureProfile() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final name = (user.userMetadata?['name'] as String?)?.trim();
  final data = <String, dynamic>{
    'id': user.id,
    if (user.email != null) 'email': user.email,
    if (name != null && name.isNotEmpty) 'name': name,
  };

  try {
    await supabase.from('profiles').upsert(data);
  } catch (e) {
    // Best effort : un échec de profil ne doit pas bloquer la connexion.
    debugPrint('ensureProfile a échoué : $e');
  }
}

/// À appeler une seule fois, au tout début de main().
///
/// Récupère l'URL et la clé anon dans Supabase :
/// Project Settings -> API -> Project URL / anon public key
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://fruewgugbnugatjaxvyb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZydWV3Z3VnYm51Z2F0amF4dnliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxNTU5NDUsImV4cCI6MjEwNTczMTk0NX0.6SOCRByIb63VhL4M6PNyJPjTdkk5aJC77N0uQ-_eo_8',
    // Flux « implicit » volontaire pour la réinitialisation de mot de passe :
    // le lien reçu par email contient directement les jetons (validés par
    // Supabase), au lieu d'un code PKCE dont le « verifier » n'existe que
    // dans le navigateur qui a demandé le lien. Sineon, ouvrir le lien dans
    // un autre navigateur (Chrome → Firefox) échoue à créer la session.
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );
}