import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../models/help_article.dart';
import 'highlighted_text.dart';

class HelpArticleTile extends StatelessWidget {
  const HelpArticleTile({
    super.key,
    required this.article,
    required this.onTap,
    this.query = '',
    this.showCategory = false,
    this.subtitleText,
  });

  final HelpArticle article;
  final VoidCallback onTap;
  final String query;
  final bool showCategory;
  final String? subtitleText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: HighlightedText(
          text: article.titre,
          query: query,
          style: theme.textTheme.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showCategory)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Text(
                    article.categorie.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              HighlightedText(
                text: subtitleText ?? article.resume,
                query: query,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
