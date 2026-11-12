import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../ui/app_background.dart';
import '../../../ui/app_feedback.dart';
import '../../../ui/app_states.dart';
import '../../../ui/section.dart';
import '../data/help_content.dart';
import '../help_navigation.dart';
import '../support.dart';
import '../widgets/help_article_tile.dart';

class HelpArticleScreen extends StatefulWidget {
  const HelpArticleScreen({
    super.key,
    required this.articleId,
  });

  final String articleId;

  @override
  State<HelpArticleScreen> createState() => _HelpArticleScreenState();
}

class _HelpArticleScreenState extends State<HelpArticleScreen> {
  String? _feedback;
  bool _savingFeedback = false;

  String get _feedbackKey => 'help_feedback_${widget.articleId}';

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_feedbackKey);
    if (!mounted) return;
    setState(() => _feedback = value);
  }

  Future<void> _saveFeedback(String articleTitle, bool helpful) async {
    setState(() => _savingFeedback = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = helpful ? 'oui' : 'non';
      await prefs.setString(_feedbackKey, value);
      if (!mounted) return;

      setState(() => _feedback = value);
      if (helpful) {
        AppSnack.success(context, 'Merci pour votre retour.');
        return;
      }

      final contact = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Besoin d’aide ?'),
          content: const Text(
            'Cet article ne répond pas à votre question. Vous pouvez '
            'contacter le support pour obtenir de l’aide.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Plus tard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Contacter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (contact == true && mounted) {
        await contactSupport(context, subject: 'Aide — $articleTitle');
      }
    } finally {
      if (mounted) setState(() => _savingFeedback = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = helpArticleById(widget.articleId);

    if (article == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Aide')),
        body: AppBackground(
          style: AppBackgroundStyle.vide,
          child: AppEmptyState(
            icon: Icons.help_outline,
            title: 'Article introuvable',
            message: 'Cet article d’aide n’existe pas ou a été renommé.',
            actionLabel: 'Retour au centre d’aide',
            actionIcon: Icons.arrow_back,
            onAction: () => context.go('/aide'),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final related = helpArticlesByIds(article.articlesLies);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Aide')),
      body: AppBackground(
        style: AppBackgroundStyle.calme,
        child: ListView(
          padding: AppSpacing.list,
          children: [
            Text(
              article.categorie.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(article.titre, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              article.resume,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (article.openRoute != null && article.openLabel != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => openHelpRoute(context, article.openRoute!),
                icon: const Icon(Icons.open_in_new),
                label: Text(article.openLabel!),
              ),
            ],
            if (article.etapes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Comment faire',
                icon: Icons.checklist,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < article.etapes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(
                          '${i + 1}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            article.etapes[i],
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (article.astuces.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Bon à savoir',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final tip in article.astuces)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•'),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            if (related.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(
                title: 'Voir aussi',
                icon: Icons.link,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < related.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                HelpArticleTile(
                  article: related[i],
                  onTap: () => context.push('/aide/${related[i].id}'),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cet article vous a-t-il aidé ?',
                      style: theme.textTheme.titleSmall,
                    ),
                    if (_feedback != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        _feedback == 'oui'
                            ? 'Votre réponse : Oui'
                            : 'Votre réponse : Non',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _savingFeedback
                              ? null
                              : () => _saveFeedback(article.titre, true),
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          label: const Text('Oui'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _savingFeedback
                              ? null
                              : () => _saveFeedback(article.titre, false),
                          icon: const Icon(Icons.thumb_down_alt_outlined),
                          label: const Text('Non'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
