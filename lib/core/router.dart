import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/address_create/address_form_screen.dart';
import '../features/address_detail/address_detail_screen.dart';
import '../models/address.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GoRouter router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
  redirect: (context, state) {
    final loggedIn = supabase.auth.currentSession != null;
    final onLoginPage = state.matchedLocation == '/login';

    if (!loggedIn && !onLoginPage) return '/login';
    if (loggedIn && onLoginPage) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    // IMPORTANT : /address/create doit être déclaré AVANT /address/:id,
    // sinon go_router pourrait interpréter "create" comme un id.
    GoRoute(
      path: '/address/create',
      builder: (context, state) => const AddressFormScreen(),
    ),
    GoRoute(
      path: '/address/:id/edit',
      builder: (context, state) => AddressFormScreen(
        existingAddress: state.extra as Address?,
      ),
    ),
    GoRoute(
      path: '/address/:id',
      builder: (context, state) => AddressDetailScreen(
        addressId: state.pathParameters['id']!,
      ),
    ),
  ],
);