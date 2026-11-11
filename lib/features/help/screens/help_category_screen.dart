import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../ui/app_background.dart';
import '../../../ui/app_states.dart';
import '../data/help_content.dart';
import '../widgets/help_article_tile.dart';
import '../widgets/help_category_icons.dart';

class HelpCategoryScreen extends StatelessWidget {
  const HelpCategoryScreen({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final category = helpCategoryFromName(categoryName);

    if (category == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Aide')),
        body: AppBackground(
          style: AppBackgroundStyle.vide,
          child: AppEmptyState(
            icon: Icons.help_outline,
            title: 'Catégorie introuvable',
            message: 'Cette catégorie d’aide n’existe pas ou a été renommée.',
            actionLabel: 'Retour au centre d’aide',
            actionIcon: Icons.arrow_back,
            onAction: () => context.go('/aide'),
          ),
        ),
      );
    }

    final articles = helpArticlesForCategory(category);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(category.label)),
      body: AppBackground(
        style: AppBackgroundStyle.calme,
        child: ListView(
          padding: AppSpacing.list,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(helpCategoryIcon(category)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      articles.length == 1
                          ? '1 article'
                          : '${articles.length} articles',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < articles.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            HelpArticleTile(
              article: articles[i],
              onTap: () => context.push('/aide/${articles[i].id}'),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
