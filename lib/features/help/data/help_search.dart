import '../models/help_article.dart';
import 'help_content.dart';

class HelpSearchResult {
  const HelpSearchResult({
    required this.article,
    required this.score,
    this.snippet,
  });

  final HelpArticle article;
  final int score;
  final String? snippet;
}

class HelpSearch {
  const HelpSearch({this.articles = helpArticles});

  final List<HelpArticle> articles;

  List<HelpSearchResult> search(String query) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return const [];

    final results = <HelpSearchResult>[];
    final order = <String, int>{
      for (var i = 0; i < articles.length; i++) articles[i].id: i,
    };

    for (final article in articles) {
      final fields = _fieldsFor(article);
      final titleBonus = _titleLengthBonus(article.titre);
      var score = titleBonus;
      var matchesAll = true;

      for (final token in tokens) {
        final match = _bestMatch(token, fields);
        if (match == null) {
          matchesAll = false;
          break;
        }
        score += match.score;
      }

      if (!matchesAll) continue;

      results.add(
        HelpSearchResult(
          article: article,
          score: score,
          snippet: _snippetFor(article, tokens),
        ),
      );
    }

    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return (order[a.article.id] ?? 0).compareTo(order[b.article.id] ?? 0);
    });

    return results;
  }

  static int _titleLengthBonus(String title) {
    final length = tokenize(title).length;
    final capped = length > 6 ? 6 : length;
    return (6 - capped) * 20;
  }

  static String normalize(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    var previousWasSpace = true;

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      String replacement;

      switch (char) {
        case 'à':
        case 'á':
        case 'â':
        case 'ã':
        case 'ä':
        case 'å':
          replacement = 'a';
          break;
        case 'ç':
          replacement = 'c';
          break;
        case 'è':
        case 'é':
        case 'ê':
        case 'ë':
          replacement = 'e';
          break;
        case 'ì':
        case 'í':
        case 'î':
        case 'ï':
          replacement = 'i';
          break;
        case 'ñ':
          replacement = 'n';
          break;
        case 'ò':
        case 'ó':
        case 'ô':
        case 'õ':
        case 'ö':
          replacement = 'o';
          break;
        case 'ù':
        case 'ú':
        case 'û':
        case 'ü':
          replacement = 'u';
          break;
        case 'ý':
        case 'ÿ':
          replacement = 'y';
          break;
        case 'œ':
          replacement = 'oe';
          break;
        case 'æ':
          replacement = 'ae';
          break;
        default:
          final isLetter = rune >= 97 && rune <= 122;
          final isDigit = rune >= 48 && rune <= 57;
          replacement = isLetter || isDigit ? char : ' ';
          break;
      }

      if (replacement == ' ') {
        if (!previousWasSpace) buffer.write(' ');
        previousWasSpace = true;
      } else {
        buffer.write(replacement);
        previousWasSpace = false;
      }
    }

    return buffer.toString().trim();
  }

  static List<String> tokenize(String value) {
    final normalized = normalize(value);
    if (normalized.isEmpty) return const [];

    return normalized
        .split(' ')
        .where((token) => token.isNotEmpty)
        .map(_singular)
        .toList(growable: false);
  }

  static String _singular(String token) {
    if (token.length > 3 && token.endsWith('s') && !token.endsWith('ss')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  List<_SearchField> _fieldsFor(HelpArticle article) {
    final fields = <_SearchField>[
      _SearchField(1000, article.titre),
      _SearchField(700, article.motsCles.join(' ')),
      _SearchField(300, article.resume),
      _SearchField(150, article.astuces.join(' ')),
    ];

    for (final step in article.etapes) {
      fields.add(_SearchField(150, step));
    }

    return fields;
  }

  _FieldMatch? _bestMatch(String token, List<_SearchField> fields) {
    _FieldMatch? best;

    for (final field in fields) {
      final match = _matchInField(token, field);
      if (match != null && (best == null || match.score > best.score)) {
        best = match;
      }
    }

    return best;
  }

  _FieldMatch? _matchInField(String token, _SearchField field) {
    _FieldMatch? best;

    for (final candidate in field.tokens) {
      final quality = _matchQuality(token, candidate);
      if (quality == null) continue;

      final score = (field.weight * quality).round();
      if (best == null || score > best.score) {
        best = _FieldMatch(score, field.text);
      }
    }

    return best;
  }

  double? _matchQuality(String token, String candidate) {
    if (candidate == token) return 1;
    if (candidate.startsWith(token)) return 0.85;
    if (candidate.contains(token)) return 0.65;
    if (token.length >= 5 &&
        candidate.length >= 5 &&
        _withinOneEdit(token, candidate)) {
      return 0.5;
    }
    return null;
  }

  String? _snippetFor(HelpArticle article, List<String> tokens) {
    if (_matchesAny(tokens, article.resume)) return article.resume;

    for (final step in article.etapes) {
      if (_matchesAny(tokens, step)) return step;
    }

    return null;
  }

  bool _matchesAny(List<String> tokens, String text) {
    final normalized = tokenize(text);
    for (final token in tokens) {
      for (final candidate in normalized) {
        if (_matchQuality(token, candidate) != null) return true;
      }
    }
    return false;
  }

  static bool _withinOneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;

    if (a.length == b.length) {
      final mismatches = <int>[];
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
          mismatches.add(i);
          if (mismatches.length > 2) return false;
        }
      }

      if (mismatches.isEmpty) return true;
      if (mismatches.length == 1) return true;
      final first = mismatches[0];
      final second = mismatches[1];
      return second == first + 1 &&
          a[first] == b[second] &&
          a[second] == b[first];
    }

    final shorter = a.length < b.length ? a : b;
    final longer = a.length < b.length ? b : a;
    var i = 0;
    var j = 0;
    var skipped = false;

    while (i < shorter.length && j < longer.length) {
      if (shorter[i] == longer[j]) {
        i++;
        j++;
        continue;
      }
      if (skipped) return false;
      skipped = true;
      j++;
    }

    return true;
  }
}

class _SearchField {
  _SearchField(this.weight, this.text) : tokens = HelpSearch.tokenize(text);

  final int weight;
  final String text;
  final List<String> tokens;
}

class _FieldMatch {
  const _FieldMatch(this.score, this.text);

  final int score;
  final String text;
}
