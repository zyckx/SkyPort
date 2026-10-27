import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyport/providers/common_providers.dart';
import 'package:skyport/providers/locale_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to following the platform locale', () async {
    final container = await _container({});
    expect(container.read(languageProvider), AppLanguage.system);
    expect(container.read(languageProvider).locale, isNull);
  });

  test('unknown stored values fall back to the platform locale', () async {
    final container = await _container({'ui_locale': 'fr'});
    expect(container.read(languageProvider), AppLanguage.system);
  });

  test('explicit choices persist and system clears the override', () async {
    final container = await _container({});
    await container.read(languageProvider.notifier).setLanguage(AppLanguage.zh);
    expect(container.read(languageProvider).locale, const Locale('zh'));
    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getString('ui_locale'), 'zh');

    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    expect(restarted.read(languageProvider), AppLanguage.zh);

    await container
        .read(languageProvider.notifier)
        .setLanguage(AppLanguage.system);
    expect(prefs.containsKey('ui_locale'), isFalse);
  });
}
