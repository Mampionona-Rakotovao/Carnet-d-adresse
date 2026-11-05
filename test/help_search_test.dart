import 'package:flutter_test/flutter_test.dart';

import 'package:carnet_adresses_repere/features/help/data/help_content.dart';
import 'package:carnet_adresses_repere/features/help/data/help_search.dart';
import 'package:carnet_adresses_repere/features/help/models/help_article.dart';

void main() {
  const search = HelpSearch();

  test('normalise les accents, la casse et la ponctuation', () {
    expect(
      HelpSearch.normalize('  Itinéraire, GPS !  '),
      'itineraire gps',
    );
    expect(
      HelpSearch.normalize('Repères — œil, cœur'),
      'reperes oeil coeur',
    );
  });

  test('simplifie les pluriels simples', () {
    expect(HelpSearch.tokenize('Les adresses favorites'), [
      'les',
      'adresse',
      'favorite',
    ]);
  });

  test('trouve un article sans tenir compte des accents et de la casse', () {
    final lower = search.search('itineraire');
    final upper = search.search('ITINÉRAIRE');

    expect(lower, isNotEmpty);
    expect(lower.first.article.id, 'itineraire');
    expect(
      upper.map((result) => result.article.id),
      lower.map((result) => result.article.id),
    );
  });

  test('accepte plusieurs mots et renvoie un extrait', () {
    final results = search.search('photo adresse');

    expect(
        results.map((result) => result.article.id), contains('photo-adresse'));
    expect(results.first.snippet, isNotNull);
  });

  test('tolère une faute de frappe sur un mot long', () {
    final results = search.search('itinéreire');

    expect(results.map((result) => result.article.id), contains('itineraire'));
  });

  test('ne renvoie rien pour une requête vide ou inconnue', () {
    expect(search.search('   '), isEmpty);
    expect(search.search('zzyzx'), isEmpty);
  });

  test('le contenu référence uniquement des articles existants', () {
    final ids = helpArticles.map((article) => article.id).toSet();

    for (final article in helpArticles) {
      expect(ids, contains(article.id));
      for (final related in article.articlesLies) {
        expect(ids, contains(related));
      }
    }
  });

  test('chaque catégorie possède au moins un article', () {
    for (final category in HelpCategory.values) {
      expect(helpArticlesForCategory(category), isNotEmpty);
    }
  });
}
