import 'supabase_client.dart';

/// Accès aux lignes de la table "favorites" de l'utilisateur connecté.
///
/// RG13 : un favori n'est pas un droit d'accès. Ces fonctions ne contrôlent
/// jamais si l'utilisateur a le droit de voir l'adresse : c'est la RLS sur
/// "addresses" qui filtre, au moment de la lecture, ce qui est réellement
/// visible. Une adresse retirée des droits disparaît donc d'elle-même des
/// listes, sans qu'il faille nettoyer "favorites".
String get _currentUserId => supabase.auth.currentUser!.id;

/// Ids des adresses mises en favori, du plus récent au plus ancien.
Future<List<String>> favoriteAddressIds() async {
  final rows = await supabase
      .from('favorites')
      .select('address_id')
      .eq('user_id', _currentUserId)
      .order('created_at', ascending: false);

  return (rows as List).map((r) => r['address_id'] as String).toList();
}

/// L'adresse est-elle dans les favoris de l'utilisateur ?
Future<bool> isFavorite(String addressId) async {
  final rows = await supabase
      .from('favorites')
      .select('address_id')
      .eq('user_id', _currentUserId)
      .eq('address_id', addressId);

  return (rows as List).isNotEmpty;
}

Future<void> addFavorite(String addressId) async {
  await supabase
      .from('favorites')
      .insert({'user_id': _currentUserId, 'address_id': addressId});
}

Future<void> removeFavorite(String addressId) async {
  await supabase
      .from('favorites')
      .delete()
      .eq('user_id', _currentUserId)
      .eq('address_id', addressId);
}

/// Ajoute ou retire l'adresse des favoris selon son état actuel.
///
/// [currentlyFavorite] est l'état connu par l'écran : on ne relit pas la
/// ligne avant d'écrire, l'utilisateur vient de voir l'étoile changer.
Future<void> toggleFavorite(
  String addressId,
  bool currentlyFavorite,
) async {
  if (currentlyFavorite) {
    await removeFavorite(addressId);
  } else {
    await addFavorite(addressId);
  }
}