import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await supabase.auth.signOut();
              // go_router redirige automatiquement vers /login.
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Connecté en tant que ${user?.email ?? "?"}'),
            const SizedBox(height: 8),
            const Text(
              'Aucune adresse pour le moment.\n'
              "L'écran de création arrive à la prochaine étape.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      // Prochaine étape : bouton "+" pour créer une adresse
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Écran de création à venir')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}