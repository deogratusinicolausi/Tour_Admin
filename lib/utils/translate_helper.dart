import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import 'app_translations.dart';

extension TranslateContext on BuildContext {
  String tr(String key) {
    final provider = Provider.of<AppThemeProvider>(this, listen: false);
    return AppTranslations.translate(key, provider.language);
  }
}