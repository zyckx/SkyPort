import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyport/l10n/app_localizations.dart';
import 'package:skyport/main.dart';
import 'package:skyport/providers/common_providers.dart';
import 'package:skyport/providers/locale_provider.dart';
import 'package:skyport/providers/ui_controller.dart';

import '../helpers/test_app.dart';
import 'home_page_test.dart' show LayoutController;

void main() {
  Future<SharedPreferences> pumpApp(
    WidgetTester tester,
    Map<String, Object> prefs,
  ) async {
    SharedPreferences.setMockInitialValues(prefs);
    final instance = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiControllerProvider.overrideWith(LayoutController.new),
          sharedPreferencesProvider.overrideWithValue(instance),
        ],
        child: const SerialDebuggerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return instance;
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(HomePage)));

  testWidgets('a stored language overrides the platform locale', (
    tester,
  ) async {
    await pumpApp(tester, {'ui_locale': 'zh'});
    expect(l10n(tester).localeName, 'zh');
  });

  testWidgets('settings select switches language and persists it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await pumpApp(tester, {'ui_locale': 'en'});
    await tester.tap(findTooltip(l10n(tester).settingsPageLabel));
    await tester.pumpAndSettle();

    final select = find.byType(ShadSelect<AppLanguage>);
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ShadOption<AppLanguage>, '简体中文'));
    await tester.pumpAndSettle();

    expect(l10n(tester).localeName, 'zh');
    expect(prefs.getString('ui_locale'), 'zh');
    expect(find.text(l10n(tester).settingsPageLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'title bar menu switches language',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await pumpApp(tester, {'ui_locale': 'zh'});
      await tester.tap(find.byKey(const ValueKey('language-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-option-en')));
      await tester.pumpAndSettle();
      expect(l10n(tester).localeName, 'en');
      expect(prefs.getString('ui_locale'), 'en');

      await tester.tap(find.byKey(const ValueKey('language-menu-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('language-option-system')));
      await tester.pumpAndSettle();
      expect(prefs.containsKey('ui_locale'), isFalse);
    },
    // The custom title bar only exists on the desktop hosts it targets.
    skip: !(Platform.isWindows || Platform.isLinux),
  );
}
