import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const webClientId =
    '792316457025-4jh4imv65sud964gp0s75vir64r8pgi2.apps.googleusercontent.com';

bool _googleInitialized = false;

Future<AuthResponse> signInWithGoogle() async {
  final supabase = Supabase.instance.client;
  final googleSignIn = GoogleSignIn.instance;

  if (!_googleInitialized) {
    await googleSignIn.initialize(serverClientId: webClientId);
    _googleInitialized = true;
  }

  final googleUser = await googleSignIn.authenticate();
  final idToken = googleUser.authentication.idToken;

  if (idToken == null) {
    throw const AuthException('Aucun ID token reçu de Google.');
  }

  return supabase.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
  );
}