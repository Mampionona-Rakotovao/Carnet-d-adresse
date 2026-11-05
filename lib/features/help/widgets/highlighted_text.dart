import 'package:flutter/material.dart';

import '../data/help_search.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlightStyle = TextStyle(
      backgroundColor: scheme.primaryContainer,
      color: scheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: _spans(highlightStyle),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<InlineSpan> _spans(TextStyle highlightStyle) {
    final tokens = HelpSearch.tokenize(query);
    if (tokens.isEmpty) return [TextSpan(text: text)];

    final folded = _fold(text);
    final ranges = <_HighlightRange>[];

    for (final token in tokens) {
      var start = 0;
      while (start < folded.length) {
        final index = folded.indexOf(token, start);
        if (index < 0) break;
        ranges.add(_HighlightRange(index, index + token.length));
        start = index + token.length;
      }
    }

    if (ranges.isEmpty) return [TextSpan(text: text)];

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightRange>[];
    for (final range in ranges) {
      if (merged.isEmpty || range.start > merged.last.end) {
        merged.add(range);
      } else if (range.end > merged.last.end) {
        merged[merged.length - 1] =
            _HighlightRange(merged.last.start, range.end);
      }
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final range in merged) {
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: highlightStyle,
        ),
      );
      cursor = range.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans;
  }

  static String _fold(String value) {
    const replacements = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'o',
      'æ': 'a',
    };

    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }
}

class _HighlightRange {
  const _HighlightRange(this.start, this.end);

  final int start;
  final int end;
}
