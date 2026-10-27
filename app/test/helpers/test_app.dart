import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skyport/l10n/app_localizations.dart';
import 'package:skyport/theme.dart';
import 'package:skyport/widgets/ui/ui.dart';

/// Hosts [home] the way the production app does: a shadcn theme above a
/// localized MaterialApp whose builder installs the toaster.
Widget shadTestApp({
  required Widget home,
  Brightness brightness = Brightness.light,
  Locale? locale,
}) {
  final shad = brightness == Brightness.light
      ? getShadLightTheme()
      : getShadDarkTheme();
  return ShadTheme(
    data: shad,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: materialThemeFrom(shad),
      builder: (context, child) => ShadAppBuilder(child: child!),
      home: home,
    ),
  );
}

/// Finds the control wrapped by an [AppTooltip] with [message].
Finder findTooltip(String message) => find.byWidgetPredicate(
  (widget) => widget is AppTooltip && widget.message == message,
);

/// The editable text inside the input identified by [key].
Finder findInputText(Key key) =>
    find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

/// Colour of the status bar's connection dot.
Color statusDotColor(WidgetTester tester) {
  final dot = tester.widget<Container>(
    find.byKey(const ValueKey('status-dot')),
  );
  return (dot.decoration! as BoxDecoration).color!;
}
