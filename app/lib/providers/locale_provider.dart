import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common_providers.dart';

/// Interface language choice; [system] follows the platform locale.
enum AppLanguage {
  system(null),
  zh(Locale('zh')),
  en(Locale('en'));

  const AppLanguage(this.locale);

  /// The locale forced on the app, or null to follow the platform.
  final Locale? locale;

  /// Native name, shown the same regardless of the current language.
  String? get nativeName => switch (this) {
    AppLanguage.system => null,
    AppLanguage.zh => '简体中文',
    AppLanguage.en => 'English',
  };
}

class LanguageNotifier extends Notifier<AppLanguage> {
  static const String _key = 'ui_locale';

  @override
  AppLanguage build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_key);
    return AppLanguage.values.firstWhere(
      (language) => language.name == stored,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = ref.read(sharedPreferencesProvider);
    if (language == AppLanguage.system) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, language.name);
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);
