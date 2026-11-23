import 'package:flutter/foundation.dart';

/// Signal unique envoyé après toute action qui modifie les adresses, les
/// favoris ou les liens de partage.
///
/// Les écrans qui affichent ces données (Bienvenue, Adresses, Favoris)
/// s'abonnent à ce notifier pour se rafraîchir, sans avoir à se connaître.
/// La valeur n'a pas d'importance : seul le changement déclenche le rechargement.
final ValueNotifier<int> addressDataRevision = ValueNotifier<int>(0);

/// À appeler après une action réussie (favori, partage, modification,
/// suppression) pour que tous les écrans concernés se resynchronisent.
void notifyAddressDataChanged() => addressDataRevision.value++;
