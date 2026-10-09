import 'package:flutter/material.dart';

enum AppLanguage {
  vietnamese('vi', 'Tiếng Việt'),
  english('en', 'English'),
  chinese('zh', '汉语');

  final String code;
  final String label;

  const AppLanguage(this.code, this.label);

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => values.firstWhere(
    (language) => language.code == code,
    orElse: () => vietnamese,
  );
}
