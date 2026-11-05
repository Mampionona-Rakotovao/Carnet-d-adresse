import 'package:flutter/material.dart';

import '../models/help_article.dart';

IconData helpCategoryIcon(HelpCategory category) => switch (category) {
      HelpCategory.demarrer => Icons.rocket_launch_outlined,
      HelpCategory.adresses => Icons.place_outlined,
      HelpCategory.reperes => Icons.signpost_outlined,
      HelpCategory.etapes => Icons.alt_route_outlined,
      HelpCategory.carte => Icons.map_outlined,
      HelpCategory.trajet => Icons.directions_outlined,
      HelpCategory.partage => Icons.share_outlined,
      HelpCategory.favorisRecherche => Icons.search_outlined,
      HelpCategory.confidentialite => Icons.lock_outline,
      HelpCategory.depannage => Icons.build_outlined,
    };
