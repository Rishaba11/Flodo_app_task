import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? baseStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.baseStyle,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lower.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        break;
      }

      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }

      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: (baseStyle ?? const TextStyle()).copyWith(
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.18),
            fontWeight: FontWeight.w700,
          ),
        ),
      );

      start = idx + query.length;
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}