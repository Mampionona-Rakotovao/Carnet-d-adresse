import 'package:supabase_flutter/supabase_flutter.dart';

/// Raccourci pour accéder au client Supabase partout dans l'app.
final supabase = Supabase.instance.client;

/// À appeler une seule fois, au tout début de main().
///
/// Récupère l'URL et la clé anon dans Supabase :
/// Project Settings -> API -> Project URL / anon public key
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://fruewgugbnugatjaxvyb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZydWV3Z3VnYm51Z2F0amF4dnliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAxNTU5NDUsImV4cCI6MjEwNTczMTk0NX0.6SOCRByIb63VhL4M6PNyJPjTdkk5aJC77N0uQ-_eo_8',
  );
}