import 'package:flutter/material.dart';
import '../utils/translate_helper.dart';

class TText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TText(
      this.text, {
        super.key,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
      });

  @override
  Widget build(BuildContext context) {
    // Convert 'Dark Mode' → 'dark_mode'
    final key = text.toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and');
    final translated = context.tr(key);

    // Kama translation haipo, context.tr inarudisha key itself
    // Kwa hivyo tuna-fallback kwa original text
    final result = translated == key ? text : translated;

    return Text(
      result,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}