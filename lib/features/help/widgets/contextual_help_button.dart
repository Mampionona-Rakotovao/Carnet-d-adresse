import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/help_content.dart';
import 'help_article_tile.dart';

Future<void> showContextualHelp(
  BuildContext context, {
  required List<String> articleIds,
  String title = 'Aide',
}) async {
  final articles = helpArticlesByIds(articleIds);
  if (articles.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(title, style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < articles.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  HelpArticleTile(
                    article: articles[i],
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (context.mounted) {
                        context.push('/aide/${articles[i].id}');
                      }
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    if (context.mounted) context.push('/aide');
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Ouvrir le centre d’aide'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ContextualHelpButton extends StatelessWidget {
  const ContextualHelpButton({
    super.key,
    required this.articleIds,
    this.tooltip = 'Aide sur cette section',
    this.title = 'Aide',
    this.iconSize = 20,
  });

  final List<String> articleIds;
  final String tooltip;
  final String title;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: iconSize),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => showContextualHelp(
        context,
        articleIds: articleIds,
        title: title,
      ),
    );
  }
}
