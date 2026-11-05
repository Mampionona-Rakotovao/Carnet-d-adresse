import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../ui/section.dart';
import '../data/help_content.dart';
import '../data/help_search.dart';
import '../models/help_article.dart';
import '../support.dart';
import '../widgets/help_article_tile.dart';
import '../widgets/help_category_icons.dart';
import '../widgets/onboarding_tour.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const _search = HelpSearch();

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _input = '';
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _input = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _input = '';
      _query = '';
    });
  }

  void _useSuggestion(String keyword) {
    _debounce?.cancel();
    _searchController.text = keyword;
    _searchController.selection = TextSelection.collapsed(
      offset: keyword.length,
    );
    setState(() {
      _input = keyword;
      _query = keyword;
    });
  }

  void _openArticle(HelpArticle article) {
    context.push('/aide/${article.id}');
  }

  @override
  Widget build(BuildContext context) {
    final results =
        _query.isEmpty ? const <HelpSearchResult>[] : _search.search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Aide')),
      body: ListView(
        padding: AppSpacing.list,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Rechercher : partage, GPS, photo…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _input.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.fieldRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_query.isNotEmpty)
            ..._buildSearchResults(context, results)
          else
            ..._buildHome(context),
        ],
      ),
    );
  }

  List<Widget> _buildSearchResults(
    BuildContext context,
    List<HelpSearchResult> results,
  ) {
    if (results.isEmpty) {
      return [
        _NoResult(
          query: _query,
          onSuggestion: _useSuggestion,
        ),
      ];
    }

    return [
      SectionHeader(
        title: 'Résultats',
        icon: Icons.search,
        subtitle: results.length == 1
            ? '1 article trouvé'
            : '${results.length} articles trouvés',
      ),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < results.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        HelpArticleTile(
          article: results[i].article,
          query: _query,
          showCategory: true,
          subtitleText: results[i].snippet,
          onTap: () => _openArticle(results[i].article),
        ),
      ],
    ];
  }

  List<Widget> _buildHome(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Text(
        'Comment pouvons-nous vous aider ?',
        style: theme.textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Trouvez une réponse, parcourez une catégorie ou contactez le support.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(
        title: 'Pour bien démarrer',
        icon: Icons.auto_awesome_outlined,
      ),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < helpFeaturedArticles.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        HelpArticleTile(
          article: helpFeaturedArticles[i],
          onTap: () => _openArticle(helpFeaturedArticles[i]),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(
        title: 'Parcourir par thème',
        icon: Icons.category_outlined,
      ),
      const SizedBox(height: AppSpacing.sm),
      _CategoryGrid(onOpen: (category) {
        context.push('/aide/categorie/${category.name}');
      }),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader(
        title: 'Questions fréquentes',
        icon: Icons.question_answer_outlined,
      ),
      const SizedBox(height: AppSpacing.sm),
      for (var i = 0; i < helpFaqArticles.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.xs),
        HelpArticleTile(
          article: helpFaqArticles[i],
          onTap: () => _openArticle(helpFaqArticles[i]),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Besoin d’aide supplémentaire ?',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Décrivez votre problème au support : nous vous répondrons '
                'par e-mail.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => contactSupport(context),
                icon: const Icon(Icons.mail_outline),
                label: const Text('Contacter le support'),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          onPressed: () => showOnboardingTour(context),
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('Revoir la visite guidée'),
        ),
      ),
    ];
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onOpen});

  final ValueChanged<HelpCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: HelpCategory.values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        mainAxisExtent: 126,
      ),
      itemBuilder: (context, index) {
        final category = HelpCategory.values[index];
        final count = helpArticlesForCategory(category).length;

        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => onOpen(category),
            borderRadius: AppRadius.cardRadius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Icon(
                      helpCategoryIcon(category),
                      size: 20,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count == 1 ? '1 article' : '$count articles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoResult extends StatelessWidget {
  const _NoResult({
    required this.query,
    required this.onSuggestion,
  });

  final String query;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 42,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Aucun résultat pour « $query »',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Essayez un autre mot ou choisissez une suggestion.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final keyword in helpSuggestionKeywords)
                  ActionChip(
                    label: Text(keyword),
                    onPressed: () => onSuggestion(keyword),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => contactSupport(context),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Contacter le support'),
            ),
          ],
        ),
      ),
    );
  }
}
